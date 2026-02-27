import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/more/more_controller.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/services/language_service.dart';
import 'package:crm_app/controllers/auth_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/services/one_click_trading_service.dart';
import 'package:crm_app/screens/home/more/bonus/scratch_card_screen.dart';
import 'package:crm_app/screens/home/more/one_click_trading_disclaimer_screen.dart';
import 'package:crm_app/controllers/ib_controller.dart';
import 'package:crm_app/widgets/custom_toast.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> with WidgetsBindingObserver {
  final languageService = Get.find<LanguageService>();
  late final MoreController moreController;
  bool _hasLoadedInitialData = false;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    moreController = Get.put(MoreController());
    WidgetsBinding.instance.addObserver(this);
    _hasLoadedInitialData = false;
    moreController.loadMoreScreenData();
    _hasLoadedInitialData = true;
    _lastRefreshTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible after navigation
    // Only refresh if it's been more than 500ms since last refresh to avoid excessive calls
    // Reduced from 1 second to make it more responsive
    if (_hasLoadedInitialData &&
        (_lastRefreshTime == null ||
            DateTime.now().difference(_lastRefreshTime!).inMilliseconds >
                500)) {
      // Add a small delay to ensure screen is fully visible before refreshing
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _refreshDataIfNeeded();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app resumes (user returns to app)
    if (state == AppLifecycleState.resumed) {
      _refreshDataIfNeeded();
    }
  }

  void _refreshDataIfNeeded() {
    if (mounted) {
      _lastRefreshTime = DateTime.now();
      moreController.loadMoreScreenData();
    }
  }

  Future<void> _handleSwitchToIB() async {
    try {
      // Get or create IBController
      IBController ibController;
      if (Get.isRegistered<IBController>()) {
        ibController = Get.find<IBController>();
      } else {
        ibController = Get.put(IBController());
      }

      // Show loading
      Get.dialog(
        Center(
          child: CommonLoadingWidget(
            // message: 'Checking IB status...',
            size: 50.0,
            color: AppColors.primary,
          ),
        ),
        barrierDismissible: false,
      );

      // Call IB Status API
      final ibStatusResponse = await ibController.getIBStatus();

      // Close loading dialog
      Get.back(closeOverlays: true);

      if (ibStatusResponse != null && ibStatusResponse.status == true) {
        final ibStatus = ibStatusResponse.data?.ibStatus;
        final isApproved = ibStatusResponse.data?.isApproved ?? false;
        final profileCompletion = ibStatusResponse.data?.profileCompletion ?? 0;

        // If IB status is rejected, show toast message
        if (ibStatus == 'rejected') {
          CustomToastService.showError(
            message:
                'Your IB application has been rejected. Please contact support for more information.',
          );
          return;
        }
        // If IB status is rejected, show toast message
        if (ibStatus == 'not_applied') {
          Get.toNamed(AppPages.PARTNERSHIP_PROGRAM);
        }
        // If IB is approved, navigate to IB Main
        else if (ibStatus == 'approved' && isApproved == true) {
          Navigator.of(context).pushReplacementNamed('/ib-main');
        }
        // If profile is 100% complete but IB not approved, go to Partnership Program
        else if (profileCompletion == 100) {
          Get.toNamed(AppPages.PARTNERSHIP_PROGRAM);
        }
        // If profile is not complete, show error message
        else {
          CustomToastService.showError(
            duration: Duration(seconds: 2),
            message:
                ibStatusResponse.message ??
                'Profile is not complete. Please complete your profile first.',
          );
        }
      } else {
        // Handle error response (status: false)
        String errorMsg;
        if (ibStatusResponse?.message != null) {
          errorMsg = ibStatusResponse!.message!;
        } else if (ibController.errorMessage.value.isNotEmpty) {
          errorMsg = ibController.errorMessage.value;
        } else {
          errorMsg = 'Failed to check IB status. Please try again.';
        }
        CustomToastService.showError(message: errorMsg);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back(closeOverlays: true);
      }
      CustomToastService.showError(message: 'Error checking IB status: $e');
    }
  }

  int _calculateCompletion(StageCompletion? stage) {
    print('_calculateCompletion - stage: $stage');
    if (stage == null) {
      print('_calculateCompletion - stage is null, returning 0');
      return 0;
    }

    print('_calculateCompletion - mobileVerified: ${stage.mobileVerified}');
    print('_calculateCompletion - emailVerified: ${stage.emailVerified}');
    print('_calculateCompletion - personalDetails: ${stage.personalDetails}');
    print('_calculateCompletion - identityVerified: ${stage.identityVerified}');
    print(
      '_calculateCompletion - addressProofVerified: ${stage.addressProofVerified}',
    );

    int completion = 0;

    // Step 1: Check mobile verification - if mobileVerified is not null (has valid DateTime)
    if (stage.mobileVerified != null) {
      completion += 20;
      print('Step 1 - Mobile Verified: +20% = $completion%');
    } else {
      print('Step 1 - Mobile Not Verified: 0%');
    }

    // Step 2: Check email verification - if emailVerified is not null (has valid DateTime)
    if (stage.emailVerified != null) {
      completion += 20;
      print('Step 2 - Email Verified: +20% = $completion%');
    } else {
      print('Step 2 - Email Not Verified: $completion%');
    }

    // Step 3: Check personal details - if personalDetails is true
    if (stage.personalDetails == true) {
      completion += 20;
      print('Step 3 - Personal Details: +20% = $completion%');
    } else {
      print('Step 3 - Personal Details Not Complete: $completion%');
    }

    // Step 4: Check identity verification - if identityVerified is true
    if (stage.identityVerified == true) {
      completion += 20;
      print('Step 4 - Identity Verified: +20% = $completion%');
    } else {
      print('Step 4 - Identity Not Verified: $completion%');
    }

    // Step 5: Check address proof verification - if addressProofVerified is true
    if (stage.addressProofVerified == true) {
      completion += 20;
      print('Step 5 - Address Proof Verified: +20% = $completion%');
    } else {
      print('Step 5 - Address Proof Not Verified: $completion%');
    }

    print('FINAL COMPLETION: $completion%');
    return completion;
  }

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final languageService = Get.find<LanguageService>();

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        title: Text(
          languageService.tr('setting_title'),
          style: AppTextStyles.screenTitle,
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            // Access stage data reactively inside Obx
            final model = moreController.dashboardModel.value;
            final stage = model?.data?.stageCompletion;
            // Check if KYC verification is completed (all required fields verified)
            final isProfileVerified =
                (stage?.emailVerified != null) &&
                (stage?.mobileVerified != null) &&
                (stage?.personalDetails == true);

            return IconButton(
              icon: SvgPicture.asset(
                'assets/svg/edit_profile.svg',
                height: 24.h,
                width: 24.w,
                color: AppColors.primary,
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              onPressed: () {
                // Pass the current verification status
                Get.toNamed(
                  AppPages.EDIT_PROFILE,
                  arguments: isProfileVerified,
                );
              },
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 22.w,
            right: 22.w,
            top: 8.h,
            bottom: 8.h + 77.h + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Container(
                padding: EdgeInsets.all(1.w),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32.r,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40.r,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${authController.userFullName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                  fontSize: 18.sp,
                                ),
                              ),
                              SizedBox(width: 6.w),

                              GetBuilder<MoreController>(
                                builder: (controller) {
                                  final model = controller.dashboardModel.value;
                                  final stage = model?.data?.stageCompletion;
                                  final completion = _calculateCompletion(
                                    stage,
                                  );

                                  // // Check if KYC verification is completed (all required fields verified)
                                  // final isProfileVerified =
                                  //     (stage?.emailVerified != null) &&
                                  //     (stage?.mobileVerified != null) &&
                                  //     (stage?.personalDetails == true);
                                  return Icon(
                                    Icons.verified,
                                    color:
                                        (completion == 100)
                                            ? AppColors.primary
                                            : AppColors.grey,
                                    size: 20.r,
                                  );
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${authController.userEmail}',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),

              GetBuilder<MoreController>(
                builder: (controller) {
                  final model = controller.dashboardModel.value;
                  final stage = model?.data?.stageCompletion;
                  final completion = _calculateCompletion(stage);
                  return completion == 100
                      ? SizedBox.shrink()
                      : VerifyAccountCard(
                        title: languageService.tr('verify_your_account'),
                        subTitle: languageService.tr(
                          'complete_verification_to_unlock',
                        ),
                        percentage: '',
                      );
                },
              ),

              SizedBox(height: 22.h),
              _MenuItem(
                icon: 'dollar-circle',
                label: languageService.tr('general_finance'),
                onTap: () async {
                  // Navigate to Finance and refresh when returning
                  await Get.toNamed(AppPages.FINANCE);
                  // Refresh data when returning from Finance screen
                  if (mounted) {
                    _refreshDataIfNeeded();
                  }
                },
                showTopBorder: true,
                color: AppColors.textPrimary,
              ),

              _MenuItem(
                icon: 'change_password',
                label: languageService.tr('change_password'),
                onTap: () {
                  Get.toNamed(AppPages.CHANGE_PASSWORD);
                },
                showTopBorder: false,
                color: AppColors.textPrimary,
              ),
              _MenuItem(
                icon: 'personal_info',
                label: languageService.tr('delete_account'),
                onTap: () {
                  _showDeleteAccountDialog(authController);
                },
                showTopBorder: false,
                color: AppColors.textPrimary,
              ),
              // COMMENTED HERE FOR HIDING EXTRA MENU ITEMS
              _MenuItemWithButton(
                icon: 'dashboard',
                label: languageService.tr('more_dashboard'),
                buttonText: languageService.tr('switch_to_ib'),
                onTap: () {
                  // Get.toNamed(AppPages.IB_DASHBOARD);
                },
                onButtonTap: () async {
                  // Call IB Status API when Switch to IB button is tapped
                  await _handleSwitchToIB();
                },
                showTopBorder: true,
                color: AppColors.textPrimary,
              ),
              // _MenuItem(
              //   icon: 'copy-trading',
              //   label: languageService.tr('more_copy_trading'),
              //   onTap: () {
              //     Get.toNamed(AppPages.COPY_TRADING);
              //   },
              //   color: AppColors.textPrimary,
              // ),
              // _MenuItem(
              //   icon: 'bonus',
              //   label: languageService.tr('more_bonus'),
              //   onTap: () {
              //     Get.toNamed(AppPages.BONUS);
              //   },
              //   color: AppColors.textPrimary,
              // ),
              // _MenuItem(
              //   icon: 'demo-account',
              //   label: languageService.tr('more_demo_contest'),
              //   onTap: () {
              //     Get.toNamed(AppPages.DEMO_CONTEST);
              //   },
              //   color: AppColors.textPrimary,
              // ),
              //
              // _MenuItem(
              //   icon: 'tools',
              //   label: languageService.tr('more_tool_education'),
              //   onTap: () {
              //     Get.toNamed(AppPages.TOOLS_EDUCATION);
              //   },
              //   color: AppColors.textPrimary,
              // ),
              // _MenuItem(
              //   icon: 'support',
              //   label: languageService.tr('more_support'),
              //   onTap: () {
              //     Get.toNamed(AppPages.SUPPORT);
              //   },
              //   color: AppColors.textPrimary,
              // ),
              //
              // _MenuItem(
              //   icon: 'settings',
              //   label: languageService.tr('more_settings'),
              //   onTap: () {
              //     Get.toNamed(AppPages.SETTING);
              //   },
              //   color: AppColors.textPrimary,
              // ),
              // One Click Trading Option
              _OneClickTradingMenuItem(),
              // _MenuItem(
              //   icon: 'scratch-card',
              //   label: languageService.tr('more_scratch_card'),
              //   onTap: () {
              //     Get.to(
              //       () => const ScratchCardListScreen(),
              //       transition: Transition.rightToLeft,
              //       duration: const Duration(milliseconds: 300),
              //     );
              //   },
              //   color: AppColors.textPrimary,
              // ),
              _MenuItem(
                icon: 'logout',
                label: languageService.tr('more_logout'),
                onTap: () {
                  _showLogoutDialog(authController);
                },
                showBottomBorder: false,
                color: AppColors.red,
              ),
              SizedBox(height: 40.h),
              // App Version Display
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox.shrink();
                  }
                  // Extract only major.minor version (remove patch version)
                  final fullVersion = snapshot.data!.version;
                  final versionParts = fullVersion.split('.');
                  final majorMinorVersion =
                      versionParts.length >= 2
                          ? '${versionParts[0]}.${versionParts[1]}'
                          : fullVersion;

                  return Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                    child: Center(
                      child: Text(
                        '${languageService.tr('version_label')} $majorMinorVersion',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(AuthController authController) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App logo - replace asset path with your app logo svg or image
              SvgPicture.asset(
                FlavorConfig.svgLogoAsset,
                height: 60.h,
                width: 60.w,
                color: FlavorConfig.isONSA() ? AppColors.primary : null,
              ),
              SizedBox(height: 24.h),
              Text(
                languageService.tr('logout_confirm_message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap:
                            authController.isLoading
                                ? null
                                : () {
                                  authController.logout();
                                },
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            languageService.tr('navigation_yes'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Get.back(closeOverlays: true);
                      },
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          languageService.tr('navigation_no'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(AuthController authController) {
    final TextEditingController _passwordController = TextEditingController();
    final RxBool _isPasswordEmpty = false.obs;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App logo - replace asset path with your app logo svg or image
              SvgPicture.asset(
                FlavorConfig.svgLogoAsset,
                height: 80.h,
                width: 80.w,
                color: FlavorConfig.isONSA() ? AppColors.primary : null,
              ),
              SizedBox(height: 24.h),
              Text(
                languageService.tr('delete_account_confirm_message'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Obx(
                  () => TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: languageService.tr(
                        'delete_account_password_hint',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              _isPasswordEmpty.value ? Colors.red : Colors.grey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              _isPasswordEmpty.value ? Colors.red : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              _isPasswordEmpty.value
                                  ? Colors.red
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Obx(
                      () => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap:
                            authController.isLoading
                                ? null
                                : () {
                                  if (_passwordController.text.isEmpty) {
                                    _isPasswordEmpty.value = true;
                                  } else {
                                    _isPasswordEmpty.value = false;
                                    authController.deleteAccount({
                                      "password": _passwordController.text,
                                      "reason": languageService.tr(
                                        'delete_account_reason_no_longer_needed',
                                      ),
                                      "accept_terms": true,
                                      "confirm_deletion": true,
                                    });
                                  }
                                },
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            languageService.tr('navigation_yes'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Get.back(closeOverlays: true);
                      },
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          languageService.tr('navigation_no'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemWithButton extends StatelessWidget {
  final String icon;
  final String label;
  final String buttonText;
  final VoidCallback onTap;
  final VoidCallback onButtonTap;
  final bool showTopBorder;
  final Color color;

  const _MenuItemWithButton({
    required this.icon,
    required this.label,
    required this.buttonText,
    required this.onTap,
    required this.onButtonTap,
    required this.color,
    this.showTopBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top:
                showTopBorder
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: SizedBox(
          height: 56.h,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h),
              child: Row(
                children: [
                  // Icon
                  SvgPicture.asset(
                    'assets/svg/more/$icon.svg',
                    height: 24.h,
                    width: 24.w,
                    color: AppColors.primary,
                  ),

                  SizedBox(width: 16.w),

                  // Label
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Roboto',
                        color: color,
                      ),
                    ),
                  ),

                  // Switch Button
                  ElevatedButton(
                    onPressed: onButtonTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      elevation: 0,
                      minimumSize: Size(0, 0),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool showTopBorder;
  final bool showBottomBorder;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.showTopBorder = false,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top:
                showTopBorder
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
            bottom:
                showBottomBorder
                    ? BorderSide(color: Colors.grey.shade300, width: 1)
                    : BorderSide.none,
          ),
        ),
        child: SizedBox(
          height: 56.h,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            leading: SvgPicture.asset(
              'assets/svg/more/$icon.svg',
              height: 24.h,
              width: 24.w,
              color: showBottomBorder ? AppColors.primary : color,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
                color: color,
              ),
            ),
            trailing:
                showBottomBorder
                    ? Icon(
                      Icons.arrow_forward_ios_sharp,
                      size: 14.h,
                      color: AppColors.icongrey,
                    )
                    : null,
            onTap: onTap,
            minLeadingWidth: 10,
            horizontalTitleGap: 8.w,
          ),
        ),
      ),
    );
  }
}

class _OneClickTradingMenuItem extends StatefulWidget {
  const _OneClickTradingMenuItem();

  @override
  State<_OneClickTradingMenuItem> createState() =>
      _OneClickTradingMenuItemState();
}

class _OneClickTradingMenuItemState extends State<_OneClickTradingMenuItem> {
  final OneClickTradingService _oneClickService =
      OneClickTradingService.instance;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await _oneClickService.isOneClickTradingEnabled();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: SizedBox(
          height: 56.h,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: 0,
            leading: Icon(
              Icons.touch_app,
              size: 24.h,
              color: AppColors.primary,
            ),
            title: Text(
              'One Click Trading',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
                color: AppColors.textPrimary,
              ),
            ),
            trailing: GestureDetector(
              onTap: () async {
                if (!_isEnabled) {
                  // Navigate to disclaimer screen
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const OneClickTradingDisclaimerScreen(),
                    ),
                  );
                  // Reload state after returning from disclaimer
                  await _loadState();
                } else {
                  // Disable directly
                  await _oneClickService.setOneClickTradingEnabled(false);
                  setState(() {
                    _isEnabled = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48.w,
                height: 26.h,
                decoration: BoxDecoration(
                  color:
                      _isEnabled
                          ? AppColors.primary
                          : AppColors.border.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(18.r),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment:
                      _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  curve: Curves.easeOut,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: 20.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            minLeadingWidth: 10,
            horizontalTitleGap: 8.w,
          ),
        ),
      ),
    );
  }
}

class VerifyAccountCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String percentage;

  VerifyAccountCard({
    super.key,
    required this.title,
    required this.subTitle,
    required this.percentage,
  });

  final languageService = Get.find<LanguageService>();
  final MoreController moreController = Get.find<MoreController>();

  int _calculateCompletion(StageCompletion? stage) {
    print('_calculateCompletion - stage: $stage');
    if (stage == null) {
      print('_calculateCompletion - stage is null, returning 0');
      return 0;
    }

    print('_calculateCompletion - mobileVerified: ${stage.mobileVerified}');
    print('_calculateCompletion - emailVerified: ${stage.emailVerified}');
    print('_calculateCompletion - personalDetails: ${stage.personalDetails}');
    print('_calculateCompletion - identityVerified: ${stage.identityVerified}');
    print(
      '_calculateCompletion - addressProofVerified: ${stage.addressProofVerified}',
    );

    int completion = 0;

    // Step 1: Check mobile verification - if mobileVerified is not null (has valid DateTime)
    if (stage.mobileVerified != null) {
      completion += 20;
      print('Step 1 - Mobile Verified: +20% = $completion%');
    } else {
      print('Step 1 - Mobile Not Verified: 0%');
    }

    // Step 2: Check email verification - if emailVerified is not null (has valid DateTime)
    if (stage.emailVerified != null) {
      completion += 20;
      print('Step 2 - Email Verified: +20% = $completion%');
    } else {
      print('Step 2 - Email Not Verified: $completion%');
    }

    // Step 3: Check personal details - if personalDetails is true
    if (stage.personalDetails == true) {
      completion += 20;
      print('Step 3 - Personal Details: +20% = $completion%');
    } else {
      print('Step 3 - Personal Details Not Complete: $completion%');
    }

    // Step 4: Check identity verification - if identityVerified is true
    if (stage.identityVerified == true) {
      completion += 20;
      print('Step 4 - Identity Verified: +20% = $completion%');
    } else {
      print('Step 4 - Identity Not Verified: $completion%');
    }

    // Step 5: Check address proof verification - if addressProofVerified is true
    if (stage.addressProofVerified == true) {
      completion += 20;
      print('Step 5 - Address Proof Verified: +20% = $completion%');
    } else {
      print('Step 5 - Address Proof Not Verified: $completion%');
    }

    print('FINAL COMPLETION: $completion%');
    return completion;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MoreController>(
      builder: (controller) {
        final model = controller.dashboardModel.value;
        final stage = model?.data?.stageCompletion;
        final completion = _calculateCompletion(stage);

        print('COMPLETION----- $completion');
        print('Model data: ${model?.data}');
        print('Stage completion: $stage');
        return Card(
          elevation: 0,
          color: AppColors.primary.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () async {
              final model = controller.dashboardModel.value;
              final stage = model?.data?.stageCompletion;
              // Navigate to KYC intro and refresh data when returning
              await Get.toNamed(AppPages.KYC_INTRO, arguments: stage);
              // Refresh data when returning from KYC screens
              controller.loadMoreScreenData();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with title + arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(title, style: AppTextStyles.heading),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.black87),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(subTitle, style: AppTextStyles.labelOnChartPendingOrder),

                  const SizedBox(height: 16),

                  // Progress row with percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$completion% ${languageService.tr('completed')}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          minHeight: 3,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
