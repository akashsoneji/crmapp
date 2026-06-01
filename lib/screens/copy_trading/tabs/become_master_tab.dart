import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/auth_controller.dart';
import 'package:crm_app/controllers/copy_trading/copy_trading_hub_controller.dart';
import 'package:crm_app/widgets/labeled_app_text_field.dart';
import 'package:crm_app/widgets/app_select_field.dart';
import 'package:crm_app/widgets/custom_toast.dart';

class BecomeMasterTab extends StatefulWidget {
  const BecomeMasterTab({super.key});

  @override
  State<BecomeMasterTab> createState() => _BecomeMasterTabState();
}

class _BecomeMasterTabState extends State<BecomeMasterTab> {
  final _nicknameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final hub = Get.find<CopyTradingHubController>();
    hub.resetMasterApplyForm();
    _nicknameCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hub.loadEligibleAccountsForMasterApply();
    });
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hub = Get.find<CopyTradingHubController>();
    final auth = Get.find<AuthController>();
    final user = auth.profileData?.data.user;

    final userName = user != null ? '${user.firstName} ${user.lastName}'.trim() : 'demo account';

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Become a Master Trader',
          style: AppTextStyles.screenTitle.copyWith(fontSize: 16.sp),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Obx(() {
          final status = hub.masterStatus.value;
          final code = hub.masterCode.value;
          final eligibleLoading = hub.masterApplyEligibleLoading.value;
          final accounts = hub.masterApplyEligibleAccounts;
          final err = hub.masterApplyEligibleError.value;
          final canSubmit = hub.canSubmitMasterApply;
          final applying = hub.isLoading.value;

          // If pending, show the pending review message
          if (status == CopyTradingMasterApplicationStatus.pending) {
            return _buildPendingReviewView(code);
          }

          final applyBtnFg =
              AppColors.primary.computeLuminance() > 0.5
                  ? AppColors.textPrimaryLight
                  : AppColors.onColoredBackground;
          final isDark = AppColors.isDarkMode;
          final checkBorder = isDark ? AppColors.textPrimaryDark : AppColors.primary;
          final checkFill = isDark ? AppColors.textPrimaryDark : AppColors.primary;
          final checkMark = isDark ? AppColors.textPrimaryLight : AppColors.onColoredBackground;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Complete all steps to become a Copy Trading Master',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),

              // ── Step checklist cards ──
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10.h,
                crossAxisSpacing: 10.w,
                childAspectRatio: 1.5,
                children: [
                  _buildStepCard(
                    title: 'Email Verification',
                    completed: user?.email.isNotEmpty == true,
                    icon: Icons.check_circle,
                  ),
                  _buildStepCard(
                    title: 'Mobile Verification',
                    completed: user?.mobile.isNotEmpty == true,
                    icon: Icons.check_circle,
                  ),
                  _buildStepCard(
                    title: 'Personal Information',
                    completed: user?.firstName.isNotEmpty == true,
                    icon: Icons.check_circle,
                  ),
                  _buildStepCard(
                    title: 'Copy Trading Application',
                    completed: status == CopyTradingMasterApplicationStatus.approved,
                    icon: status == CopyTradingMasterApplicationStatus.none ? Icons.notifications_none : Icons.check_circle,
                    labelOverride: status == CopyTradingMasterApplicationStatus.none ? 'Not Applied' : 'Pending',
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // ── Application Form Section ──
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.textGrey.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Your name
                    Text(
                      'Your name',
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.tradeBackgroundCenterColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.textGrey.withOpacity(0.15)),
                      ),
                      child: Text(
                        userName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Shown for admin reference; update in profile if incorrect.',
                      style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey),
                    ),
                    SizedBox(height: 16.h),

                    // Trading Account select dropdown
                    Text(
                      'Trading account *',
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6.h),
                    if (eligibleLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Center(
                          child: SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                        ),
                      )
                    else if (accounts.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Text(
                          err.isNotEmpty ? err : 'No eligible accounts found.',
                          style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textGrey),
                        ),
                      )
                    else
                      AppSelectField<int>(
                        value: hub.masterApplySelectedAccountId.value,
                        hint: '-- Select account --',
                        sheetTitle: 'Trading account',
                        borderRadius: 10,
                        fontSize: 14.sp,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        options: accounts
                            .map(
                              (a) => AppSelectOption<int>(
                                value: a.id,
                                title: '${a.metaAccountNumber} · ${a.accountType}',
                                subtitle: '\$${a.equity.toStringAsFixed(2)}',
                              ),
                            )
                            .toList(),
                        onChanged: (v) => hub.masterApplySelectedAccountId.value = v,
                      ),
                    SizedBox(height: 16.h),

                    // Public nickname
                    LabeledAppTextField(
                      label: 'Public nickname *',
                      controller: _nicknameCtrl,
                      keyboardType: TextInputType.text,
                      hintText: 'e.g. Alpha Trader',
                      onChanged: (s) => hub.masterApplyNicknameDraft.value = s,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Displayed on the public leaderboard and master profile.',
                      style: TextStyle(fontSize: 10.sp, color: AppColors.textGrey),
                    ),
                    SizedBox(height: 16.h),

                    // Terms check
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24.r,
                          height: 24.r,
                          child: Checkbox(
                            value: hub.masterApplyTermsAccepted.value,
                            side: BorderSide(color: checkBorder, width: 1.5),
                            fillColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return checkFill;
                              }
                              return Colors.transparent;
                            }),
                            checkColor: checkMark,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => hub.masterApplyTermsAccepted.value = v ?? false,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'I accept the Master Trader Terms & Conditions and confirm that I will trade responsibly. Copiers may mirror my trades in real time.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: ElevatedButton(
                        onPressed: canSubmit && !applying
                            ? () async {
                                final id = hub.masterApplySelectedAccountId.value!;
                                final nick = hub.masterApplyNicknameDraft.value.trim();
                                final res = await hub.applyForMaster(
                                  mt5AccountId: id,
                                  nickname: nick,
                                  termsAccepted: hub.masterApplyTermsAccepted.value,
                                );
                                if (res.success) {
                                  CustomToastService.showSuccess(
                                    title: 'Submitted',
                                    message: res.message ?? 'Application submitted',
                                    duration: const Duration(milliseconds: 2500),
                                  );
                                } else {
                                  CustomToastService.showError(
                                    title: 'Failed',
                                    message: res.message ?? hub.errorMessage.value,
                                    duration: const Duration(milliseconds: 2500),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: applyBtnFg,
                          disabledBackgroundColor: AppColors.textGrey.withOpacity(0.2),
                          disabledForegroundColor: applyBtnFg.withOpacity(0.4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: applying
                            ? SizedBox(
                                width: 18.r,
                                height: 18.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: applyBtnFg,
                                ),
                              )
                            : Text(
                                'Submit Application',
                                style: AppTextStyles.button.copyWith(
                                  color: applyBtnFg,
                                  fontSize: 14.sp,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepCard({
    required String title,
    required bool completed,
    required IconData icon,
    String? labelOverride,
  }) {
    final statusColor = completed ? AppColors.green : AppColors.warning;
    final statusText = labelOverride ?? (completed ? 'Completed' : 'Pending');

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                size: 18.r,
                color: statusColor,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviewView(String masterCode) {
    return Container(
      margin: EdgeInsets.only(top: 40.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 48.r, color: AppColors.warning),
          SizedBox(height: 14.h),
          Text(
            'Under Review',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your application is currently being reviewed by our administration team. We will notify you as soon as your status is updated.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textGrey,
              height: 1.4,
            ),
          ),
          if (masterCode.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.tradeBackgroundCenterColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Master Code: $masterCode',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
