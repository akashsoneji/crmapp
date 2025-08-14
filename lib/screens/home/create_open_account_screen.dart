import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/color.dart';
import '../../services/language_service.dart';

class CreateOpenAccountScreen extends StatefulWidget {
  final String accountType; // 'real' or 'demo'

  const CreateOpenAccountScreen({Key? key, required this.accountType})
    : super(key: key);

  @override
  State<CreateOpenAccountScreen> createState() =>
      _CreateOpenAccountScreenState();
}

class _CreateOpenAccountScreenState extends State<CreateOpenAccountScreen> {
  String selectedAccount = 'Pipze Demo';
  String selectedAccountType = 'Pipze Demo'; // MT5 Demo or Pipze Demo
  final TextEditingController depositAmountController = TextEditingController(
    text: '500.00',
  );
  final TextEditingController tradingPasswordController = TextEditingController(
    text: 'XXXXXXXXX',
  );
  final TextEditingController investorPasswordController =
      TextEditingController(text: 'XXXXXXXXX');

  bool isTradingPasswordVisible = false;
  bool isInvestorPasswordVisible = false;

  final List<String> accountOptions = [
    'Pipze Demo',
    'MT5 Demo',
    'Pipze Real',
    'MT5 Real',
  ];

  late final LanguageService languageService;

  @override
  void initState() {
    super.initState();
    languageService = Get.find<LanguageService>();

    // Set default values based on account type
    if (widget.accountType == 'demo') {
      selectedAccount = 'Pipze Demo';
      selectedAccountType = 'Pipze Demo';
    } else {
      selectedAccount = 'Pipze Real';
      selectedAccountType = 'Pipze Real';
    }
  }

  void _showAccountDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  languageService.tr('create_account_select_account'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),
                ...accountOptions.map(
                  (option) => ListTile(
                    title: Text(
                      option,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    trailing:
                        selectedAccount == option
                            ? Icon(Icons.check, color: AppColors.primary)
                            : null,
                    onTap: () {
                      setState(() {
                        selectedAccount = option;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          languageService.tr('create_account_create_open_account'),
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Account Dropdown
            Text(
              languageService.tr('create_account_select_account'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showAccountDropdown(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedAccount,
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              selectedAccount.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Account Type Radio Buttons
            Text(
              languageService.tr('create_account_account_type'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                // MT5 Demo Radio Button
                Row(
                  children: [
                    Radio<String>(
                      value: 'MT5 Demo',
                      groupValue: selectedAccountType,
                      onChanged: (value) {
                        setState(() {
                          selectedAccountType = value!;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      languageService.tr('create_account_mt5_demo'),
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
                SizedBox(width: 32),
                // Pipze Demo Radio Button
                Row(
                  children: [
                    Radio<String>(
                      value: 'Pipze Demo',
                      groupValue: selectedAccountType,
                      onChanged: (value) {
                        setState(() {
                          selectedAccountType = value!;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      languageService.tr('create_account_pipze_demo'),
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 32),

            // Deposit Amount Field
            Text(
              languageService.tr('create_account_deposit_amount'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: depositAmountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16, color: Colors.black87),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: languageService.tr('create_account_enter_amount'),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Pipze Trading Password Field
            Text(
              languageService.tr('create_account_pipze_trading_password'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tradingPasswordController,
                      obscureText: !isTradingPasswordVisible,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter trading password',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isTradingPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        isTradingPasswordVisible = !isTradingPasswordVisible;
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Pipze Investor Password Field
            Text(
              'Pipze Investor Password',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: investorPasswordController,
                      obscureText: !isInvestorPasswordVisible,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter investor password',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isInvestorPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        isInvestorPasswordVisible = !isInvestorPasswordVisible;
                      });
                    },
                  ),
                ],
              ),
            ),

            Spacer(),

            // Open Account Button
            GestureDetector(
              onTap: _handleOpenAccount,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                                    child: Text(
                    _getButtonText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (selectedAccountType.contains('Demo')) {
      return 'Open Demo Account';
    } else {
      return 'Open Real Account';
    }
  }

  void _handleOpenAccount() async {
    // Validate form fields
    if (depositAmountController.text.isEmpty ||
        tradingPasswordController.text.isEmpty ||
        investorPasswordController.text.isEmpty) {
      Get.snackbar(
        languageService.tr('create_account_error'),
        languageService.tr('create_account_error_fill_fields'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }



    // Show success message and go back
    Get.snackbar(
      languageService.tr('create_account_success'),
      languageService.tr('create_account_success_created'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );

    // Navigate back to dashboard
    Get.until((route) => route.isFirst);
  }

  @override
  void dispose() {
    depositAmountController.dispose();
    tradingPasswordController.dispose();
    investorPasswordController.dispose();
    super.dispose();
  }
}
