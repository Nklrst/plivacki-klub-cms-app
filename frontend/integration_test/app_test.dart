import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Smoke Test', () {
    testWidgets('User can login and see dashboard', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we are on the Login screen
      expect(find.text('PK Ušće CMS'), findsOneWidget);

      // Find input fields
      final emailField = find.byType(TextFormField).at(0);
      final passwordField = find.byType(TextFormField).at(1);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      // Enter credentials (seed data: parent user)
      await tester.enterText(emailField, 'jelena@test.com');
      await tester.enterText(passwordField, 'parent123');

      // Find and tap the Login button
      final loginButton = find.text('LOGIN');
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);

      // Wait for API call + navigation to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we navigated to the Parent Dashboard
      expect(find.text('Dobrodošli!'), findsOneWidget);
      expect(find.textContaining('Prijavljen kao:'), findsOneWidget);
    });
  });
}
