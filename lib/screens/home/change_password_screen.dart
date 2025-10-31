import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../constants/color.dart';
import '../../constants/text_styles.dart';
import '../../controllers/change_password_controller.dart';
import '../../services/language_service.dart';
import '../../utils/trl_helper.dart';
import '../../widgets/custom_toast.dart';


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // final TextEditingController _confirmPasswordController = TextEditingController();
  final ChangePasswordController _changePasswordController = Get.put(ChangePasswordController());
  final LanguageService languageService = Get.find<LanguageService>();

  bool _isLoading = false;



  @override
  void dispose() {
    // _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _changePassword() async {
    // final confirmPassword = _confirmPasswordController.text.trim();

    if (_changePasswordController.newPasswordController.value.text.isEmpty) {
      CustomToastService.showError(message: 'Please fill password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _changePasswordController.changePassword();
      if (_changePasswordController.successMessage.isNotEmpty) {
        CustomToastService.showSuccess(
          message: _changePasswordController.successMessage,
        );
        // Navigator.of(context).pop();
        Get.back();
      } else if (_changePasswordController.errorMessage.isNotEmpty) {
        CustomToastService.showError(
          message: _changePasswordController.errorMessage,
        );
      }
    } catch (e) {
      CustomToastService.showError(message: 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: SizedBox(
        height: 46.h,
        child: RTLHelper.rtlTextField(
          obscureText: true,
          controller: controller,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            labelText: label,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          languageService.tr('change_password'),
          style: AppTextStyles.screenTitle,
        ),
        leading: IconButton(
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // _buildPasswordField(label: 'Old Password', controller: _oldPasswordController),
            // _buildPasswordField(label: 'New Password', controller: _newPasswordController),
            _buildPasswordField(label: 'Password', controller: _changePasswordController.newPasswordController),

            SizedBox(height: 20.h),

            _buildContinueButton()

          ],
        ),
      ),
    );
  }


  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        onPressed: _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          languageService.tr('change_password'),
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.71,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
