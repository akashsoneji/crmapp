import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/controllers/instruments_controller.dart';

class InstrumentsScreen extends StatelessWidget {
  final VoidCallback? onNavigateToChart;

  const InstrumentsScreen({super.key, this.onNavigateToChart});

  @override
  Widget build(BuildContext context) {
    final InstrumentsController controller = Get.find<InstrumentsController>();
    final languageService = Get.find<LanguageService>();

    return Obx(() {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: Text(languageService.tr('instruments_title')),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.all(16.w),
              child: TextField(
                onChanged: controller.updateSearchQuery,
                decoration: InputDecoration(
                  hintText: languageService.tr('search_instruments'),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // Instruments list
            Expanded(
              child: Obx(() {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(controller.errorMessage),
                        ElevatedButton(
                          onPressed: controller.refreshInstruments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final instruments = controller.filteredInstruments;

                if (instruments.isEmpty) {
                  return Center(
                    child: Text(languageService.tr('no_instruments_found')),
                  );
                }

                return RefreshIndicator(
                  onRefresh: controller.refreshInstruments,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: instruments.length,
                    itemBuilder: (context, index) {
                      final instrument = instruments[index];
                      return _buildInstrumentCard(instrument, controller);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInstrumentCard(
    Map<String, dynamic> instrument,
    InstrumentsController controller,
  ) {
    final change = instrument['change'] as double? ?? 0.0;
    final changePercent = instrument['changePercent'] as double? ?? 0.0;
    final isPositive = change >= 0;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        title: Text(
          instrument['name'] ?? '',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
        ),
        subtitle: Text(
          instrument['symbol'] ?? '',
          style: TextStyle(color: AppColors.textGrey, fontSize: 14.sp),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${instrument['price']}',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
            ),
            Text(
              '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onTap: () {
          controller.selectInstrument(instrument);

          // Show instrument details or navigate to chart
          Get.snackbar(
            'Instrument Selected',
            'Selected ${instrument['name']}',
            snackPosition: SnackPosition.BOTTOM,
          );

          // Navigate to chart if callback is provided
          onNavigateToChart?.call();
        },
      ),
    );
  }
}
