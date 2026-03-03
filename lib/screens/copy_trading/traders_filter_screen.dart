import 'package:flutter/material.dart';
import 'package:crm_app/constants/color.dart';
import 'package:flutter_svg/svg.dart';

class TradersFilterScreen extends StatefulWidget {
  const TradersFilterScreen({super.key});

  @override
  State<TradersFilterScreen> createState() => _TradersFilterScreenState();
}

class _TradersFilterScreenState extends State<TradersFilterScreen> {
  bool freeTrial = false;
  String minExpertise = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        freeTrial = false;
                        minExpertise = 'All';
                      });
                    },
                    child: const Text(
                      'Reset all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Minimum Investment
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '\$25.00 or more',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          left: 12,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: const Text(
                              'Minimum Investment',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Free 7-day trial
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          freeTrial = !freeTrial;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Free 7-day trial',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color:
                                      freeTrial
                                          ? AppColors.primary
                                          : Colors.grey.withOpacity(0.8),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                color:
                                    freeTrial
                                        ? AppColors.primary
                                        : Colors.transparent,
                              ),
                              child:
                                  freeTrial
                                      ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Minimum Expertise
                    Card(
                      elevation: 0.8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.transparent),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Minimum Expertise',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Divider(
                              height: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          _buildExpertiseRadioItem(
                            'Legend',
                            SvgPicture.asset(
                              "assets/svg/copy_trading/filters/gold_legend.svg",
                              width: 20,
                              height: 20,
                            ),
                            minExpertise,
                            (val) => setState(() => minExpertise = val!),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Divider(
                              height: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          _buildExpertiseRadioItem(
                            'Expert',
                            SvgPicture.asset(
                              "assets/svg/copy_trading/filters/blue_expert.svg",
                              width: 20,
                              height: 20,
                            ),

                            minExpertise,
                            (val) => setState(() => minExpertise = val!),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Divider(
                              height: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          _buildExpertiseRadioItem(
                            'High Achiever',
                            SvgPicture.asset(
                              "assets/svg/copy_trading/filters/green_highachiever.svg",
                              width: 20,
                              height: 20,
                            ),

                            minExpertise,
                            (val) => setState(() => minExpertise = val!),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Divider(
                              height: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          _buildExpertiseRadioItem(
                            'Growing Talent',
                            SvgPicture.asset(
                              "assets/svg/copy_trading/filters/grey_growing_talent.svg",
                              width: 14,
                              height: 14,
                            ),

                            minExpertise,
                            (val) => setState(() => minExpertise = val!),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Divider(
                              height: 1,
                              color: Color(0xFFEEEEEE),
                            ),
                          ),
                          _buildExpertiseRadioItem(
                            'All',
                            SvgPicture.asset(
                              "assets/svg/menu.svg",
                              width: 20,
                              height: 20,
                            ),
                            minExpertise,
                            (val) => setState(() => minExpertise = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 100,
                    ), // padding for the bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 20,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Show 108 Master Traders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpertiseRadioItem(
    String title,
    Widget icon,
    String groupValue,
    ValueChanged<String?> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.icongrey,
                ),
              ),
            ),
            SizedBox(
              width: 20,
              height: 20,
              child: Radio<String>(
                value: title,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: AppColors.primary,
                fillColor: MaterialStateProperty.resolveWith<Color>((
                  Set<MaterialState> states,
                ) {
                  if (states.contains(MaterialState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.grey.shade400;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
