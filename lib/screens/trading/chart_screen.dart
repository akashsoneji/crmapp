import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/controllers/instruments_controller.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final InstrumentsController controller = Get.find<InstrumentsController>();
    final languageService = Get.find<LanguageService>();

    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(languageService.tr('chart_title')),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Obx(() {
          final selectedInstrument = controller.selectedInstrument;

          return Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instrument info
                if (selectedInstrument != null) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedInstrument['name'] ?? 'No Instrument',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                selectedInstrument['symbol'] ?? '',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${selectedInstrument['price']}',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(selectedInstrument['change'] as double? ?? 0.0) >= 0 ? '+' : ''}${(selectedInstrument['changePercent'] as double? ?? 0.0).toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color:
                                      (selectedInstrument['change']
                                                      as double? ??
                                                  0.0) >=
                                              0
                                          ? Colors.green
                                          : Colors.red,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Chart placeholder
                Expanded(
                  child: Card(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 64.h,
                            color: AppColors.textGrey,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            selectedInstrument != null
                                ? 'Chart for ${selectedInstrument['name']}'
                                : languageService.tr('chart_placeholder'),
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            languageService.tr('chart_coming_soon'),
                            style: AppTextStyles.subheading.copyWith(
                              color: AppColors.textGrey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Chart controls
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeframeButton('1M'),
                    _buildTimeframeButton('5M'),
                    _buildTimeframeButton('15M'),
                    _buildTimeframeButton('1H'),
                    _buildTimeframeButton('1D'),
                  ],
                ),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildTimeframeButton(String timeframe) {
    return ElevatedButton(
      onPressed: () {
        Get.snackbar(
          'Timeframe',
          'Selected $timeframe timeframe',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
      child: Text(
        timeframe,
        style: TextStyle(fontSize: 12.sp, color: Colors.white),
      ),
    );
  }
}
