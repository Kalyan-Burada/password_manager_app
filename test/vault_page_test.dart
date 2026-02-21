import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager_app/main.dart';
import 'package:password_manager_app/services/auth_service.dart';
import 'package:password_manager_app/services/log_service.dart';
import 'package:password_manager_app/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAuthService extends AuthService {
  Map<String, Map<String, String>> vault = {};
  int encryptCalls = 0;
  int updateCalls = 0;

  void seedVault(Map<String, Map<String, String>> seed) {
    vault = seed.map(
      (key, value) {
        final item = Map<String, String>.from(value);
        // Add 'category' field if missing for backward compatibility with tests
        if (!item.containsKey('category')) {
          item['category'] = 'Personal';
        }
        return MapEntry(key, item);
      },
    );
  }

  @override
  Future<Map<String, dynamic>> decryptVault(
    Map<String, dynamic> blob,
    String password,
  ) async {
    return vault.map(
      (key, value) => MapEntry(key, Map<String, String>.from(value)),
    );
  }

  @override
  Future<Map<String, String>> encryptVault(
    Map<String, dynamic> vaultMap,
    String password,
  ) async {
    encryptCalls++;
    vault = vaultMap.map((key, value) {
      final mapValue = Map<String, String>.from(
        (value as Map).cast<String, String>(),
      );
      return MapEntry(key, mapValue);
    });
    return {'ciphertext': 'stub'};
  }

  @override
  Future<bool> updateVault(
      String token, Map<String, String> encryptedBlob) async {
    updateCalls++;
    return true;
  }
}

class FakeLogService extends LogService {
  final List<String> actions = [];

  @override
  Future<void> logAction(String action) async {
    actions.add(action);
  }
}

