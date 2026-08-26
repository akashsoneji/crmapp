import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/models/banner_model.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  const BannerCarousel({super.key, required this.banners});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients) {
          final nextPage = (_currentPage + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _stopAutoPlay() {
    _timer?.cancel();
  }

  Future<void> _handleBannerTap(BannerItem banner) async {
    final clickUrl = banner.clickUrl;
    if (clickUrl != null && clickUrl.trim().isNotEmpty) {
      final uri = Uri.parse(clickUrl.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 130.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              final imageUrl = banner.imageUrl ?? '';

              return GestureDetector(
                onTap: () => _handleBannerTap(banner),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.35)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.cardBackGround,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined, color: AppColors.textGrey, size: 36.sp),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.cardBackGround,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator.adaptive(),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) {
              final isSelected = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                height: 6.h,
                width: isSelected ? 16.w : 6.w,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.textGrey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
