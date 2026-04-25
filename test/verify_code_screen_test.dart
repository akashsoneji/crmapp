import 'package:crm_app/screens/auth/password/verify_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VerifyCodeScreen', () {
    testWidgets('verify disabled until 6 digits; paste fills boxes', (
      tester,
    ) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const VerifyCodeScreen(email: 'a@b.com')));

      // Initially disabled.
      final verifyBtn = find.byType(ElevatedButton).first;
      expect(tester.widget<ElevatedButton>(verifyBtn).onPressed, isNull);

      // Paste into first field.
      final otpFields = find.byType(TextField);
      await tester.enterText(otpFields.at(0), '123456');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60)); // focus delays

      // Verify should be enabled now.
      expect(tester.widget<ElevatedButton>(verifyBtn).onPressed, isNotNull);

      await tester.tap(verifyBtn);
      await tester.pump();

      expect(controller.verifyPasswordResetOtpCalls, 1);
      expect(controller.lastEmail, 'a@b.com');
      expect(controller.lastOtp, '123456');
    });

    testWidgets('resend calls requestPasswordResetOTP', (tester) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const VerifyCodeScreen(email: 'x@y.com')));

      // Resend link is a GestureDetector wrapping a Text.
      await tester.ensureVisible(find.text('verify_code_resend'));
      await tester.tap(find.text('verify_code_resend'));
      await tester.pump();

      expect(controller.requestPasswordResetOtpCalls, 1);
      expect(controller.lastEmail, 'x@y.com');
    });
  });
}

