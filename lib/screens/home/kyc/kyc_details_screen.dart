import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/widgets/kyc_scaffold.dart';
import 'package:pipze/widgets/otp_modal.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/utils/trl_helper.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/dropdown_service.dart';

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
  final TextEditingController _addressController = TextEditingController(
    text: 'Value',
  );

  // Phone verification state
  bool _isPhoneVerified = false;

  // Dropdown service
  late DropdownService dropdownService;

  @override
  void initState() {
    super.initState();
    // Initialize dropdown service
    dropdownService = Get.put(DropdownService());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

                      // Country, State, and City dropdowns
                      _buildCountryDropdown(),
                      _buildStateDropdown(),
                      _buildCityDropdown(),

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

  // Country Dropdown
  Widget _buildCountryDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Obx(
        () => RTLHelper.rtlTextField(
          readOnly: true,
          controller: TextEditingController(
            text: dropdownService.selectedCountryText,
          ),
          onTap: () => _showCountryOptions(),
          decoration: InputDecoration(
            labelText: 'Country',
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
            // dropdownService.isLoadingCountries.value
            //     ? Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 14.w),
            //       child: SizedBox(
            //         width: 20.w,
            //         height: 20.h,
            //         child: CircularProgressIndicator(
            //           strokeWidth: 2,
            //           valueColor: AlwaysStoppedAnimation<Color>(
            //             AppColors.primary,
            //           ),
            //         ),
            //       ),
            //     )
            //     :
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: RTLHelper.rtlIcon(
                Icons.keyboard_arrow_down,
                color: AppColors.icongrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // State Dropdown
  Widget _buildStateDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Obx(
        () => RTLHelper.rtlTextField(
          readOnly: true,
          controller: TextEditingController(
            text: dropdownService.selectedStateText,
          ),
          onTap:
              dropdownService.selectedCountry.value != null
                  ? () => _showStateOptions()
                  : null,
          decoration: InputDecoration(
            labelText: 'State',
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
            // dropdownService.isLoadingStates.value
            // ? Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 14.w),
            //   child: SizedBox(
            //     width: 20.w,
            //     height: 20.h,
            //     child: CircularProgressIndicator(
            //       strokeWidth: 2,
            //       valueColor: AlwaysStoppedAnimation<Color>(
            //         AppColors.primary,
            //       ),
            //     ),
            //   ),
            // )
            // :
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: RTLHelper.rtlIcon(
                Icons.keyboard_arrow_down,
                color:
                    dropdownService.selectedCountry.value != null
                        ? AppColors.icongrey
                        : AppColors.icongrey.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // City Dropdown
  Widget _buildCityDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Obx(
        () => RTLHelper.rtlTextField(
          readOnly: true,
          controller: TextEditingController(
            text: dropdownService.selectedCityText,
          ),
          onTap:
              dropdownService.selectedState.value != null
                  ? () => _showCityOptions()
                  : null,
          decoration: InputDecoration(
            labelText: 'City',
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
            // dropdownService.isLoadingCities.value
            //     ? Padding(
            //       padding: EdgeInsets.symmetric(horizontal: 14.w),
            //       child: SizedBox(
            //         width: 20.w,
            //         height: 20.h,
            //         child: CircularProgressIndicator(
            //           strokeWidth: 2,
            //           valueColor: AlwaysStoppedAnimation<Color>(
            //             AppColors.primary,
            //           ),
            //         ),
            //       ),
            //     )
            //     :
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              child: RTLHelper.rtlIcon(
                Icons.keyboard_arrow_down,
                color:
                    dropdownService.selectedState.value != null
                        ? AppColors.icongrey
                        : AppColors.icongrey.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show Country Options
  void _showCountryOptions() {
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
                  'Select Country',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 300.h,
                  child: Obx(() {
                    if (dropdownService.isLoadingCountries.value) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: dropdownService.countries.length,
                      itemBuilder: (context, index) {
                        final country = dropdownService.countries[index];
                        final isSelected =
                            dropdownService.selectedCountry.value?.id ==
                            country.id;

                        return InkWell(
                          onTap: () {
                            dropdownService.selectCountry(country);
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
                                    country.name,
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
                    );
                  }),
                ),
              ],
            ),
          ),
    );
  }

  // Show State Options
  void _showStateOptions() {
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
                  'Select State',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 300.h,
                  child: Obx(() {
                    if (dropdownService.isLoadingStates.value) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: dropdownService.states.length,
                      itemBuilder: (context, index) {
                        final state = dropdownService.states[index];
                        final isSelected =
                            dropdownService.selectedState.value?.id == state.id;

                        return InkWell(
                          onTap: () {
                            dropdownService.selectState(state);
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
                                    state.name,
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
                    );
                  }),
                ),
              ],
            ),
          ),
    );
  }

  // Show City Options
  void _showCityOptions() {
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
                  'Select City',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 300.h,
                  child: Obx(() {
                    if (dropdownService.isLoadingCities.value) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: dropdownService.cities.length,
                      itemBuilder: (context, index) {
                        final city = dropdownService.cities[index];
                        final isSelected =
                            dropdownService.selectedCity.value?.id == city.id;

                        return InkWell(
                          onTap: () {
                            dropdownService.selectCity(city);
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
                                    city.name,
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
                    );
                  }),
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
    // Validate form fields
    if (_firstNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your first name',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_lastNameController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your last name',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your phone number',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (!dropdownService.isComplete) {
      Get.snackbar(
        'Error',
        'Please select country, state, and city',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your address',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    // TODO: Implement save logic with API call
    // You can access the selected values like this:
    // final country = dropdownService.selectedCountry.value;
    // final state = dropdownService.selectedState.value;
    // final city = dropdownService.selectedCity.value;

    print('Selected Country: ${dropdownService.selectedCountry.value?.name}');
    print('Selected State: ${dropdownService.selectedState.value?.name}');
    print('Selected City: ${dropdownService.selectedCity.value?.name}');

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
