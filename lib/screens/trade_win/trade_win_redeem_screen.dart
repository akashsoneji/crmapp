import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/trade_win/trade_win_redeem_controller.dart';
import 'package:crm_app/models/trade_win/trade_win_product_model.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/utils/trade_win_format.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_product_image.dart';
import 'package:crm_app/screens/trade_win/trade_win_theme.dart';
import 'package:crm_app/screens/trade_win/widgets/trade_win_redeem_stepper.dart';

class TradeWinRedeemScreen extends StatelessWidget {
  const TradeWinRedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final product = args?['product'] as TradeWinProductModel?;
    final quantity = args?['quantity'] as int? ?? 1;

    if (product == null) {
      return Scaffold(
        body: Center(child: Text(Get.find<LanguageService>().tr('tw_product_not_found'))),
      );
    }

    final controller = Get.put(
      TradeWinRedeemController(product: product, initialQuantity: quantity),
    );
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: TradeWinRedeemStepper(currentStep: controller.currentStep.value),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                child: controller.currentStep.value == 1
                    ? _StepConfirm(controller: controller, languageService: languageService)
                    : _StepShipping(controller: controller, languageService: languageService),
              ),
            ),
            _BottomActions(controller: controller, languageService: languageService),
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
          style: AppTextStyles.heading.copyWith(color: AppColors.primary),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            TradeWinProductImage(
              imagePath: product.imagePath,
              width: 72.w,
              height: 72.w,
            ),
            SizedBox(width: 12.w),
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
        SizedBox(height: 16.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: AppColors.icongrey.withValues(alpha: 0.12)),
          ),
          child: Obx(() {
            return Column(
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
            );
          }),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(12.r),
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
  final TradeWinRedeemController controller;
  final LanguageService languageService;

  const _StepShipping({
    required this.controller,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageService.tr('tw_step_shipping'),
          style: AppTextStyles.heading.copyWith(color: AppColors.primary),
        ),
        SizedBox(height: 4.h),
        Text(
          languageService.tr('tw_shipping_instruction'),
          style: AppTextStyles.subheading,
        ),
        SizedBox(height: 16.h),
        _Field(label: languageService.tr('tw_full_name'), controller: controller.nameController),
        _Field(label: languageService.tr('tw_phone'), controller: controller.phoneController, keyboard: TextInputType.phone),
        _Field(label: languageService.tr('tw_email'), controller: controller.emailController, keyboard: TextInputType.emailAddress),
        _Field(label: languageService.tr('tw_address'), controller: controller.addressController, maxLines: 3),
        Row(
          children: [
            Expanded(child: _Field(label: languageService.tr('tw_city'), controller: controller.cityController)),
            SizedBox(width: 10.w),
            Expanded(child: _Field(label: languageService.tr('tw_country'), controller: controller.countryController)),
          ],
        ),
        Obx(
          () => CheckboxListTile(
            value: controller.rememberAddress.value,
            onChanged: (v) => controller.rememberAddress.value = v ?? false,
            activeColor: AppColors.primary,
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
      padding: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          SizedBox(height: 6.h),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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

  const _BottomActions({
    required this.controller,
    required this.languageService,
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
                      backgroundColor: TradeWinTheme.accentFill,
                      foregroundColor: TradeWinTheme.onAccentFill,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: AppColors.isDarkMode
                            ? BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      languageService.tr('tw_continue'),
                      style: TextStyle(color: TradeWinTheme.onAccentFill),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(languageService.tr('tw_cancel')),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () {
                            if (!controller.validateShipping()) {
                              CustomToastService.show(
                                message: languageService.tr('tw_fill_all_fields'),
                                type: ToastType.warning,
                              );
                              return;
                            }
                            controller.submitRedemption();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TradeWinTheme.accentFill,
                      foregroundColor: TradeWinTheme.onAccentFill,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: AppColors.isDarkMode
                            ? BorderSide(
                                color: Colors.white.withValues(alpha: 0.2),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: submitting
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: TradeWinTheme.onAccentFill,
                            ),
                          )
                        : Text(
                            languageService.tr('tw_submit_redemption'),
                            style: TextStyle(color: TradeWinTheme.onAccentFill),
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
