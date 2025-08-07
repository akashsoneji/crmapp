import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';

import '../../../constants/color.dart';
import '../../../services/language_service.dart';
import '../../../utils/trl_helper.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
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
  final List<String> stateList = ['Gujarat', 'Maharashtra', 'Delhi','Gujarat', 'Maharashtra', 'Delhi','Gujarat', 'Maharashtra', 'Delhi'];
  final List<String> cityList = ['Ahmedabad', 'Mumbai', 'Delhi','Gujarat', 'Maharashtra', 'Delhi','Gujarat', 'Maharashtra', 'Delhi'];

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
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
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
    final maxHeight = MediaQuery.of(context).size.height * 0.85; // below app bar
    final totalHeight = (items.length * itemHeight) + 80; // include padding + title

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
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              languageService.tr('withdrawal'),
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
                      hintText: languageService.tr('edit_profile_please_enter_first_name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return languageService.tr('edit_profile_please_enter_first_name');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    RTLHelper.rtlTextField(
                      controller: _lastNameController,
                      labelText: languageService.tr('edit_profile_last_name'),
                      hintText: languageService.tr('edit_profile_please_enter_last_name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return languageService.tr('edit_profile_please_enter_last_name');
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16.h),
                    RTLHelper.rtlTextField(
                      controller: _phoneController,
                      labelText: languageService.tr('edit_profile_mobile_number'),
                      hintText: languageService.tr('edit_profile_please_enter_mobile_number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return languageService.tr('edit_profile_please_enter_mobile_number');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    RTLHelper.rtlTextField(
                      controller: TextEditingController(text: _selectedGender ?? ''),
                      labelText: languageService.tr('edit_profile_gender'),
                      readOnly: true,
                      onTap: () => _showBottomSheetList(
                        context: context,
                        items: genderList,
                        title: languageService.tr('edit_profile_select_gender'),
                        onItemSelected: (value) {
                          setState(() {
                            _selectedGender = value;
                            _validateForm();
                          });
                        },
                      ),
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      validator: (value) {
                        if (_selectedGender == null || _selectedGender!.isEmpty) {
                          return languageService.tr('edit_profile_select_gender');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 106.h),

                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: RTLHelper.rtlButton(
                        text: languageService.tr('navigation_save'),
                        onPressed: _isFormValid
                            ? () {
                          if (_formKey.currentState!.validate()) {
                            // Save profile logic here
                            // Get.snackbar('Success', 'Profile updated successfully!', backgroundColor: Colors.green, colorText: Colors.white);
                          }
                        }
                            : null,
                        backgroundColor: AppColors.primary,
                        foregroundColor: _isFormValid ? Colors.white : AppColors.textGrey,
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
