import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  late final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.only(left: 16),
          child: Icon(
            Icons.apps,
            color: Colors.black,
            size: 24,
          ),
        ),
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart_outline,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              onPressed: () {},
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              onPressed: controller.showOpenAccountSheet,
            ),
          ),
        ],
      ),
      body: Obx(() => Stack(
        children: [
          // Main Content
          AnimatedOpacity(
            opacity: controller.isBottomSheetOpen.value ? 0.3 : 1.0,
            duration: Duration(milliseconds: 300),
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: controller.accounts.length,
              itemBuilder: (context, index) {
                final account = controller.accounts[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: _buildAccountCard(account),
                );
              },
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildAccountCard(Account account) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Account Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    account.accountNumber,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: account.label == 'REAL'
                          ? Colors.orange
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      account.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Equity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '\$${account.equity.toStringAsFixed(2)} ${account.currency}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 4),
                      Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 8),

          // Account Type
          Row(
            children: [
              Text(
                '${account.type}  ${account.status}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              // First Action (Always present)
              Expanded(
                child: _buildActionButton(
                  icon: Icons.trending_up,
                  label: account.actions[0],
                  onTap: () {
                    if (account.actions[0] == 'Deposit') {
                      controller.onDeposit(account.accountNumber);
                    }
                  },
                ),
              ),

              SizedBox(width: 12),

              // Second Action
              Expanded(
                child: _buildActionButton(
                  icon: account.actions.length > 1 && account.actions[1] == 'Withdraw'
                      ? Icons.trending_down
                      : Icons.settings,
                  label: account.actions.length > 1 ? account.actions[1] : 'Settings',
                  onTap: () {
                    if (account.actions.length > 1) {
                      if (account.actions[1] == 'Withdraw') {
                        controller.onWithdraw(account.accountNumber);
                      } else {
                        controller.onSettings(account.accountNumber);
                      }
                    } else {
                      controller.onSettings(account.accountNumber);
                    }
                  },
                ),
              ),

              SizedBox(width: 12),

              // More Options
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ),

          // Switch to Trade Button (only for some accounts)
          if (account.label == 'DEMO' ||
              (account.actions.contains('Withdraw'))) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => controller.switchToTrade(account.accountNumber),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF7B2CBF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz,
                      color: Color(0xFF7B2CBF),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Switch to Trade',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B2CBF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Color(0xFF7B2CBF),
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7B2CBF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenAccountBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: 24),

          // Title
          Text(
            'Open Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Open a trading account to get superior trading conditions any strategy',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),

          SizedBox(height: 40),

          // Real Account Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: controller.openRealAccount,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Real',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7B2CBF),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Demo Account Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: controller.openDemoAccount,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Demo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Cancel Button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}