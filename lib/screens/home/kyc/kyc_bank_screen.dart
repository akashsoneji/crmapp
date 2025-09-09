import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/widgets/kyc_scaffold.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';

import '../../../routes/app_pages.dart';
import '../../../utils/trl_helper.dart';


class KycBankScreen extends StatefulWidget {
  const KycBankScreen({Key? key}) : super(key: key);

  @override
  State<KycBankScreen> createState() => _KycBankScreenState();
}

class _KycBankScreenState extends State<KycBankScreen> {
  final TextEditingController _accountHolderController =
      TextEditingController(text: 'Simmons');
  final TextEditingController _beneficiaryBankController =
      TextEditingController(text: 'John Doe');
  final TextEditingController _ibanController = TextEditingController(text: 'Value');
  final TextEditingController _codeController = TextEditingController(text: 'Value');
  final TextEditingController _accountNumberController =
      TextEditingController(text: '12341234');
  final TextEditingController _confirmAccountNumberController =
      TextEditingController(text: '12341234');
  final TextEditingController _swiftCodeController =
      TextEditingController(text: '12341234');

  String _selectedAccountType = "Bank";
  String _selectedCurrency = "Euro";
  String _selectedIban = "Value1";

  File? _proofFile;

  @override
  Widget build(BuildContext context) {
    return KycScaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15.h),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Account Type field
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.h, top: 8.h),
                        child: GestureDetector(
                          onTap: _showAccountTypeOptions,
                          child: RTLHelper.rtlTextField(
                            controller: TextEditingController(text: _selectedAccountType),
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Account Type',
                              suffixIcon: Icon(Icons.keyboard_arrow_down, color: AppColors.icongrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Currency field
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: GestureDetector(
                          onTap: _showCurrencyOptions,
                          child: RTLHelper.rtlTextField(
                            controller: TextEditingController(text: _selectedCurrency),
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              suffixIcon: Icon(Icons.keyboard_arrow_down, color: AppColors.icongrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border),
                              ),
                            ),
                          ),
                        ),
                      ),

                      _buildFormField("Account Holder Name", _accountHolderController),
                      _buildFormField("Beneficiary Bank Name", _beneficiaryBankController),

                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 20.h),
                              child: GestureDetector(
                                onTap: _showIbanOptions,
                                child: RTLHelper.rtlTextField(
                                  controller: TextEditingController(text: _selectedIban),
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'IBAN/IFSC',
                                    suffixIcon: Icon(Icons.keyboard_arrow_down, color: AppColors.icongrey),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppColors.border),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(child: _buildFormField("Code", _codeController)),
                        ],
                      ),

                      _buildFormField("Bank Account Number", _accountNumberController),
                      _buildFormField("Confirm Bank Account Number", _confirmAccountNumberController),
                      _buildFormField("Bank Swift code", _swiftCodeController),

                      SizedBox(height: 16.h),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "ADD Proof",
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: _showProofOptions,
                        child: Container(
                          height: 120.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            border: Border.all(color: AppColors.primary, style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: _proofFile == null
                              ? Center(
                                  child: Icon(Icons.add, size: 32.sp, color: AppColors.primary),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Image.file(_proofFile!, fit: BoxFit.cover, width: double.infinity),
                                ),
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: () {
                    // Get.snackbar("OTP Sent", "We’ve sent OTP to your registered number",
                    //     backgroundColor: AppColors.green, colorText: Colors.white);
                    Future.delayed(Duration(seconds: 1), () {
                      Get.toNamed(AppPages.KYC_SUCCESS);
                    });

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Send OTP',
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
  // Helper for Account Type bottom sheet
  void _showAccountTypeOptions() {
    final List<String> accountTypes = ["Bank", "Wallet"];
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: accountTypes.map((type) {
              return ListTile(
                title: Text(type),
                onTap: () {
                  setState(() => _selectedAccountType = type);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Helper for Currency bottom sheet
  void _showCurrencyOptions() {
    final List<String> currencies = ["Euro", "USD", "INR"];
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: currencies.map((currency) {
              return ListTile(
                title: Text(currency),
                onTap: () {
                  setState(() => _selectedCurrency = currency);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Helper for IBAN/IFSC bottom sheet
  void _showIbanOptions() {
    final List<String> ibans = ["Value", "Value1", "Value2"];
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: ibans.map((iban) {
              return ListTile(
                title: Text(iban),
                onTap: () {
                  setState(() => _selectedIban = iban);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showProofOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take Photo'),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _proofFile = File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Select from Gallery'),
                onTap: () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _proofFile = File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file),
                title: Text('Attach from Documents'),
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.any);
                  if (result != null && result.files.single.path != null) {
                    setState(() => _proofFile = File(result.files.single.path!));
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: TextField(
        controller: controller,
        style: AppTextStyles.black16400h1_5,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label, String value, List<String> options, Function(String) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: DropdownButtonFormField<String>(
        value: value,
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: (val) => onChanged(val!),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
