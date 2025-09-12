import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:pipze/constants/text_styles.dart';

import '../../../../constants/color.dart';
import '../../../../controllers/finance/deposit_instrction_controller.dart';
import '../../../../services/api_service.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/common_loading_widget.dart';
import 'package:image_picker/image_picker.dart';


class DepositInstructionScreen extends StatefulWidget {

  final Map<String, dynamic> object;
  const DepositInstructionScreen({super.key, required this.object});

  @override
  State<DepositInstructionScreen> createState() => _DepositInstructionScreenState();
}

class _DepositInstructionScreenState extends State<DepositInstructionScreen> {
  late final String titleString;
  final DepositInstructionController controller = Get.put(DepositInstructionController());
  final ApiService apiService = Get.put(ApiService());

  late final LanguageService languageService;

  final TextEditingController transactionNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    languageService = Get.find<LanguageService>();

    if (widget.object['type'].toString().toLowerCase() == 'bank') {
      titleString = 'Bank Transfer';
    } else if (widget.object['type'].toString().toLowerCase() == 'local') {
      titleString = 'UPI';
    } else if (widget.object['type'].toString().toLowerCase() == 'crypto') {
      titleString = 'Coin';
    } else {
      titleString = '';
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.object['type'].toString().toLowerCase();
    Widget body;
    if (type == 'bank') {
      body = _buildBankUI();
    } else if (type == 'crypto') {
      body = _buildCryptoUI();
    } else if (type == 'local') {
      body = _buildLocalUI();
    } else {
      body = const SizedBox();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: IconButton(
            icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
            onPressed: () => Get.back(),
          ),
        ),
        title: Text(
          titleString,
          style: AppTextStyles.screenTitle,
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }

  Widget _buildBankUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction Card for Bank
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide.none),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide.none),
              title: const Text(
                'Instruction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                _buildInstructionItem('Transfer funds using your bank account details provided.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Enter Amount that you want to transfer and make payment.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Press submit button to submit your deposit request.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Your payment will be credited into respective account once reflected in company\'s account.'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bank Name
          Text(
            'Bank Name',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.object['bankName'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.object['bankName'] ?? ''));
                    Get.snackbar('Copied', 'Bank Name copied to clipboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset("assets/svg/more/copy.svg"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bank Holder Name
          Text(
            'Bank Holder Name',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.object['bankHolderName'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.object['bankHolderName'] ?? ''));
                    Get.snackbar('Copied', 'Bank Holder Name copied to clipboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset("assets/svg/more/copy.svg"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Account Number
          Text(
            'Account Number',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.object['accountNumber'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.object['accountNumber'] ?? ''));
                    Get.snackbar('Copied', 'Account Number copied to clipboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset("assets/svg/more/copy.svg"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // IFSC Code
          Text(
            'IFSC Code',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.object['ifscCode'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.object['ifscCode'] ?? ''));
                    Get.snackbar('Copied', 'IFSC Code copied to clipboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset("assets/svg/more/copy.svg"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transaction Number TextField
          Text(
            'Transaction Number',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: transactionNumberController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              hintText: 'Enter transaction number',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 24),

          // File Upload Section
          GestureDetector(
            onTap: () => _showImagePicker(context),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Obx(() {
                  if (controller.selectedImage.value != null) {
                    return Image.file(
                      controller.selectedImage.value!,
                      height: 120,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload file',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  }
                }),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          _buildContinueButton()
        ],
      ),
    );
  }

  Widget _buildCryptoUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instruction Card
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide.none),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide.none),
              title: const Text(
                'Instruction',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                _buildInstructionItem('Use Below Give QR Code to make payment via UPI.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Alternatively, enter your UPI ID to make payment.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Enter Amount that you want to transfer and make payment.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Press submit button to submit your deposit request.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Your payment will be credited into respective account once reflected in company\'s account.'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const SizedBox(height: 24),

          // Address Section with label depending on type
          Text(
            'UPI ID',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => Text(
                    controller.cryptoAddress.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  )),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: controller.copyCryptoAddress,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset("assets/svg/more/copy.svg"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // File Upload Section
          GestureDetector(
            onTap: () => _showImagePicker(context),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Obx(() {
                  if (controller.selectedImage.value != null) {
                    return Image.file(
                      controller.selectedImage.value!,
                      height: 120,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Upload file',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  }
                }),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Submit Button
          _buildContinueButton()
        ],
      ),
    );
  }

  Widget _buildLocalUI() {
    // For now, use same as _buildCryptoUI
    return _buildCryptoUI();
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () { },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          languageService.tr("deposit_confirm_deposit"),
          style: AppTextStyles.button,
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, right: 8),
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
