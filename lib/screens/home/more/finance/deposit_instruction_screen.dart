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
import 'package:pipze/utils/navigation_helper.dart';
import 'package:pipze/widgets/custom_toast.dart';

import '../../../../constants/color.dart';
import '../../../../controllers/finance/deposit_instrction_controller.dart';
import '../../../../services/api_service.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/common_loading_widget.dart';
import 'package:image_picker/image_picker.dart';


class DepositInstructionScreen extends StatefulWidget {

  final Map<String, dynamic> object;
  final String amountString;
  final String selectedMT5AccountID;
  const DepositInstructionScreen({super.key, required this.object, required this.amountString,required this.selectedMT5AccountID});

  @override
  State<DepositInstructionScreen> createState() => _DepositInstructionScreenState();
}

class _DepositInstructionScreenState extends State<DepositInstructionScreen> {
  late final String titleString;

  final DepositInstructionController controller = Get.put(DepositInstructionController());
  final ApiService apiService = Get.put(ApiService());
  late final Map<String, dynamic>? bankDetail;
  late final LanguageService languageService;

  final TextEditingController transactionNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    languageService = Get.find<LanguageService>();

    bankDetail = widget.object['payment_gateway'];
    if (widget.object['type'].toString().toLowerCase() == 'bank') {
      titleString = 'Bank Transfer';
    } else if (widget.object['type'].toString().toLowerCase() == 'local') {
      titleString = 'Local Transfer';
    } else if (widget.object['typxe'].toString().toLowerCase() == 'crypto') {
      titleString = 'Coin';
    } else {
      titleString = 'UPI';
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
      body = _buildUPI();
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
            onPressed: () => NavigationHelper.safeBack(context: context),
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
          // Instruction Section
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
                _buildInstructionItem('Use Given bank details to make payment.'),
                const SizedBox(height: 8),
                _buildInstructionItem('You need to take a screenshot of successful payment.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Where UTR / transaction Number is clearly visible.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Upload screenshot in given upload field.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Press submit button to submit your deposit request.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Your payment will be credited into respective account.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Once reflected in our bank account.'),
                const SizedBox(height: 8),
                _buildInstructionItem('Transaction limit may vary as per your bank.'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bank Name

          _buildBankDetailRow('Bank Name', bankDetail?['bank_name'] ?? ''),

          const SizedBox(height: 16),

          // Bank Holder Name
          _buildBankDetailRow('Bank Holder Name', bankDetail?['holder_name'] ?? ''),

          const SizedBox(height: 16),

          // Account Number
          _buildBankDetailRow('Account Number', bankDetail?['bank_account_no'] ?? ''),

          const SizedBox(height: 16),

          // IFSC Code
          _buildBankDetailRow('IFSC Code', bankDetail?['ifsc_iban'] ?? ''),

          const SizedBox(height: 24),

          // Transaction Number TextField
          TextField(
            controller: transactionNumberController,
            decoration: InputDecoration(
              hintText: 'Transaction Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 24),

          // File Upload Section
          // GestureDetector(
          //   onTap: () => _showImagePicker(context),
          //   child: Center(
          //     child: Container(
          //       width: double.infinity,
          //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          //       decoration: BoxDecoration(
          //         color: Colors.grey[100],
          //         borderRadius: BorderRadius.circular(8),
          //         border: Border.all(
          //           color: Colors.grey,
          //           style: BorderStyle.solid,
          //         ),
          //       ),
          //       child: Obx(() {
          //         if (controller.selectedImage.value != null) {
          //           return Image.file(
          //             controller.selectedImage.value!,
          //             height: 120,
          //             fit: BoxFit.cover,
          //           );
          //         } else {
          //           return Column(
          //             children: [
          //               Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.grey[600]),
          //               const SizedBox(height: 12),
          //               Text(
          //                 'Upload file',
          //                 style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          //               ),
          //             ],
          //           );
          //         }
          //       }),
          //     ),
          //   ),
          // ),
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
          _buildContinueButton(),
        ],
      ),
    );
  }

  // Helper for bank detail row
  Widget _buildBankDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTextStyles.label,
              ),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                // Get.snackbar('Copied', '$label copied to clipboard');
                CustomToastService.showSuccess(message: '$label copied to clipboard',title: 'Copied');
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  "assets/svg/more/copy.svg",
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
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
          // const SizedBox(height: 24),

          // Address Section with label depending on type
          // Text(
          //   'UPI ID',
          //   style: const TextStyle(
          //     fontSize: 14,
          //     color: Colors.grey,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //     borderRadius: BorderRadius.circular(8),
          //     border: Border.all(color: Colors.grey[300]!),
          //   ),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: Obx(() => Text(
          //           controller.cryptoAddress.value,
          //           style: const TextStyle(
          //             fontSize: 16,
          //             fontWeight: FontWeight.w500,
          //           ),
          //         )),
          //       ),
          //       const SizedBox(width: 8),
          //       GestureDetector(
          //         onTap: controller.copyCryptoAddress,
          //         child: Container(
          //           padding: const EdgeInsets.all(4),
          //           child: SvgPicture.asset("assets/svg/more/copy.svg"),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          //
          // const SizedBox(height: 24),

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
          _buildContinueButton(),
          //
          // Obx(
          //       () =>
          //   controller.isLoading.value
          //       ? Center(child: OverlayLoadingWidget())
          //       : SizedBox.shrink(),
          // ),
        ],
      ),
    );
  }

  Widget _buildUPI() {
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
            'Scan UPI',
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
      height: 46.h,
      child: ElevatedButton(
        onPressed: () {

          print(widget.object);
          if (widget.object['type'].toString().toLowerCase() == 'bank') {
            if (transactionNumberController.text.isEmpty) {
              CustomToastService.showError(
                message: 'Please enter transaction number',
              );
            } else {
            controller.submitDepositInstruction({
            "gateway_method_id":widget.object['deposit_slug'],
            "amount":widget.amountString,
            "mt5_account_id": widget.selectedMT5AccountID
            });
            }
          } else if (widget.object['type'].toString().toLowerCase() == 'local') {
              controller.submitDepositInstruction({
              "gateway_method_id":widget.object['deposit_slug'],
              "amount":widget.amountString,
              "mt5_account_id": widget.selectedMT5AccountID
              });
          } else if (widget.object['type'].toString().toLowerCase() == 'crypto') {
              controller.submitDepositInstruction({
              "gateway_method_id":widget.object['deposit_slug'],
              "amount":widget.amountString,
              "mt5_account_id": widget.selectedMT5AccountID
              });
          } else {
            // titleString = 'UPI';
          }
        },
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
          languageService.tr("deposit_confirm_deposit"),
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
