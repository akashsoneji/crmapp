import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/tenax_broker_selection_controller.dart';
import 'package:crm_app/models/tenax_broker_model.dart';
import 'package:crm_app/routes/app_pages.dart';

class TenaxBrokerSelectionScreen
    extends GetView<TenaxBrokerSelectionController> {
  const TenaxBrokerSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final allowBack = args?['allowBack'] == true;

    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F6),
        appBar: AppBar(
          automaticallyImplyLeading: allowBack,
          leading:
              allowBack
                  ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Get.back(),
                  )
                  : null,
          elevation: 0,
          centerTitle: true,
          backgroundColor: const Color(0xFFF4F4F6),
          title: Text(
            'Broker',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Obx(() {
          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Find broker...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 14.h,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textGrey,
                          size: 22.w,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: const Color(0xFFD5D7DE),
                            width: 1.w,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: AppColors.textGrey.withValues(alpha: 0.6),
                            width: 1.1.w,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: controller.fetchBrokers,
                      child: ListView(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          ...controller.brokers.map(_buildBrokerTile),
                          SizedBox(height: 24.h),
                          _buildStaticInfo(),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (controller.isLoading.value)
                const Center(child: CircularProgressIndicator()),
              if (!controller.isLoading.value &&
                  controller.errorMessage.isNotEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBrokerTile(TenaxBrokerModel broker) {
    return InkWell(
      onTap: () async {
        try {
          await controller.selectBroker(broker);
          final routeArgs = Get.arguments as Map<String, dynamic>?;
          final nextRoute = (routeArgs?['nextRoute'] ?? '').toString();
          if (nextRoute.isNotEmpty) {
            Get.offAllNamed(nextRoute);
          } else {
            Get.offAllNamed(AppPages.SPLASH);
          }
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
            bottom: BorderSide(color: const Color(0xFFD6D8DE), width: 1.w),
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
                      color: const Color(0xFF21242C),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    broker.subTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF767B88),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.info_outline,
              size: 22.w,
              color: const Color(0xFF5E616C),
            ),
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
        errorBuilder:
            (context, error, stackTrace) => Container(
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
    return Column(
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 56.w,
          color: const Color(0xFF7B808C),
        ),
        SizedBox(height: 12.h),
        Text(
          'Use search to find a company',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF2B2D33),
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'The application may feature brokerage companies which may not be regulated in your country. Exercise caution and responsibility before opening an account with any brokerage company.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747884),
            fontSize: 18.sp,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'Contact details are provided for each company. Use them to further research their regulatory status and services.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF747884),
            fontSize: 18.sp,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
