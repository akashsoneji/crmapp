import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/trade_win/trade_win_redeem_controller.dart';
import 'package:crm_app/models/trade_win/trade_win_product_model.dart';
import 'package:crm_app/models/trade_win/trade_win_shipping_details_model.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trade_win_format.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_product_image.dart';
import 'package:crm_app/screens/trade_win/trade_win_theme.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_redeem_stepper.dart';

class TradeWinRedeemScreen extends StatefulWidget {
  const TradeWinRedeemScreen({super.key});

  @override
  State<TradeWinRedeemScreen> createState() => _TradeWinRedeemScreenState();
}

class _TradeWinRedeemScreenState extends State<TradeWinRedeemScreen> {
  TradeWinRedeemController? _controller;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _rememberAddress = true.obs;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final product = args?['product'] as TradeWinProductModel?;
    final quantity = args?['quantity'] as int? ?? 1;

    if (product == null) {
      _initialized = false;
      return;
    }

    final redeemController = TradeWinRedeemController(
      product: product,
      initialQuantity: quantity,
    );
    _controller = redeemController;
    Get.put(redeemController, tag: TradeWinRedeemController.redeemTag);
    _initialized = true;
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final saved = await TradeWinRedeemController.loadSavedAddress();
    if (!mounted) return;
    _nameController.text = saved.name;
    _phoneController.text = saved.phone;
    _emailController.text = saved.email;
    _addressController.text = saved.address;
    _cityController.text = saved.city;
    _countryController.text = saved.country;
  }

  TradeWinShippingDetailsModel get _shippingDetails =>
      TradeWinShippingDetailsModel(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
      );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _rememberAddress.close();
    if (_initialized &&
        Get.isRegistered<TradeWinRedeemController>(
          tag: TradeWinRedeemController.redeemTag,
        )) {
      Get.delete<TradeWinRedeemController>(
        tag: TradeWinRedeemController.redeemTag,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_initialized || controller == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Text(Get.find<LanguageService>().tr('tw_product_not_found')),
        ),
      );
    }

    final languageService = Get.find<LanguageService>();

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        centerTitle: true,
        title: Text(languageService.tr('tw_redeem'), style: AppTextStyles.heading),
        leading: Obx(() {
          if (controller.currentStep.value > 1) {
            return IconButton(
              onPressed: () => controller.goToStep(controller.currentStep.value - 1),
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            );
          }
          return IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          );
        }),
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.close, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: Obx(() {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: TradeWinRedeemStepper(
                currentStep: controller.currentStep.value,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: controller.currentStep.value == 1
                    ? _StepConfirm(
                        controller: controller,
                        languageService: languageService,
                      )
                    : _StepShipping(
                        languageService: languageService,
                        nameController: _nameController,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        addressController: _addressController,
                        cityController: _cityController,
                        countryController: _countryController,
                        rememberAddress: _rememberAddress,
                      ),
              ),
            ),
            _BottomActions(
              controller: controller,
              languageService: languageService,
              onSubmit: () {
                if (!TradeWinRedeemController.validateShipping(_shippingDetails)) {
                  CustomToastService.showWarning(
                    message: languageService.tr('tw_fill_all_fields'),
                  );
                  return;
                }
                controller.submitRedemption(
                  shipping: _shippingDetails,
                  rememberAddress: _rememberAddress.value,
                );
              },
            ),
          ],
        );
      }),
    );
  }
}

class _StepConfirm extends StatelessWidget {
  final TradeWinRedeemController controller;
  final LanguageService languageService;

  const _StepConfirm({
    required this.controller,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    final product = controller.product;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageService.tr('tw_step_confirm'),
          style: AppTextStyles.headingblack.copyWith(
            fontSize: 15.sp,
            color: TradeWinTheme.sectionTitle,
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            TradeWinProductImage(
              imagePath: product.imagePath,
              width: 56.w,
              height: 56.w,
              borderRadius: BorderRadius.circular(8.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.headingblack),
                  Text(
                    TradeWinFormat.categoryLabel(product.category),
                    style: AppTextStyles.subheading,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Obx(
            () => Column(
              children: [
                _SummaryRow(
                  label: languageService.tr('tw_item'),
                  value: product.name,
                ),
                Divider(height: 1, color: AppColors.icongrey.withValues(alpha: 0.15)),
                _SummaryRow(
                  label: languageService.tr('tw_quantity'),
                  value: '${controller.quantity.value}',
                ),
                Divider(height: 1, color: AppColors.icongrey.withValues(alpha: 0.15)),
                _SummaryRow(
                  label: languageService.tr('tw_total_cost'),
                  value: TradeWinFormat.points(controller.totalCost),
                ),
                Divider(height: 1, color: AppColors.icongrey.withValues(alpha: 0.15)),
                _SummaryRow(
                  label: languageService.tr('tw_balance_after'),
                  value: TradeWinFormat.points(controller.balanceAfter),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningText, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  languageService.tr('tw_points_deduct_warning'),
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.warningText,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepShipping extends StatelessWidget {
  final LanguageService languageService;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController countryController;
  final RxBool rememberAddress;

  const _StepShipping({
    required this.languageService,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.cityController,
    required this.countryController,
    required this.rememberAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageService.tr('tw_step_shipping'),
          style: AppTextStyles.headingblack.copyWith(
            fontSize: 15.sp,
            color: TradeWinTheme.sectionTitle,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          languageService.tr('tw_shipping_instruction'),
          style: AppTextStyles.subheading.copyWith(fontSize: 12.sp),
        ),
        SizedBox(height: 10.h),
        _Field(label: languageService.tr('tw_full_name'), controller: nameController),
        _Field(label: languageService.tr('tw_phone'), controller: phoneController, keyboard: TextInputType.phone),
        _Field(label: languageService.tr('tw_email'), controller: emailController, keyboard: TextInputType.emailAddress),
        _Field(label: languageService.tr('tw_address'), controller: addressController, maxLines: 3),
        Row(
          children: [
            Expanded(child: _Field(label: languageService.tr('tw_city'), controller: cityController)),
            SizedBox(width: 10.w),
            Expanded(child: _Field(label: languageService.tr('tw_country'), controller: countryController)),
          ],
        ),
        Obx(
          () => CheckboxListTile(
            value: rememberAddress.value,
            onChanged: (v) => rememberAddress.value = v ?? false,
            activeColor: AppColors.brandPrimary,
            title: Text(
              languageService.tr('tw_remember_address'),
              style: AppTextStyles.subheading.copyWith(fontSize: 13.sp),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.quickActionBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: AppColors.quickActionBlue, size: 22.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  languageService.tr('tw_estimated_delivery'),
                  style: AppTextStyles.subheading.copyWith(fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          SizedBox(height: 4.h),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: AppTextStyles.input,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: AppColors.icongrey.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: AppColors.icongrey.withValues(alpha: 0.25)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.subheading),
          Text(value, style: AppTextStyles.headingblack.copyWith(fontSize: 14.sp)),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final TradeWinRedeemController controller;
  final LanguageService languageService;
  final VoidCallback onSubmit;

  const _BottomActions({
    required this.controller,
    required this.languageService,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.currentStep.value;
      final submitting = controller.isSubmitting.value;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (step == 1) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.goToStep(2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.onColoredBackground,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      languageService.tr('tw_continue'),
                      style: TextStyle(color: AppColors.onColoredBackground),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.border),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(languageService.tr('tw_cancel')),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.onColoredBackground,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: submitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onColoredBackground,
                            ),
                          )
                        : Text(
                            languageService.tr('tw_submit_redemption'),
                            style: TextStyle(
                              color: AppColors.onColoredBackground,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
