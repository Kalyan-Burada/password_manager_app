import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart'; // Not using mockito anymore

import 'package:password_manager_app/services/auth_service.dart';
import 'package:password_manager_app/widgets/backup_dialog.dart';

// Mock AuthService using Mockito (we'll implement a simple manual mock as Mockito gen needs build_runner)
class MockAuthService extends Fake implements AuthService {
  final List<String> mockBackups = ['backup1.enc', 'backup2.enc'];

  @override
  Future<List<String>> getBackups(String token) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 10));
    return mockBackups;
  }

  @override
  Future<String> createBackup(String token) async {
    await Future.delayed(const Duration(milliseconds: 10));
    const newBackup = 'backup_new.enc';
    mockBackups.add(newBackup);
    return newBackup;
  }

  @override
  Future<void> restoreBackup(String token, String filename) async {
     await Future.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  testWidgets('BackupManagerDialog shows backups and allows creation', (WidgetTester tester) async {
    final mockAuthService = MockAuthService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BackupManagerDialog(
          token: 'dummy_token',
          authService: mockAuthService,
        ),
      ),
    ));

    // Initially loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for load
    await tester.pumpAndSettle();

    // Check if backups are displayed
    expect(find.text('backup1.enc'), findsOneWidget);
    expect(find.text('backup2.enc'), findsOneWidget);

    // Create new backup
    final createButton = find.widgetWithText(ElevatedButton, 'Create New Backup');
    expect(createButton, findsOneWidget);

    await tester.tap(createButton);
    await tester.pump(); // Start loading
    await tester.pumpAndSettle(); // Finish loading

    // Verify snackbar
    expect(find.text('Backup created successfully'), findsOneWidget);

    // Verify new backup in list
    expect(find.text('backup_new.enc'), findsOneWidget);
  });

   testWidgets('BackupManagerDialog restores backup', (WidgetTester tester) async {
    final mockAuthService = MockAuthService();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BackupManagerDialog(
          token: 'dummy_token',
          authService: mockAuthService,
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Find custom Restore button (ElevatedButton)
    final restoreButtons = find.widgetWithText(ElevatedButton, 'Restore');
    expect(restoreButtons, findsWidgets); // Should be at least one

    // Tap the first one
     await tester.tap(restoreButtons.first);
     await tester.pumpAndSettle();

     // Verify confirmation dialog
     expect(find.text('Confirm Restore'), findsOneWidget);
     expect(find.text('RESTORE'), findsOneWidget);

     // Tap Confirm
     await tester.tap(find.text('RESTORE'));
     await tester.pumpAndSettle();

     // Verify snackbar
     expect(find.text('Backup restored successfully'), findsOneWidget);
  });
}
