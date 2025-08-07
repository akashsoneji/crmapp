import 'dart:ui' as ui;
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/utils/trl_helper.dart';

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
  String _selectedCountry = '';
  String? _selectedGender;
  String? _selectedState;
  bool _isFormValid = false;
  final LanguageService languageService = Get.find<LanguageService>();

  final List<String> genderList = ['Male', 'Female', 'Other'];
  final List<String> stateList = [
    'Gujarat',
    'Maharashtra',
    'Delhi',
    'Gujarat',
    'Maharashtra',
    'Delhi',
    'Gujarat',
    'Maharashtra',
    'Delhi',
  ];
  final List<String> cityList = [
    'Ahmedabad',
    'Mumbai',
    'Delhi',
    'Gujarat',
    'Maharashtra',
    'Delhi',
    'Gujarat',
    'Maharashtra',
    'Delhi',
  ];

  @override
  void initState() {
    super.initState();
    _addListeners();
    _setDeviceCountry();
  }

  void _addListeners() {
    _firstNameController.addListener(_validateForm);
    _lastNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _addressController.addListener(_validateForm);
    _cityController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _firstNameController.text.isNotEmpty &&
          _lastNameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _phoneController.text.isNotEmpty &&
          _selectedDate != null &&
          _selectedGender != null &&
          _selectedCountry.isNotEmpty &&
          _selectedState != null &&
          _cityController.text.isNotEmpty &&
          _addressController.text.isNotEmpty;
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
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _validateForm();
      });
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
        setState(() {
          _selectedCountry = "${country.flagEmoji} ${country.name}";
          _validateForm();
        });
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
        setState(() {
          _selectedCountry = "${deviceCountry.flagEmoji} ${deviceCountry.name}";
          _validateForm();
        });
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
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20.sp,
                fontFamily: 'RobotoMono',
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RTLHelper.rtlTextField(
                      controller: _firstNameController,
                      labelText: languageService.tr('edit_profile_first_name'),
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
                    RTLHelper.rtlTextField(
                      controller: TextEditingController(
                        text:
                            _selectedDate == null
                                ? ''
                                : DateFormat(
                                  'dd MMM yyyy',
                                ).format(_selectedDate!),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (_selectedDate == null) {
                          return languageService.tr(
                            'edit_profile_please_select_dob',
                          );
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    RTLHelper.rtlTextField(
                      controller: TextEditingController(
                        text: _selectedGender ?? '',
                      ),
                      labelText: languageService.tr('edit_profile_gender'),
                      readOnly: true,
                      onTap:
                          () => _showBottomSheetList(
                            context: context,
                            items: genderList,
                            title: languageService.tr(
                              'edit_profile_select_gender',
                            ),
                            onItemSelected: (value) {
                              setState(() {
                                _selectedGender = value;
                                _validateForm();
                              });
                            },
                          ),
                      suffixIcon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      validator: (value) {
                        if (_selectedGender == null ||
                            _selectedGender!.isEmpty) {
                          return languageService.tr(
                            'edit_profile_select_gender',
                          );
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    RTLHelper.rtlTextField(
                      controller: TextEditingController(text: _selectedCountry),
                      labelText: languageService.tr('register_country'),
                      readOnly: true,
                      onTap: _showCountryPicker,
                      suffixIcon: InkWell(
                        onTap: _showCountryPicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (_selectedCountry.isEmpty) {
                          return languageService.tr(
                            'validation_country_required',
                          );
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: RTLHelper.rtlTextField(
                            controller: _cityController,
                            labelText: languageService.tr('edit_profile_city'),
                            readOnly: true,
                            onTap:
                                () => _showBottomSheetList(
                                  context: context,
                                  items: cityList,
                                  title: languageService.tr(
                                    'edit_profile_select_city',
                                  ),
                                  onItemSelected: (value) {
                                    setState(() {
                                      _cityController.text = value;
                                      _validateForm();
                                    });
                                  },
                                ),
                            suffixIcon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                            validator: (value) {
                              if (_cityController.text.isEmpty) {
                                return languageService.tr(
                                  'edit_profile_select_city',
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: RTLHelper.rtlTextField(
                            controller: TextEditingController(
                              text: _selectedState ?? '',
                            ),
                            labelText: languageService.tr('edit_profile_state'),
                            readOnly: true,
                            onTap:
                                () => _showBottomSheetList(
                                  context: context,
                                  items: stateList,
                                  title: languageService.tr(
                                    'edit_profile_select_state',
                                  ),
                                  onItemSelected: (value) {
                                    setState(() {
                                      _selectedState = value;
                                      _validateForm();
                                    });
                                  },
                                ),
                            suffixIcon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                            validator: (value) {
                              if (_selectedState == null ||
                                  _selectedState!.isEmpty) {
                                return languageService.tr(
                                  'edit_profile_select_state',
                                );
                              }
                              return null;
                            },
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
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: RTLHelper.rtlButton(
                        text: languageService.tr('navigation_save'),
                        onPressed:
                            _isFormValid
                                ? () {
                                  if (_formKey.currentState!.validate()) {
                                    // Save profile logic here
                                    // Get.snackbar('Success', 'Profile updated successfully!', backgroundColor: Colors.green, colorText: Colors.white);
                                  }
                                }
                                : null,
                        backgroundColor: AppColors.primary,
                        foregroundColor:
                            _isFormValid ? Colors.white : AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
