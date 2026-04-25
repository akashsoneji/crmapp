import 'package:crm_app/screens/auth/password/create_new_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CreateNewPasswordScreen', () {
    testWidgets('blocks submit for <8 chars and mismatch confirm', (tester) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );

      await tester.pumpWidget(wrapForTest(const SizedBox.shrink()));
      Get.to(
        () => const CreateNewPasswordScreen(),
        arguments: {'email': 'user@example.com', 'otp': '123456'},
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(2));

      // Too short.
      await tester.enterText(fields.at(0), '1234567');
      await tester.enterText(fields.at(1), '1234567');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(controller.resetPasswordWithOtpCalls, 0);

      // Valid length but mismatch confirm.
      await tester.enterText(fields.at(0), '12345678');
      await tester.enterText(fields.at(1), '87654321');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(controller.resetPasswordWithOtpCalls, 0);
    });

    testWidgets('calls controller when valid', (tester) async {
      final authService = TestAuthService();
      final controller = setUpGetxForWidgetTests(
        authService: authService,
        authControllerFactory: () => TestAuthController(),
      );
      await tester.pumpWidget(wrapForTest(const SizedBox.shrink()));
      Get.to(
        () => const CreateNewPasswordScreen(),
        arguments: {'email': 'user@example.com', 'otp': '123456'},
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Password123');
      await tester.enterText(fields.at(1), 'Password123');
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(controller.resetPasswordWithOtpCalls, 1);
      expect(controller.lastEmail, 'user@example.com');
      expect(controller.lastOtp, '123456');
      expect(controller.lastPassword, 'Password123');
      expect(controller.lastPasswordConfirmation, 'Password123');
    });
  });
}

