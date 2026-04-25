import 'package:crm_app/screens/auth/password/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPasswordScreen', () {
    testWidgets('blocks submit when email missing/invalid', (tester) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const ForgotPasswordScreen()));

      // Try submit with empty email.
      await tester.tap(find.text('forgot_password_send_otp'));
      await tester.pump();
      expect(controller.requestPasswordResetOtpCalls, 0);

      // Enter invalid email (no @) and try again.
      final field = find.byType(TextFormField).first;
      await tester.enterText(field, 'invalid-email');
      await tester.pump();
      await tester.tap(find.text('forgot_password_send_otp'));
      await tester.pump();

      expect(controller.requestPasswordResetOtpCalls, 0);
    });

    testWidgets('calls controller when email contains @', (tester) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const ForgotPasswordScreen()));

      final field = find.byType(TextFormField).first;
      await tester.enterText(field, 'user@example.com');
      await tester.pump();

      await tester.tap(find.text('forgot_password_send_otp'));
      await tester.pump();

      expect(controller.requestPasswordResetOtpCalls, 1);
      expect(controller.lastEmail, 'user@example.com');
    });
  });
}

