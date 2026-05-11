// import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/text_styles.dart';
import 'package:crm_app/controllers/pmam/pmam_controller.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/common_loading_widget.dart';
import 'package:crm_app/screens/home/more/widgets/more_menu_widgets.dart';

class PmamMainScreen extends StatefulWidget {
  const PmamMainScreen({super.key});

  @override
  State<PmamMainScreen> createState() => _PmamMainScreenState();
}

class _PmamMainScreenState extends State<PmamMainScreen> {
  late final PmamController _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PmamController>()) {
      _controller = Get.find<PmamController>();
    } else {
      _controller = Get.put(PmamController());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadManagerStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset('assets/svg/trade/arro_back.svg'),
        ),
        title: Text('PMAM', style: AppTextStyles.heading),
        centerTitle: true,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(
            child: CommonLoadingWidget(size: 40, color: AppColors.primary),
          );
        }

        final status = _controller.managerStatus.value;

        // ── APPROVED MANAGER: jump directly to shell with bottom nav ──
        if (status == 'approved') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.offNamed(AppPages.PMAM_MANAGER_SHELL);
          });
          return Center(
            child: CommonLoadingWidget(size: 40, color: AppColors.primary),
          );
        }

        // ── All other states: show menu ──
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              _buildManagerMenuItems(),
              SizedBox(height: 8.h),
              _buildInvestorMenuItems(),
              SizedBox(height: 10.h),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildManagerMenuItems() {
    final status = _controller.managerStatus.value;

    if (status == 'approved') {
      return Column(
        children: [
          _PortalCard(
            icon: Icons.dashboard_outlined,
            label: 'Manager Dashboard',
            subtitle: 'Plans, investors & stats',
            onTap: () => Get.toNamed(AppPages.PMAM_MANAGER_SHELL),
          ),
          SizedBox(height: 10.h),
          _PortalCard(
            icon: Icons.people_outline,
            label: 'Investor Portal',
            subtitle: 'Browse & invest in managers',
            onTap: () => Get.toNamed(AppPages.PMAM_INVESTOR_PORTAL),
          ),
        ],
      );
    }

    if (status == 'pending') {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFFFCC02), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              color: const Color(0xFFF59E0B),
              size: 22.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manager Application Pending',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Your application is under review by admin.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFA37E3B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'rejected') {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.red.withOpacity(0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.red, size: 22.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Your manager application was rejected. Contact support for more info.',
                style: TextStyle(fontSize: 13.sp, color: AppColors.red),
              ),
            ),
          ],
        ),
      );
    }

    // Not applied
    return MoreMenuCardGroup(
      children: [
        MoreMenuTile(
          iconName: 'dashboard',
          label: 'Become a Manager',
          onTap: () => Get.toNamed(AppPages.PMAM_BECOME_MANAGER),
          textColor: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _buildInvestorMenuItems() {
    return Column(
      children: [
        _PortalCard(
          icon: Icons.candlestick_chart_outlined,
          label: 'Investor Portal',
          subtitle: 'Browse fund managers',
          onTap: () => Get.toNamed(AppPages.PMAM_INVESTOR_PORTAL),
        ),
      ],
    );
  }
}

// ─── Portal Card ─────────────────────────────────────────────────────────────

class _PortalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _PortalCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.icongrey.withValues(alpha: 0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: AppColors.cardBackGround,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: AppColors.cardBackGround,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 18.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _PmamMenuItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String subtitle;
//   final VoidCallback onTap;
//   final bool showBorder;

//   const _PmamMenuItem({
//     required this.icon,
//     required this.label,
//     required this.subtitle,
//     required this.onTap,
//     this.showBorder = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(14.r),
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
//         decoration:
//             showBorder
//                 ? BoxDecoration(
//                   border: Border(
//                     bottom: BorderSide(color: const Color(0xFFEEEEEE)),
//                   ),
//                 )
//                 : null,
//         child: Row(
//           children: [
//             Container(
//               width: 40.w,
//               height: 40.w,
//               decoration: BoxDecoration(
//                 color: AppColors.primary.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10.r),
//               ),
//               child: Icon(icon, color: AppColors.primary, size: 20.sp),
//             ),
//             SizedBox(width: 14.w),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     label,
//                     style: TextStyle(
//                       fontSize: 15.sp,
//                       fontWeight: FontWeight.w600,
//                       textColor: AppColors.textPrimary,
//                     ),
//                   ),
//                   // SizedBox(height: 2.h),
//                   // Text(
//                   //   subtitle,
//                   //   style: TextStyle(
//                   //     fontSize: 12.sp,
//                   //     color: AppColors.textGrey,
//                   //   ),
//                   // ),
//                 ],
//               ),
//             ),
//             Icon(
//               Icons.chevron_right_rounded,
//               color: AppColors.textGrey,
//               size: 22.sp,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
