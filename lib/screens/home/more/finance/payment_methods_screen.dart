import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/controllers/finance/payment_method_controller.dart';
import 'package:pipze/screens/home/more/finance/deposit_real_screen.dart';
import 'package:pipze/widgets/custom_toast.dart';

import '../../../../constants/color.dart';
import '../../../../constants/text_styles.dart';
import '../../../../services/api_service.dart';
import '../../../../services/language_service.dart';
import '../../../../widgets/common_loading_widget.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String accountNumber;

  const PaymentMethodsScreen({super.key, required this.accountNumber});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentMethodController controller = Get.put(PaymentMethodController());
  final ApiService apiService = Get.put(ApiService());

  late final LanguageService languageService;

  @override
  void initState() {
    super.initState();
    languageService = Get.find<LanguageService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: IconButton(
            icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
            onPressed: () => Get.back(),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Payment Methods', style: AppTextStyles.screenTitle),
            SizedBox(height: 2.h),
            Text(
              'MT5 ${widget.accountNumber}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        shape: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return Center(child: OverlayLoadingWidget());
        } else if (controller.kycDeposits.isEmpty) {
          return Center(child: Text("Data not available"));
        } else {
          return ListView.builder(
            itemCount: controller.kycDeposits.length,
            itemBuilder: (context, index) {
              final method = controller.kycDeposits[index];
              final name = method['display_name'] ?? '';

              return InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  if (method['status'] == 'active') {
                    controller.setSelectedKYCDeposit(method);
                    // Navigate to your next screen

                    Get.to(
                      () => DepositRealScreen(object: method),
                    ); // replace NextScreen with actual screen
                  } else {
                    CustomToastService.showError(
                      message: 'Complete KYC Verification first',
                    );
                  }
                },
                child:
                    (controller.kycDeposits[index]['iconBytes'] != null)
                        ? ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child:
                                controller.kycDeposits[index]['iconBytes'] !=
                                        null
                                    ? Image.memory(
                                      controller
                                          .kycDeposits[index]['iconBytes'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                    : CircleAvatar(
                                      child: Text(
                                        name.isNotEmpty ? name[0] : "?",
                                      ),
                                    ),
                          ),
                          title: Text(name),
                          // subtitle: Text("Instant up to 1 hour"),
                          trailing: Icon(Icons.arrow_forward_ios_rounded),
                        )
                        : Center(child: OverlayLoadingWidget()),
              );
            },
          );
        }
      }),
    );
  }
}
