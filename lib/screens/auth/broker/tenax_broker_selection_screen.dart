import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/tenax_broker_selection_controller.dart';
import 'package:crm_app/models/tenax_broker_model.dart';
import 'package:crm_app/services/language_service.dart';

class TenaxBrokerSelectionScreen
    extends GetView<TenaxBrokerSelectionController> {
  const TenaxBrokerSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Get.find<LanguageService>();
    final args = Get.arguments as Map<String, dynamic>?;
    final allowBack = args?['allowBack'] == true;

    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          automaticallyImplyLeading: allowBack,
          leading: allowBack
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Get.back(),
                )
              : null,
          elevation: 0,
          centerTitle: false,
          backgroundColor: AppColors.surface,
          title: Text(
            controller.isDemoMode ? 'Select Demo' : 'Broker',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Obx(() {
          return Stack(
            children: [
              Column(
                children: [
                  if (!controller.isDemoMode)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Container(
                        height: 46.h,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 14.w),
                            SvgPicture.asset(
                              'assets/svg/broker_search.svg',
                              width: 20.w,
                              height: 20.w,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF9CA3AF),
                                BlendMode.srcIn,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: controller.searchController,
                                onChanged: controller.onSearchChanged,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: languageService.tr(
                                    'auth_find_broker',
                                  ),
                                  hintStyle: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 14.sp,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            SizedBox(width: 14.w),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: controller.isDemoMode ? 4.h : 10.h),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetchBrokers,
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          ...controller.brokers.map(_buildBrokerTile),
                          if (controller.brokers.isEmpty) ...[
                            SizedBox(height: 24.h),
                            if (!controller.isDemoMode) _buildStaticInfo(),
                          ],
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (controller.isLoading.value)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        }),
        bottomNavigationBar: controller.isDemoMode
            ? null
            : SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
                  child: SizedBox(
                    height: 50.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.isDarkMode
                            ? Color(0xFFFFFFFF)
                            : Color(0xFF4A0C54),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                languageService.tr('auth_contact_support'),
                              ),
                              content: Text(
                                languageService.tr(
                                  'auth_contact_support_message',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(languageService.tr('common_ok')),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          languageService.tr('auth_cannot_find_broker'),
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBrokerTile(TenaxBrokerModel broker) {
    return InkWell(
      onTap: () async {
        try {
          await controller.selectBroker(broker);
        } catch (e) {
          Get.snackbar(
            'Error',
            'Unable to save selected broker. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1.w),
          ),
        ),
        child: Row(
          children: [
            _buildLogo(broker.logoUrl),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    broker.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (broker.companyName.trim().isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      broker.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Obx(() {
              final isThisLoading =
                  controller.loadingInfoSlug.value == broker.slug;
              return GestureDetector(
                onTap: controller.loadingInfoSlug.value.isNotEmpty
                    ? null
                    : () => controller.fetchBrokerInfo(broker),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: isThisLoading
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF6B3FA0),
                          ),
                        )
                      : Icon(
                          Icons.info_outline,
                          size: 22.w,
                          color: AppColors.textGrey,
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(String logoUrl) {
    final hasLogo =
        logoUrl.trim().startsWith('http://') ||
        logoUrl.trim().startsWith('https://');
    if (!hasLogo) {
      return Container(
        width: 46.w,
        height: 46.w,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE3E5EA),
        ),
        child: const Icon(Icons.business, color: Color(0xFF6F7380)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(23.r),
      child: Image.network(
        logoUrl.trim(),
        width: 46.w,
        height: 46.w,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 46.w,
          height: 46.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE3E5EA),
          ),
          child: const Icon(Icons.business, color: Color(0xFF6F7380)),
        ),
      ),
    );
  }

  Widget _buildStaticInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Column(
        children: [
          SizedBox(height: 24.h),
          SvgPicture.asset(
            'assets/svg/broker_search.svg',
            width: 80.w,
            height: 64.w,
            colorFilter: const ColorFilter.mode(
              Color(0xFF9CA3AF),
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Use search to find a company',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'The application may feature brokerage companies which may not be regulated in your country. Exercise caution and responsibility before opening an account with any brokerage company.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13.sp,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            "Contact details are provided for each company. Use them to further research their regulatory status and services. Tenax code may not possess complete and updated information about the regulation status of brokerage companies in particular countries and does not guarantee their reliability or reputation.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textGrey,
              fontSize: 13.sp,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
