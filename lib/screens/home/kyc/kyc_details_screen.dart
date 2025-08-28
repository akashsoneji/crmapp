import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/widgets/kyc_scaffold.dart';
import 'package:pipze/widgets/otp_modal.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/widgets/AppTextField.dart';

class KycDetailsScreen extends StatefulWidget {
  const KycDetailsScreen({Key? key}) : super(key: key);

  @override
  State<KycDetailsScreen> createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  final TextEditingController _firstNameController = TextEditingController(
    text: 'Brooklyn',
  );
  final TextEditingController _lastNameController = TextEditingController(
    text: 'Simmons',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'brooklynsimmons@gmail.com',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '+91 987654321',
  );
  final TextEditingController _cityController = TextEditingController(
    text: 'Value',
  );
  final TextEditingController _stateController = TextEditingController(
    text: 'Value',
  );
  final TextEditingController _addressController = TextEditingController(
    text: 'Value',
  );

  // Phone verification state
  bool _isPhoneVerified = false;
  bool _isOtpSent = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KycScaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

              // Section Title
              Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.75,
                ),
              ),

              SizedBox(height: 15.h),

              // Form Fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFormField(
                        label: 'First Name',
                        controller: _firstNameController,
                      ),

                      _buildFormField(
                        label: 'Last',
                        controller: _lastNameController,
                      ),

                      _buildFormField(
                        label: 'Email',
                        controller: _emailController,
                      ),

                      _buildPhoneField(),

                      // City and State in same row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              label: 'City',
                              controller: _cityController,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: _buildDropdownField(
                              label: 'State',
                              controller: _stateController,
                            ),
                          ),
                        ],
                      ),

                      _buildFormField(
                        label: 'Residence Address',
                        controller: _addressController,
                        maxLines: 3,
                      ),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
              ),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.whiteColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.all(0),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: RTLHelper.rtlTextField(
        controller: controller,
        maxLines: maxLines,
        style: AppTextStyles.black16400h1_5,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
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
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Row(
        children: [
          Expanded(
            child: RTLHelper.rtlTextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 16.h,
                ),
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
                suffixIcon:
                    _isPhoneVerified
                        ? Container(
                          margin: EdgeInsets.only(right: 8.w),
                          child: Icon(
                            Icons.verified,
                            color: AppColors.green,
                            size: 20.w,
                          ),
                        )
                        : TextButton(
                          onPressed: _isPhoneVerified ? null : _showOtpModal,
                          child: Text(
                            _isPhoneVerified ? 'Verified' : 'Send OTP',
                            style: TextStyle(
                              color:
                                  _isPhoneVerified
                                      ? AppColors.icongrey
                                      : AppColors.primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: RTLHelper.rtlTextField(
        readOnly: true,
        controller: controller,
        onTap: () => _showDropdownOptions(label, controller),
        decoration: InputDecoration(
          labelText: label,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
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
          suffixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: RTLHelper.rtlIcon(
              Icons.keyboard_arrow_down,
              color: AppColors.icongrey,
            ),
          ),
          // filled: true,
        ),
      ),
    );
  }

  void _showDropdownOptions(
    String fieldName,
    TextEditingController controller,
  ) {
    final options = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata'];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Select $fieldName',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 200.h,
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = controller.text == option;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            controller.text = option;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showOtpModal() {
    Get.bottomSheet(
      OtpModal(
        phoneNumber: _phoneController.text,
        onVerify: () {
          // Handle OTP verification
          Get.back(); // Close OTP modal
          setState(() {
            _isPhoneVerified = true;
          });
          Get.snackbar(
            'Success',
            'Phone number verified successfully!',
            backgroundColor: AppColors.green,
            colorText: AppColors.whiteColor,
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _handleSave() {
    // TODO: Implement save logic
    Get.snackbar(
      'Success',
      'Personal details saved successfully!',
      backgroundColor: AppColors.green,
      colorText: Colors.white,
    );

    // Navigate to next screen
    Future.delayed(Duration(seconds: 1), () {
      Get.toNamed(AppPages.KYC_DOCS);
    });
  }
}
