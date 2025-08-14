import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pipze/constants/color.dart';
import 'package:pipze/utils/trl_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String selectedAccount = 'All';
  DateTime selectedDate = DateTime(2001, 1, 25);
  String selectedTransactionType = 'Deposit';

  final List<String> accounts = [
    'All',
    'MT5 Account',
    'Pipze Account',
    'Wallet',
  ];
  final List<String> transactionTypes = [
    'Deposit',
    'Withdrawal',
    'Transfer',
    'All',
  ];

  // Sample transaction data
  final List<Map<String, dynamic>> allTransactions = [
    {
      'id': 'WD - 6465',
      'subId': '5 901063',
      'remark':
          'Remark: It is a long established fact that a reader will be by the readable content of a page layout.',
      'amount': 200.00,
      'type': 'deposit',
      'date': DateTime(2001, 1, 25),
      'account': 'MT5 Account',
    },
    {
      'id': 'WD - 6465',
      'subId': '5 901063',
      'remark':
          'Remark: It is a long established fact that a reader will be by the readable content of a page layout.',
      'amount': -80.00,
      'type': 'withdrawal',
      'date': DateTime(2001, 1, 24),
      'account': 'Pipze Account',
    },
    {
      'id': 'WD - 6465',
      'subId': '5 901063',
      'remark':
          'Remark: It is a long established fact that a reader will be by the readable content of a page layout.',
      'amount': 10.00,
      'type': 'deposit',
      'date': DateTime(2001, 1, 23),
      'account': 'Wallet',
    },
    {
      'id': 'WD - 6465',
      'subId': '5 901063',
      'remark':
          'Remark: It is a long established fact that a reader will be by the readable content of a page layout.',
      'amount': 340.00,
      'type': 'deposit',
      'date': DateTime(2001, 1, 22),
      'account': 'MT5 Account',
    },
    {
      'id': 'WD - 6465',
      'subId': '5 901063',
      'remark':
          'Remark: It is a long established fact that a reader will be by the readable content of a page layout.',
      'amount': -80.00,
      'type': 'withdrawal',
      'date': DateTime(2001, 1, 21),
      'account': 'Pipze Account',
    },
  ];

  List<Map<String, dynamic>> get filteredTransactions {
    List<Map<String, dynamic>> filtered =
        allTransactions.where((transaction) {
          // Filter by account
          if (selectedAccount != 'All' &&
              transaction['account'] != selectedAccount) {
            return false;
          }

          // Filter by transaction type
          if (selectedTransactionType != 'All' &&
              transaction['type'] != selectedTransactionType.toLowerCase()) {
            return false;
          }

          return true;
        }).toList();

    // Sort transactions: selected date first, then others
    filtered.sort((a, b) {
      final aDate = a['date'] as DateTime;
      final bDate = b['date'] as DateTime;

      // Check if transaction is on selected date
      final aIsSelectedDate =
          aDate.year == selectedDate.year &&
          aDate.month == selectedDate.month &&
          aDate.day == selectedDate.day;

      final bIsSelectedDate =
          bDate.year == selectedDate.year &&
          bDate.month == selectedDate.month &&
          bDate.day == selectedDate.day;

      // Selected date transactions come first
      if (aIsSelectedDate && !bIsSelectedDate) return -1;
      if (!aIsSelectedDate && bIsSelectedDate) return 1;

      // If both are same date type, sort by date (newest first)
      if (aIsSelectedDate == bIsSelectedDate) {
        return bDate.compareTo(aDate);
      }

      return 0;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 20.w),
          child: IconButton(
            icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
            onPressed: () => Get.back(),
          ),
        ),
        title: Text(
          'Transaction History',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

              // Filter Section
              _buildFilterSection(),

              SizedBox(height: 24.h),

              // Transaction List
              Expanded(child: _buildTransactionList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Filter
        _buildFilterField(
          label: 'Account',
          value: selectedAccount,
          onTap: () => _showAccountDropdown(),
          suffixIcon: Icons.arrow_drop_down,
        ),

        SizedBox(height: 16.h),

        // Date and Transaction Type Filters in Row
        Row(
          children: [
            Expanded(
              child: _buildFilterField(
                label: 'Select Date',
                value: _formatDate(selectedDate),
                onTap: () => _showDatePicker(),
                suffixIcon: Icons.calendar_today,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildFilterField(
                label: 'Transaction Type',
                value: selectedTransactionType,
                onTap: () => _showTransactionTypeDropdown(),
                suffixIcon: Icons.arrow_drop_down,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterField({
    required String label,
    required String value,
    required VoidCallback onTap,
    required IconData suffixIcon,
  }) {
    return RTLHelper.rtlTextField(
      controller: TextEditingController(text: value),
      readOnly: true,
      onTap: onTap,
      suffixIcon: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Icon(suffixIcon, color: Colors.grey[600], size: 20),
        ),
      ),
      decoration: InputDecoration(
        labelText: label,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = filteredTransactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final bool isDeposit = transaction['type'] == 'deposit';
    final Color iconColor = isDeposit ? Colors.green : Colors.red;
    final Color amountColor = isDeposit ? Colors.green : Colors.red;
    final String amountPrefix = isDeposit ? '' : '-';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color:
                          isDeposit
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SvgPicture.asset(
                      isDeposit
                          ? 'assets/svg/deshboard/money-recive.svg'
                          : 'assets/svg/deshboard/money-send.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        isDeposit ? Colors.green : Colors.red,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['id'],
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        transaction['subId'],
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '$amountPrefix\$${transaction['amount'].abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: amountColor,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Remark
          RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Remark: ',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: transaction['remark'].toString().replaceFirst(
                    'Remark: ',
                    '',
                  ),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.icongrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Select Account',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 200.h,
                  child: ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final isSelected = account == selectedAccount;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedAccount = account;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showTransactionTypeDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Select Transaction Type',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 24.h),
                Container(
                  height: 200.h,
                  child: ListView.builder(
                    itemCount: transactionTypes.length,
                    itemBuilder: (context, index) {
                      final type = transactionTypes[index];
                      final isSelected = type == selectedTransactionType;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedTransactionType = type;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 16.h,
                            horizontal: 16.w,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppColors.primary.withOpacity(0.1)
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color:
                                        isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
