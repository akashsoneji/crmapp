import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/constants/text_styles.dart';
import 'package:pipze/controllers/auth_controller.dart';
import 'package:pipze/services/language_service.dart';
import 'package:pipze/widgets/dashBorder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../flavor_config.dart';
import '../../home/more/finance/payment_methods_screen.dart';

class AccountCreatedScreen extends StatelessWidget {
  AccountCreatedScreen({super.key});
  final AuthController authController = Get.find<AuthController>();
  final LanguageService languageService = Get.find<LanguageService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 40.h),
                    _buildSuccessIcon(),
                    SizedBox(height: 24.h),
                    _buildWelcomeMessage(),
                    // SizedBox(height: 32.h),
                    // _buildAccountDetails(),
                    SizedBox(height: 32.h),
                    _buildCallToAction(context),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    ;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          // Back button container
          Container(height: 40.h, width: 40.w),

          SizedBox(width: 16.w),

          // Progress bar row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _progressBar(active: true),
                SizedBox(width: 8.w),
                _progressBar(active: true),
                SizedBox(width: 8.w),
                _progressBar(active: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar({bool active = false}) {
    return Container(
      width: 60.w,
      height: 4.h,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        // borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return FutureBuilder<Widget>(
      future: SvgColorHelper.loadSvgWithTwoColors(
        assetPath: 'assets/svg/welcom_withstr_icon.svg',
        targetColor1: AppColors.primary,
        targetColor2: Colors.black,
        colorToReplace1: '#5F259E',
        colorToReplace2: '#3D126C',

        height: 130.h,
        width: 130.w,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        return SizedBox(height: 130.h, width: 130.w);
      },
    );

    // return Center(
    //   child: SvgPicture.asset(
    //     'assets/svg/welcom_withstr_icon.svg',
    //     height: 130.h,
    //     width: 130.w,
    //     semanticsLabel: 'Pipze Logo',
    //     // color: AppColors.primary,
    //   ),
    // );
  }

  Widget _buildWelcomeMessage() {
    final bool isONSA = FlavorConfig.isONSA();
    final bool isTENAX = FlavorConfig.isTenax();
    var welcomeString = '';

    if (isONSA) {
      welcomeString = languageService.tr("onboarding_welcome_onsa");
    } else if (isTENAX) {
      welcomeString = languageService.tr("onboarding_welcome_tenax");
    } else {
      welcomeString = languageService.tr("onboarding_welcome");
    }
    return Column(
      children: [
        Text(
          // "${languageService.tr("onboarding_welcome")} ${FlavorConfig.appNameDisplay}",
          "Welcome to ${FlavorConfig.appNameDisplay}",
          style: AppTextStyles.heading.copyWith(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12.h),
        Text(
          languageService.tr("onboarding_slide3_subtitle"),

          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textGrey,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        // SizedBox(height: 8.h),
        // Text(
        //   languageService.tr("onboarding_slide3_subtitle2"),

        //   style: TextStyle(
        //     fontSize: 16.sp,
        //     color: AppColors.textGrey,
        //     height: 1.4,
        //   ),
        //   textAlign: TextAlign.center,
        // ),
      ],
    );
  }

  Widget _buildAccountDetails() {
    final bool isONSA = FlavorConfig.isONSA();

    return Container(
      // padding: EdgeInsets.all(20.w),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(16),
      //   border: Border.all(color: AppColors.border),
      // ),
      child: Column(
        children: [
          _buildDetailRow(
            languageService.tr("common_type"),
            languageService.tr("common_real"),
          ),
          _buildDivider(),
          _buildDetailRow(languageService.tr("common_number"), "12384965"),
          _buildDivider(),
          isONSA
              ? _buildDetailRow(
                languageService.tr("common_platform"),
                languageService.tr("onsa_trader"),
              )
              : _buildDetailRow(
                languageService.tr("common_platform"),
                languageService.tr("Pipze Trader"),
              ),
          _buildDivider(),
          _buildDetailRow(
            languageService.tr("common_currency"),
            languageService.tr("common_currency_usd"),
          ),
          _buildDivider(),
          _buildDetailRow(languageService.tr("common_leverage"), "1:5000"),
          _buildDivider(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 0, right: 0),
      child: DashedUnderline(color: AppColors.textGreyLight.withAlpha(100)),
    );
  }

  Widget _buildCallToAction(BuildContext context) {
    return Column(
      children: [
        Text(
          languageService.tr("common_to_start_trading"),
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          height: 46.h,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to trading screen first (clearing the stack)
              // This removes Account Created Screen from navigation stack
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/trading',
                (route) => false,
              );
              // Navigate to PaymentMethodsScreen after a short delay
              // to ensure Trading screen is fully loaded
              Future.delayed(Duration(milliseconds: 300), () {
                Get.to(() => PaymentMethodsScreen(accountNumber: ''));
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              // padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              languageService.tr("common_deposit"),
              style: AppTextStyles.button,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 46.h,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // Navigate to trading screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/trading',
                (route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              // padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              languageService.tr("common_skip_for_now"),
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class SvgColorHelper {
  static Future<Widget> loadSvgWithColor({
    required String assetPath,
    required Color targetColor,
    required String colorToReplace, // e.g. "#FF0000"
    double? height,
    double? width,
  }) async {
    // Load SVG as string
    String svgString = await rootBundle.loadString(assetPath);

    // Replace specific color
    svgString = svgString.replaceAll(
      colorToReplace.toUpperCase(),
      _colorToHex(targetColor),
    );
    svgString = svgString.replaceAll(
      colorToReplace.toLowerCase(),
      _colorToHex(targetColor),
    );

    // Return rendered SVG
    return SvgPicture.string(svgString, height: height, width: width);
  }

  static Future<Widget> loadSvgWithTwoColors({
    required String assetPath,
    required Color targetColor1,
    required String colorToReplace1, // e.g. "#FF0000"
    required Color targetColor2,
    required String colorToReplace2, // e.g. "#00FF00"
    double? height,
    double? width,
  }) async {
    // Load SVG as string
    String svgString = await rootBundle.loadString(assetPath);

    // Replace first color (both uppercase and lowercase)
    svgString = svgString.replaceAll(
      colorToReplace1.toUpperCase(),
      _colorToHex(targetColor1),
    );
    svgString = svgString.replaceAll(
      colorToReplace1.toLowerCase(),
      _colorToHex(targetColor1),
    );

    // Replace second color (both uppercase and lowercase)
    svgString = svgString.replaceAll(
      colorToReplace2.toUpperCase(),
      _colorToHex(targetColor2),
    );
    svgString = svgString.replaceAll(
      colorToReplace2.toLowerCase(),
      _colorToHex(targetColor2),
    );

    // Return rendered SVG
    return SvgPicture.string(svgString, height: height, width: width);
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
