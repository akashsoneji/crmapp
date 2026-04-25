import 'package:crm_app/screens/auth/getstart/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen', () {
    testWidgets('shows validation for empty fields', (tester) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const LoginScreen()));
      await tester.pump(); // allow post-frame callbacks

      await tester.tap(find.text('login_button'));
      await tester.pump();

      expect(find.text('validation_email_required'), findsOneWidget);
      expect(find.text('validation_password_required'), findsOneWidget);
      expect(controller.loginCalls, 0);
    });

    testWidgets('shows validation for invalid email and short password', (
      tester,
    ) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const LoginScreen()));
      await tester.pump();

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));

      await tester.enterText(fields.at(0), 'invalid');
      await tester.enterText(fields.at(1), '123');
      await tester.pump();

      await tester.tap(find.text('login_button'));
      await tester.pump();

      expect(find.text('validation_email_invalid'), findsOneWidget);
      expect(find.text('validation_password_min_length'), findsOneWidget);
      expect(controller.loginCalls, 0);
    });

    testWidgets('calls controller.login when valid', (tester) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const LoginScreen()));
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'user@example.com');
      await tester.enterText(fields.at(1), ' 123456 ');
      await tester.pump();

      await tester.tap(find.text('login_button'));
      await tester.pump();

      expect(controller.loginCalls, 1);
      expect(controller.lastEmail, 'user@example.com');
      expect(controller.lastPassword, '123456');
    });
  });
}

