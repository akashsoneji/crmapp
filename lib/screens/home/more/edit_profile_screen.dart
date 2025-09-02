import 'dart:ui' as ui;
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/controllers/more/edit_profile_controller.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/trl_helper.dart';

import '../../../constants/text_styles.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  DateTime? _selectedDate;
  final LanguageService languageService = Get.find<LanguageService>();
  final EditProfileController controller = Get.put(EditProfileController());

  @override
  void initState() {
    super.initState();
    _addListeners();
    _setDeviceCountry();
    _bindControllerData();
  }

  void _addListeners() {
    _firstNameController.addListener(() {
      controller.updateFirstName(_firstNameController.text);
    });
    _lastNameController.addListener(() {
      controller.updateLastName(_lastNameController.text);
    });
    _emailController.addListener(() {
      controller.updateEmail(_emailController.text);
    });
    _phoneController.addListener(() {
      controller.updatePhone(_phoneController.text);
    });
    _addressController.addListener(() {
      controller.updateAddress(_addressController.text);
    });
    _cityController.addListener(() {
      controller.updateCity(_cityController.text);
    });
  }

  void _bindControllerData() {
    // Listen to controller data changes and update text controllers
    ever(controller.firstName, (value) {
      if (_firstNameController.text != value) {
        _firstNameController.text = value;
      }
    });
    ever(controller.lastName, (value) {
      if (_lastNameController.text != value) {
        _lastNameController.text = value;
      }
    });
    ever(controller.email, (value) {
      if (_emailController.text != value) {
        _emailController.text = value;
      }
    });
    ever(controller.phone, (value) {
      if (_phoneController.text != value) {
        _phoneController.text = value;
      }
    });
    ever(controller.address, (value) {
      if (_addressController.text != value) {
        _addressController.text = value;
      }
    });
    ever(controller.city, (value) {
      if (_cityController.text != value) {
        _cityController.text = value;
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime.now().subtract(
        const Duration(days: 36500),
      ), // 100 years ago
      lastDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      controller.updateDateOfBirth(DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, color: Colors.black),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        inputDecoration: InputDecoration(
          labelText: languageService.tr('common_search'),
          hintText: languageService.tr('common_search'),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withOpacity(0.2),
            ),
          ),
        ),
      ),
      onSelect: (Country country) {
        controller.updateCountry("${country.flagEmoji} ${country.name}");
      },
    );
  }

  void _setDeviceCountry() {
    try {
      final deviceLocale = ui.window.locale;
      final countryCode = deviceLocale.countryCode;
      if (countryCode != null && countryCode.isNotEmpty) {
        final countries = CountryService().getAll();
        final deviceCountry = countries.firstWhere(
          (country) => country.countryCode == countryCode,
          orElse: () => countries.first,
        );
        controller.updateCountry(
          "${deviceCountry.flagEmoji} ${deviceCountry.name}",
        );
      }
    } catch (e) {
      // ignore
    }
  }

  void _showBottomSheetList({
    required BuildContext context,
    required List<String> items,
    required String title,
    required ValueChanged<String> onItemSelected,
  }) {
    final itemHeight = 56.0;
    final maxHeight =
        MediaQuery.of(context).size.height * 0.85; // below app bar
    final totalHeight =
        (items.length * itemHeight) + 80; // include padding + title

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: totalHeight > maxHeight ? maxHeight : totalHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(items[index]),
                      onTap: () {
                        Navigator.pop(context);
                        onItemSelected(items[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            scrolledUnderElevation: 0.0,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.backgroundLight,
            title: Text(
              languageService.tr('edit_profile'),
              style: AppTextStyles.screenTitle,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(height: 50.h),
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading profile data...',
                          style: AppTextStyles.subheading.copyWith(
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (controller.errorMessage.value.isNotEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        SizedBox(height: 50.h),
                        Icon(
                          Icons.error_outline,
                          size: 48.h,
                          color: AppColors.red,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          controller.errorMessage.value,
                          style: AppTextStyles.subheading.copyWith(
                            color: AppColors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: () {
                            controller.loadProfileData();
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RTLHelper.rtlTextField(
                        controller: _firstNameController,
                        labelText: languageService.tr(
                          'edit_profile_first_name',
                        ),
                        hintText: languageService.tr(
                          'edit_profile_please_enter_first_name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr(
                              'edit_profile_please_enter_first_name',
                            );
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      RTLHelper.rtlTextField(
                        controller: _lastNameController,
                        labelText: languageService.tr('edit_profile_last_name'),
                        hintText: languageService.tr(
                          'edit_profile_please_enter_last_name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr(
                              'edit_profile_please_enter_last_name',
                            );
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      RTLHelper.rtlTextField(
                        controller: _emailController,
                        labelText: languageService.tr('edit_profile_email'),
                        hintText: languageService.tr(
                          'edit_profile_please_enter_email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr(
                              'edit_profile_please_enter_email',
                            );
                          }
                          if (!RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          ).hasMatch(value)) {
                            return languageService.tr(
                              'edit_profile_please_enter_valid_email',
                            );
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      RTLHelper.rtlTextField(
                        controller: _phoneController,
                        labelText: languageService.tr(
                          'edit_profile_mobile_number',
                        ),
                        hintText: languageService.tr(
                          'edit_profile_please_enter_mobile_number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr(
                              'edit_profile_please_enter_mobile_number',
                            );
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      Obx(
                        () => RTLHelper.rtlTextField(
                          controller: TextEditingController(
                            text:
                                controller.dateOfBirth.value.isEmpty
                                    ? ''
                                    : controller.dateOfBirth.value,
                          ),
                          labelText: languageService.tr(
                            'edit_profile_date_of_birth',
                          ),
                          hintText: languageService.tr(
                            'edit_profile_please_select_dob',
                          ),
                          readOnly: true,
                          onTap: _selectDate,
                          suffixIcon: InkWell(
                            onTap: _selectDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (controller.dateOfBirth.value.isEmpty) {
                              return languageService.tr(
                                'edit_profile_please_select_dob',
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Obx(
                        () => RTLHelper.rtlTextField(
                          controller: TextEditingController(
                            text: controller.gender.value,
                          ),
                          labelText: languageService.tr('edit_profile_gender'),
                          readOnly: true,
                          onTap:
                              () => _showBottomSheetList(
                                context: context,
                                items: controller.genderList,
                                title: languageService.tr(
                                  'edit_profile_select_gender',
                                ),
                                onItemSelected: (value) {
                                  controller.updateGender(value);
                                },
                              ),
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          validator: (value) {
                            if (controller.gender.value.isEmpty) {
                              return languageService.tr(
                                'edit_profile_select_gender',
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Obx(
                        () => RTLHelper.rtlTextField(
                          controller: TextEditingController(
                            text: controller.country.value,
                          ),
                          labelText: languageService.tr('register_country'),
                          readOnly: true,
                          onTap: _showCountryPicker,
                          suffixIcon: InkWell(
                            onTap: _showCountryPicker,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (controller.country.value.isEmpty) {
                              return languageService.tr(
                                'validation_country_required',
                              );
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(
                              () => RTLHelper.rtlTextField(
                                controller: _cityController,
                                labelText: languageService.tr(
                                  'edit_profile_city',
                                ),
                                readOnly: true,
                                onTap:
                                    () => _showBottomSheetList(
                                      context: context,
                                      items: controller.cityList,
                                      title: languageService.tr(
                                        'edit_profile_select_city',
                                      ),
                                      onItemSelected: (value) {
                                        controller.updateCity(value);
                                      },
                                    ),
                                suffixIcon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                                // City is optional - no validation required
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Obx(
                              () => RTLHelper.rtlTextField(
                                controller: TextEditingController(
                                  text: controller.state.value,
                                ),
                                labelText: languageService.tr(
                                  'edit_profile_state',
                                ),
                                readOnly: true,
                                onTap:
                                    () => _showBottomSheetList(
                                      context: context,
                                      items: controller.stateList,
                                      title: languageService.tr(
                                        'edit_profile_select_state',
                                      ),
                                      onItemSelected: (value) {
                                        controller.updateState(value);
                                      },
                                    ),
                                suffixIcon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey,
                                ),
                                // State is optional - no validation required
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),
                      RTLHelper.rtlTextField(
                        controller: _addressController,
                        labelText: languageService.tr('register_address'),
                        hintText: languageService.tr(
                          'edit_profile_please_enter_address',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return languageService.tr(
                              'edit_profile_please_enter_address',
                            );
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 16.w,
          right: 16.w,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56.h,
          child: Obx(
            () => RTLHelper.rtlButton(
              text:
                  controller.isSaving.value
                      ? 'Saving...'
                      : languageService.tr('navigation_save'),
              onPressed:
                  controller.isFormValid.value && !controller.isSaving.value
                      ? () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await controller.updateProfile();
                          if (success) {
                            Navigator.of(context).pop();
                          }
                        }
                      }
                      : null,
              backgroundColor: AppColors.primary,
              foregroundColor:
                  controller.isFormValid.value && !controller.isSaving.value
                      ? Colors.white
                      : AppColors.textGrey,
            ),
          ),
        ),
      ),
    );
  }
}