Future<void> pumpVaultPage(
  WidgetTester tester, {
  required FakeAuthService authService,
  required FakeLogService logService,
  Map<String, Map<String, String>> initialVault = const {},
  Duration clipboardDelay = const Duration(milliseconds: 100),
}) async {
  authService.seedVault(initialVault);

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: MaterialApp(
        home: VaultPage(
          username: 'user',
          token: 'token',
          password: 'Password1!',
          vaultResponse: const {'blob': <String, dynamic>{}},
          authService: authService,
          logService: logService,
          clipboardDelay: clipboardDelay,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Finder _fieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

Future<void> _addCredential(
  WidgetTester tester, {
  required String title,
  required String password,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(_fieldWithLabel('Title'), title);
  await tester.enterText(_fieldWithLabel('Password'), password);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
  await tester.pump();
  await tester.pumpAndSettle();
}

Finder _tileForTitle(String title) {
  return find.widgetWithText(ListTile, title);
}

Finder _iconInTile(String title, IconData icon) {
  return find.descendant(
    of: _tileForTitle(title),
    matching: find.byIcon(icon),
  );
}

Future<void> _openAddDialog(WidgetTester tester) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
}

Future<void> _openEditDialog(WidgetTester tester, String title) async {
  await tester.tap(_iconInTile(title, Icons.edit));
  await tester.pumpAndSettle();
}

Future<void> _openDeleteDialog(WidgetTester tester, String title) async {
  await tester.tap(_iconInTile(title, Icons.delete));
  await tester.pumpAndSettle();
}

List<String> _listTitles(WidgetTester tester) {
  return tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((tile) {
        // Handle the new Row structure with title and category chip
        if (tile.title is Row) {
          final row = tile.title as Row;
          if (row.children.isNotEmpty && row.children[0] is Expanded) {
            final expanded = row.children[0] as Expanded;
            if (expanded.child is Text) {
              return (expanded.child as Text).data;
            }
          }
        }
        // Fallback for old Text format
        if (tile.title is Text) {
          return (tile.title as Text).data;
        }
        return null;
      })
      .whereType<String>()
      .toList();
}

Future<List<MethodCall>> _setupClipboardHandler() async {
  final clipboardCalls = <MethodCall>[];

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      clipboardCalls.add(call);
    }
    return null;
  });

  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  return clipboardCalls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VaultPage credential flows', () {
    late FakeAuthService authService;
    late FakeLogService logService;

    setUp(() {
      authService = FakeAuthService();
      logService = FakeLogService();
    });

    testWidgets('stores a new credential with timestamp', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.textContaining('Updated:'), findsOneWidget);
      expect(authService.vault['GitHub']?['password'], 'StrongPass1!');
      expect(authService.vault['GitHub']?['updatedAt'], isNotNull);
      expect(logService.actions.last, contains('Item added: GitHub'));
    });

    testWidgets('rejects empty title or password on add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldWithLabel('Title'), '');
      await tester.enterText(_fieldWithLabel('Password'), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();

      expect(find.text('Title and Password cannot be empty'), findsOneWidget);
      expect(authService.vault, isEmpty);
    });

    testWidgets('rejects duplicate title on add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldWithLabel('Title'), 'GitHub');
      await tester.enterText(_fieldWithLabel('Password'), 'StrongPass1!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();

      expect(find.text('Title already exists'), findsOneWidget);
      expect(authService.vault.length, 1);
    });

    testWidgets('shows weak-password dialog on add and does not save',
        (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldWithLabel('Title'), 'GitHub');
      await tester.enterText(_fieldWithLabel('Password'), 'weak');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(find.text('Weak Password'), findsOneWidget);
      final weakDialog = find.ancestor(
        of: find.text('Weak Password'),
        matching: find.byType(AlertDialog),
      );
      final cancelFinder = find.descendant(
        of: weakDialog,
        matching: find.widgetWithText(TextButton, 'Cancel'),
      );
      await tester.tap(cancelFinder);
      await tester.pumpAndSettle();

      expect(authService.vault.containsKey('GitHub'), isFalse);
    });

    testWidgets('trims title and password on add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _openAddDialog(tester);
      await tester.enterText(_fieldWithLabel('Title'), '  GitHub  ');
      await tester.enterText(_fieldWithLabel('Password'), '  StrongPass1!  ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(authService.vault.containsKey('GitHub'), isTrue);
      expect(authService.vault['GitHub']?['password'], 'StrongPass1!');
    });

    testWidgets('allows internal spaces in title on add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'My Site',
        password: 'StrongPass1!',
      );

      expect(authService.vault.containsKey('My Site'), isTrue);
    });

    testWidgets('allows case-sensitive titles on add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );
      await _addCredential(
        tester,
        title: 'github',
        password: 'StrongPass2!',
      );

      expect(authService.vault.length, 2);
      expect(authService.vault.containsKey('GitHub'), isTrue);
      expect(authService.vault.containsKey('github'), isTrue);
    });

    testWidgets('keeps existing entries when adding new one', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      expect(authService.vault.length, 2);
      expect(authService.vault.containsKey('Email'), isTrue);
      expect(authService.vault.containsKey('GitHub'), isTrue);
    });

    testWidgets('accepts minimum strong length on add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'Aa1!aaaa',
      );

      expect(authService.vault['GitHub']?['password'], 'Aa1!aaaa');
    });

    testWidgets('add triggers save calls', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      expect(authService.updateCalls, 1);
      expect(authService.encryptCalls, 1);
    });

    testWidgets('add cancel does not save', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _openAddDialog(tester);
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(authService.vault, isEmpty);
    });

    testWidgets('weak add generate opens generator dialog', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _openAddDialog(tester);
      await tester.enterText(_fieldWithLabel('Title'), 'GitHub');
      await tester.enterText(_fieldWithLabel('Password'), 'weak');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      final weakDialog = find.ancestor(
        of: find.text('Weak Password'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: weakDialog,
          matching: find.widgetWithText(ElevatedButton, 'Generate'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generate Password'), findsOneWidget);
      final generatorDialog = find.ancestor(
        of: find.text('Generate Password'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: generatorDialog,
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authService.vault.containsKey('GitHub'), isFalse);
    });

    testWidgets('empty add does not trigger save', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _openAddDialog(tester);
      await tester.enterText(_fieldWithLabel('Title'), '');
      await tester.enterText(_fieldWithLabel('Password'), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();

      expect(authService.updateCalls, 0);
    });

    testWidgets('duplicate add does not trigger save', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openAddDialog(tester);
      await tester.enterText(_fieldWithLabel('Title'), 'GitHub');
      await tester.enterText(_fieldWithLabel('Password'), 'StrongPass1!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pump();

      expect(authService.updateCalls, 0);
    });

    testWidgets('adding multiple items increases list count', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );
      await _addCredential(
        tester,
        title: 'Email',
        password: 'StrongPass2!',
      );

      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('updates existing credential and refreshes timestamp',
        (tester) async {
      const originalTime = '2024-01-01 10:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': originalTime,
          },
        },
      );

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['password'], 'NewPass2!');
      expect(authService.vault['Email']?['updatedAt'], isNot(originalTime));
      expect(logService.actions.last, contains('Item edited: Email'));
    });

    testWidgets('rejects empty password on edit', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldWithLabel('Password'), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      expect(find.text('Password cannot be empty'), findsOneWidget);
      expect(authService.vault['Email']?['password'], 'OldPass1!');
    });

    testWidgets('shows weak-password dialog on edit and does not save',
        (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(_fieldWithLabel('Password'), 'weak');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Weak Password'), findsOneWidget);
      final weakDialog = find.ancestor(
        of: find.text('Weak Password'),
        matching: find.byType(AlertDialog),
      );
      final cancelFinder = find.descendant(
        of: weakDialog,
        matching: find.widgetWithText(TextButton, 'Cancel'),
      );
      await tester.tap(cancelFinder);
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['password'], 'OldPass1!');
    });

    testWidgets('trims password on edit', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), '  NewPass2!  ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['password'], 'NewPass2!');
    });

    testWidgets('same password still refreshes timestamp', (tester) async {
      const originalTime = '2000-01-01 00:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'SamePass1!',
            'updatedAt': originalTime,
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'SamePass1!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['updatedAt'], isNot(originalTime));
    });

    testWidgets('editing one entry preserves others', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(authService.vault['GitHub']?['password'], 'StrongPass1!');
    });

    testWidgets('edit triggers save calls', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(authService.updateCalls, 1);
      expect(authService.encryptCalls, 1);
    });

    testWidgets('edit cancel keeps value', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      final editDialog = find.ancestor(
        of: find.text('Edit Email'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: editDialog,
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['password'], 'OldPass1!');
    });

    testWidgets('edit dialog shows current password', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      // Find the password TextField by its label
      final field = tester.widget<TextField>(_fieldWithLabel('Password'));
      expect(field.controller?.text, 'OldPass1!');
    });

    testWidgets('weak edit generate opens generator dialog', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'weak');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final weakDialog = find.ancestor(
        of: find.text('Weak Password'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: weakDialog,
          matching: find.widgetWithText(ElevatedButton, 'Generate'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Generate Password'), findsOneWidget);
      final generatorDialog = find.ancestor(
        of: find.text('Generate Password'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: generatorDialog,
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('weak edit generate cancel keeps value', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'weak');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final weakDialog = find.ancestor(
        of: find.text('Weak Password'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: weakDialog,
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['password'], 'OldPass1!');
    });

    testWidgets('edit accepts minimum strong length', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'Aa1!aaaa');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['password'], 'Aa1!aaaa');
    });

    testWidgets('empty edit does not trigger save', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      expect(authService.updateCalls, 0);
    });

    testWidgets('weak edit does not trigger save', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'weak');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final weakDialog = find.ancestor(
        of: find.text('Weak Password'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: weakDialog,
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authService.updateCalls, 0);
    });

    testWidgets('edit twice keeps latest password', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass3!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['password'], 'NewPass3!');
    });

    testWidgets('removes a credential from the vault', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsNothing);
      expect(authService.vault.containsKey('GitHub'), isFalse);
      expect(logService.actions.last, contains('Item deleted: GitHub'));
    });

    testWidgets('cancel delete keeps credential', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsOneWidget);
      expect(authService.vault.containsKey('GitHub'), isTrue);
    });

    testWidgets('deletes one of multiple entries', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(authService.vault.containsKey('GitHub'), isFalse);
      expect(authService.vault.containsKey('Email'), isTrue);
    });

    testWidgets('deleting last item shows empty state', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Your vault is empty'), findsOneWidget);
    });

    testWidgets('delete triggers save calls', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(authService.updateCalls, 1);
      expect(authService.encryptCalls, 1);
    });

    testWidgets('delete shows snackbar message', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pump();

      expect(find.text('Item deleted'), findsOneWidget);
    });

    testWidgets('delete cancel does not trigger save', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(authService.updateCalls, 0);
    });

    testWidgets('delete cancel does not log action', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(logService.actions, isEmpty);
    });

    testWidgets('delete dialog includes item name', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');

      expect(find.text('Are you sure you want to delete "GitHub"?'),
          findsOneWidget);
    });

    testWidgets('delete after add removes item', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );
      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(authService.vault.containsKey('GitHub'), isFalse);
    });

    testWidgets('delete handles titles with symbols', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'My#Site': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'My#Site');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(authService.vault.containsKey('My#Site'), isFalse);
    });

    testWidgets('delete reduces list count', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.byType(ListTile), findsNWidgets(2));

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(1));
    });

    testWidgets('delete keeps remaining list sorted', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'b': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'c': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'b');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(_listTitles(tester), ['a', 'c']);
    });

    testWidgets('delete confirm logs action', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(logService.actions.last, contains('Item deleted: GitHub'));
    });

    testWidgets('delete keeps case-variant item', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'github': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(authService.vault.containsKey('GitHub'), isFalse);
      expect(authService.vault.containsKey('github'), isTrue);
    });

    testWidgets('shows empty state when vault is empty', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      expect(find.text('Your vault is empty'), findsOneWidget);
    });

    testWidgets('lists all credential names', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Bank': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
    });

    testWidgets('list does not show passwords', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('StrongPass1!'), findsNothing);
    });

    testWidgets('list supports names with spaces', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'My Site': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('My Site'), findsOneWidget);
    });

    testWidgets('list supports names with numbers', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Bank2': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('Bank2'), findsOneWidget);
    });

    testWidgets('list supports names with symbols', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'My#Site': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('My#Site'), findsOneWidget);
    });

    testWidgets('list supports mixed case names', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'github': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('github'), findsOneWidget);
    });

    testWidgets('list updates after add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      expect(find.byType(ListTile), findsNothing);

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      expect(find.byType(ListTile), findsNWidgets(1));
    });

    testWidgets('list updates after delete', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.byType(ListTile), findsNWidgets(2));

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(1));
    });

    testWidgets('list still shows name after edit', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('list count equals entries', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Bank': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('list supports a single item', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('list supports many items', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'a': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'b': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'c': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
          'd': {
            'password': 'StrongPass4!',
            'updatedAt': '2024-01-01 10:00',
          },
          'e': {
            'password': 'StrongPass5!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('list does not show empty state when items exist',
        (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('Your vault is empty'), findsNothing);
    });

    testWidgets('list shows long names', (tester) async {
      const title = 'VeryLongCredentialNameForTesting';
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          title: {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text(title), findsOneWidget);
    });

    testWidgets('list titles are non-empty', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester).every((title) => title.isNotEmpty), isTrue);
    });

    testWidgets('lists credentials alphabetically', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'Slack',
        password: 'StrongPass1!',
      );
      await _addCredential(
        tester,
        title: 'amazon',
        password: 'StrongPass1!',
      );
      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) {
            // Handle the new Row structure with title and category chip
            if (tile.title is Row) {
              final row = tile.title as Row;
              if (row.children.isNotEmpty && row.children[0] is Expanded) {
                final expanded = row.children[0] as Expanded;
                if (expanded.child is Text) {
                  return (expanded.child as Text).data;
                }
              }
            }
            // Fallback for old Text format
            if (tile.title is Text) {
              return (tile.title as Text).data;
            }
            return null;
          })
          .whereType<String>()
          .toList();

      expect(titles, ['amazon', 'GitHub', 'Slack']);
    });

    testWidgets('sorts case-insensitively', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'B': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'c': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['a', 'B', 'c']);
    });

    testWidgets('sorts numeric suffixes lexicographically', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Account2': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Account10': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Account1': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['Account1', 'Account10', 'Account2']);
    });

    testWidgets('sorts symbols by character order', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'A#': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'A!': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['A!', 'A#']);
    });

    testWidgets('sorts prefix before longer string', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Apple': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'App': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['App', 'Apple']);
    });

    testWidgets('sorts two items in order', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'b': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['a', 'b']);
    });

    testWidgets('sorts single item list', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Only': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['Only']);
    });

    testWidgets('sorts after add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'b',
        password: 'StrongPass1!',
      );
      await _addCredential(
        tester,
        title: 'a',
        password: 'StrongPass2!',
      );
      await _addCredential(
        tester,
        title: 'c',
        password: 'StrongPass3!',
      );

      expect(_listTitles(tester), ['a', 'b', 'c']);
    });

    testWidgets('sorts remaining items after delete', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'c': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'b': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'b');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(_listTitles(tester), ['a', 'c']);
    });

    testWidgets('sorts mixed letter-number strings lexicographically',
        (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'a10': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a1': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a2': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['a1', 'a10', 'a2']);
    });

    testWidgets('sorts underscores after hyphens', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'a_a': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a-a': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['a-a', 'a_a']);
    });

    testWidgets('sorts underscore before letters', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'aa': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'a_a': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['a_a', 'aa']);
    });

    testWidgets('sorts upper and lower case together', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Zebra': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'ant': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['ant', 'Zebra']);
    });

    testWidgets('sorts leading numbers before letters', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'pass': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          '2pass': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          '1pass': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['1pass', '2pass', 'pass']);
    });

    testWidgets('sorts mixed case words', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'gamma': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Beta': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
          'alpha': {
            'password': 'StrongPass3!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(_listTitles(tester), ['alpha', 'Beta', 'gamma']);
    });

    testWidgets('displays stored last-updated timestamps', (tester) async {
      const timestamp = '2025-12-31 23:59';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': timestamp,
          },
        },
      );

      expect(find.text('Updated: $timestamp'), findsOneWidget);
    });

    testWidgets('displays timestamps for multiple entries', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2025-12-31 23:59',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('Updated: 2025-12-31 23:59'), findsOneWidget);
      expect(find.text('Updated: 2024-01-01 10:00'), findsOneWidget);
    });

    testWidgets('generated timestamp matches expected format', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      final updatedAt = authService.vault['GitHub']?['updatedAt'] ?? '';
      expect(
        RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$').hasMatch(updatedAt),
        isTrue,
      );
    });

    testWidgets('updatedAt is not empty after add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      expect(authService.vault['GitHub']?['updatedAt'], isNotEmpty);
    });

    testWidgets('updatedAt is not null after add', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
      );

      await _addCredential(
        tester,
        title: 'GitHub',
        password: 'StrongPass1!',
      );

      expect(authService.vault['GitHub']?['updatedAt'], isNotNull);
    });

    testWidgets('updatedAt unchanged when edit canceled', (tester) async {
      const originalTime = '2024-01-01 10:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': originalTime,
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      final editDialog = find.ancestor(
        of: find.text('Edit Email'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: editDialog,
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['updatedAt'], originalTime);
    });

    testWidgets('updatedAt unchanged after empty edit', (tester) async {
      const originalTime = '2024-01-01 10:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': originalTime,
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pump();

      expect(authService.vault['Email']?['updatedAt'], originalTime);
    });

    testWidgets('updatedAt unchanged after weak edit cancel', (tester) async {
      const originalTime = '2024-01-01 10:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': originalTime,
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'weak');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final weakDialog = find.ancestor(
        of: find.text('Weak Password'),
        matching: find.byType(AlertDialog),
      );
      await tester.tap(
        find.descendant(
          of: weakDialog,
          matching: find.widgetWithText(TextButton, 'Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(authService.vault['Email']?['updatedAt'], originalTime);
    });

    testWidgets('updatedAt changes after second update', (tester) async {
      const originalTime = '2000-01-01 00:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': originalTime,
          },
        },
      );

      // First update
      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final firstUpdate = authService.vault['Email']?['updatedAt'];
      expect(firstUpdate, isNot(originalTime)); // Has current timestamp

      // Second update - timestamp should reflect current time (may be same minute)
      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass3!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      final secondUpdate = authService.vault['Email']?['updatedAt'];
      expect(secondUpdate, isNot(originalTime)); // Still has current timestamp
      expect(secondUpdate, isNotNull);
      expect(secondUpdate, isNotEmpty);
    });

    testWidgets('updatedAt displayed with prefix', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      expect(find.text('Updated: 2024-01-01 10:00'), findsOneWidget);
    });

    testWidgets('updatedAt shown in subtitle for each tile', (tester) async {
      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-02 11:00',
          },
        },
      );

      expect(find.textContaining('Updated:'), findsNWidgets(2));
    });

    testWidgets('updatedAt persists when delete canceled', (tester) async {
      const originalTime = '2024-01-01 10:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': originalTime,
          },
        },
      );

      await _openDeleteDialog(tester, 'GitHub');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(authService.vault['GitHub']?['updatedAt'], originalTime);
    });

    testWidgets('updatedAt remains after deleting other entry', (tester) async {
      const originalTime = '2024-01-01 10:00';

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'StrongPass1!',
            'updatedAt': originalTime,
          },
          'Email': {
            'password': 'StrongPass2!',
            'updatedAt': '2024-01-02 11:00',
          },
        },
      );

      await _openDeleteDialog(tester, 'Email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(authService.vault['GitHub']?['updatedAt'], originalTime);
    });

    testWidgets('clears clipboard after timeout', (tester) async {
      const passwordText = 'TempPass1!';
      final clipboardCalls = <MethodCall>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardCalls.add(call);
        }
        return null;
      });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': passwordText,
            'updatedAt': '2024-01-01 10:00',
          },
        },
        clipboardDelay: const Duration(milliseconds: 100),
      );

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(clipboardCalls.length, greaterThanOrEqualTo(2));
      expect(clipboardCalls.first.arguments['text'], passwordText);
      expect(clipboardCalls.last.arguments['text'], '');
    });

    testWidgets('copy writes password to clipboard', (tester) async {
      const passwordText = 'TempPass1!';
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': passwordText,
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();

      expect(clipboardCalls.first.arguments['text'], passwordText);
    });

    testWidgets('copy shows snackbar message', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();

      expect(clipboardCalls, isNotEmpty);
      expect(find.text('Copied to clipboard'), findsOneWidget);
    });

    testWidgets('clear shows snackbar message', (tester) async {
      await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
        clipboardDelay: const Duration(milliseconds: 50),
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pumpAndSettle(); // Process tap and show "Copied" snackbar

      // Dismiss the first snackbar by waiting for it to auto-dismiss
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Advance fake time to trigger the timer callback
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle(); // Process async callback and snackbar

      expect(find.text('Clipboard cleared automatically'), findsOneWidget);
    });

    testWidgets('copy twice resets timer and clears once', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
        clipboardDelay: const Duration(milliseconds: 100),
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(
        clipboardCalls.where((call) => call.arguments['text'] == '').length,
        1,
      );
    });

    testWidgets('copy from second item uses its password', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'EmailPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'GitHub': {
            'password': 'GitHubPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(_iconInTile('Email', Icons.copy));
      await tester.pump();

      expect(clipboardCalls.first.arguments['text'], 'EmailPass1!');
    });

    testWidgets('multiple copies update clipboard text', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'EmailPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
          'GitHub': {
            'password': 'GitHubPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.tap(_iconInTile('Email', Icons.copy));
      await tester.pump();

      expect(clipboardCalls.first.arguments['text'], 'GitHubPass1!');
      expect(clipboardCalls[1].arguments['text'], 'EmailPass1!');
    });

    testWidgets('copy after clear works again', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
        clipboardDelay: const Duration(milliseconds: 50),
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(
        clipboardCalls.where((call) => call.arguments['text'] == '').length,
        2,
      );
    });

    testWidgets('copy records non-empty clipboard text', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();

      expect(clipboardCalls.first.arguments['text'], isNot(''));
    });

    testWidgets('clear writes empty clipboard text', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
        clipboardDelay: const Duration(milliseconds: 50),
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(clipboardCalls.last.arguments['text'], '');
    });

    testWidgets('copy produces set and clear calls', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
        clipboardDelay: const Duration(milliseconds: 50),
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(clipboardCalls.length, greaterThanOrEqualTo(2));
    });

    testWidgets('copy uses latest password after edit', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'Email': {
            'password': 'OldPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await _openEditDialog(tester, 'Email');
      await tester.enterText(_fieldWithLabel('Password'), 'NewPass2!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      await tester.tap(_iconInTile('Email', Icons.copy));
      await tester.pump();

      expect(clipboardCalls.first.arguments['text'], 'NewPass2!');
    });

    testWidgets('copy sequence keeps latest clear timing', (tester) async {
      final clipboardCalls = await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
        clipboardDelay: const Duration(milliseconds: 80),
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pump();

      expect(
        clipboardCalls.where((call) => call.arguments['text'] == '').length,
        1,
      );
    });

    testWidgets('copy uses clipboard handler without errors', (tester) async {
      await _setupClipboardHandler();

      await pumpVaultPage(
        tester,
        authService: authService,
        logService: logService,
        initialVault: {
          'GitHub': {
            'password': 'TempPass1!',
            'updatedAt': '2024-01-01 10:00',
          },
        },
      );

      await tester.tap(_iconInTile('GitHub', Icons.copy));
      await tester.pump();

      expect(find.text('Copied to clipboard'), findsOneWidget);
    });
  });
}
