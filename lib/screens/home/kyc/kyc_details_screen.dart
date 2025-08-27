import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/widgets/kyc_scaffold.dart';
import 'package:pipze/widgets/otp_modal.dart';
import 'package:pipze/routes/app_pages.dart';

class KycDetailsScreen extends StatefulWidget {
  const KycDetailsScreen({Key? key}) : super(key: key);

  @override
  State<KycDetailsScreen> createState() => _KycDetailsScreenState();
}

class _KycDetailsScreenState extends State<KycDetailsScreen> {
  final TextEditingController _firstNameController = TextEditingController(text: 'Brooklyn');
  final TextEditingController _lastNameController = TextEditingController(text: 'Simmons');
  final TextEditingController _emailController = TextEditingController(text: 'brooklynsimmons@gmail.com');
  final TextEditingController _phoneController = TextEditingController(text: '+91 987654321');
  final TextEditingController _cityController = TextEditingController(text: 'Value');
  final TextEditingController _stateController = TextEditingController(text: 'Value');
  final TextEditingController _addressController = TextEditingController(text: 'Value');

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
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              SizedBox(height: 32.h),

              // Form Fields
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFormField(
                        label: 'First Name',
                        controller: _firstNameController,
                      ),
                      SizedBox(height: 24.h),

                      _buildFormField(
                        label: 'Last',
                        controller: _lastNameController,
                      ),
                      SizedBox(height: 24.h),

                      _buildFormField(
                        label: 'Email',
                        controller: _emailController,
                      ),
                      SizedBox(height: 24.h),

                      _buildPhoneField(),
                      SizedBox(height: 24.h),

                      _buildDropdownField(
                        label: 'City',
                        controller: _cityController,
                      ),
                      SizedBox(height: 24.h),

                      _buildDropdownField(
                        label: 'State',
                        controller: _stateController,
                      ),
                      SizedBox(height: 24.h),

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
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A2DD8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF5A2DD8), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneController,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF5A2DD8), width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  suffixIcon: Container(
                    margin: EdgeInsets.only(right: 8.w),
                    child: Icon(
                      Icons.verified,
                      color: Colors.grey[400],
                      size: 20.w,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            TextButton(
              onPressed: _showOtpModal,
              child: Text(
                'Send OTP',
                style: TextStyle(
                  color: const Color(0xFF5A2DD8),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _showDropdownOptions(label, controller),
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF5A2DD8), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            suffixIcon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 24.w,
            ),
          ),
        ),
      ],
    );
  }

  void _showDropdownOptions(String fieldName, TextEditingController controller) {
    final options = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata'];
    
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Select $fieldName',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24.h),
            ...options.map((option) => ListTile(
              title: Text(option),
              onTap: () {
                controller.text = option;
                Get.back();
              },
            )),
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
          Get.snackbar(
            'Success',
            'Phone number verified successfully!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
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
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    
    // Navigate to next screen
    Future.delayed(Duration(seconds: 1), () {
      Get.toNamed(AppPages.KYC_DOCS);
    });
  }
}
