import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/screens/home/create_pipze_account_screen.dart';

class ChooseAccountScreen extends StatefulWidget {
  const ChooseAccountScreen({Key? key}) : super(key: key);

  @override
  State<ChooseAccountScreen> createState() => _ChooseAccountScreenState();
}

class _ChooseAccountScreenState extends State<ChooseAccountScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;

  final List<AccountType> accountTypes = [
    AccountType(
      name: 'Pipze MT5',
      icon: '5',
      spread: '0.6 pips',
      instruments: '230',
      minDeposit: '\$25',
      maxLeverage: '1:1000',
      marginCall: '0.25',
      stopOutLevel: '0.15',
      isRecommended: true,
    ),
    AccountType(
      name: 'Pipze MT4',
      icon: '4',
      spread: '0.8 pips',
      instruments: '200',
      minDeposit: '\$50',
      maxLeverage: '1:500',
      marginCall: '0.30',
      stopOutLevel: '0.20',
      isRecommended: false,
    ),
    AccountType(
      name: 'Pipze Pro',
      icon: 'P',
      spread: '0.4 pips',
      instruments: '250',
      minDeposit: '\$100',
      maxLeverage: '1:2000',
      marginCall: '0.20',
      stopOutLevel: '0.10',
      isRecommended: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        backgroundColor: AppColors.backgroundLight,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
        ),
        title: Text(
          'Choose your account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Instructional Text
            _buildInstructionalText(),

            // Account Cards with proper spacing
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: _buildAccountCards(),
              ),
            ),

            // Page Indicator
            _buildPageIndicator(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionalText() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Text(
        'Choose an account type you\'d like to start trading with',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4),
      ),
    );
  }

  Widget _buildAccountCards() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: accountTypes.length,
      itemBuilder: (context, index) {
        return _buildAccountCard(accountTypes[index], index);
      },
    );
  }

  Widget _buildAccountCard(AccountType accountType, int index) {
    bool isCurrentCard = index == _currentIndex;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: isCurrentCard ? 2 : 1,
        ),
        boxShadow:
            isCurrentCard
                ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name and icon
          Row(
            children: [
              Expanded(
                child: Text(
                  accountType.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    accountType.icon,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Account specifications
          _buildSpecificationRow('Spread from', accountType.spread),
          _buildDivider(),
          _buildSpecificationRow('Instruments', accountType.instruments),
          _buildDivider(),
          _buildSpecificationRow('Min deposit', accountType.minDeposit),
          _buildDivider(),
          _buildSpecificationRow('Maximum leverage', accountType.maxLeverage),
          _buildDivider(),
          _buildSpecificationRow('Margin call', accountType.marginCall),
          _buildDivider(),
          _buildSpecificationRow('Stop Out level', accountType.stopOutLevel),

          // SizedBox(height: 32),
          Spacer(),
          // Open Account Button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _onOpenAccount(accountType),
                child: Center(
                  child: Text(
                    'Open Account',
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

        ],
      ),
    );
  }

  Widget _buildSpecificationRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey[200]);
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        accountTypes.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _currentIndex == index ? AppColors.primary : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  void _onOpenAccount(AccountType accountType) {
    // Navigate to the new Pipze account creation screen
    Get.to(() => CreatePipzeAccountScreen(accountType: accountType.name));
  }
}

class AccountType {
  final String name;
  final String icon;
  final String spread;
  final String instruments;
  final String minDeposit;
  final String maxLeverage;
  final String marginCall;
  final String stopOutLevel;
  final bool isRecommended;

  AccountType({
    required this.name,
    required this.icon,
    required this.spread,
    required this.instruments,
    required this.minDeposit,
    required this.maxLeverage,
    required this.marginCall,
    required this.stopOutLevel,
    this.isRecommended = false,
  });
}
