// StartPage smoke test – verifies Login and Create Account buttons are visible.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:password_manager_app/main.dart';
import 'package:password_manager_app/providers/settings_provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Required so SharedPreferences doesn't throw inside SettingsProvider
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const MyApp(),
      ),
    );

    // Let FadeInUp entrance animations finish (they have up to 650ms delay)
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify that Login and Create Account buttons are shown on StartPage
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}

