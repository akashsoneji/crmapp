import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Transaction Model
class Transaction {
  final String id;
  final String type;
  final double amount;
  final String accountNumber;
  final String remark;
  final DateTime date;
  final String status;
  final bool isPositive;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.accountNumber,
    required this.remark,
    required this.date,
    required this.status,
    required this.isPositive,
  });
}

// Controller
class TransactionHistoryController extends GetxController {
  final RxString selectedAccount = 'All'.obs;
  final RxString selectedDate = '25 Jan 2001'.obs;
  final RxString selectedTransactionType = 'Deposit'.obs;
  final RxInt selectedTransactionIndex = (-1).obs;

  final List<String> accounts = ['All', 'Account 1', 'Account 2', 'Account 3'];
  final List<String> transactionTypes = ['All', 'Deposit', 'Withdrawal', 'Transfer'];

  final RxList<Transaction> transactions = <Transaction>[
    Transaction(
      id: 'WD - 6465',
      type: 'Deposit',
      amount: 200.00,
      accountNumber: '5 901063',
      remark: 'It is a long established fact that a reader will be by the readable content of a page layout.',
      date: DateTime(2001, 1, 25),
      status: 'Completed',
      isPositive: true,
    ),
    Transaction(
      id: 'WD - 6465',
      type: 'Withdrawal',
      amount: 880.00,
      accountNumber: '5 901063',
      remark: 'It is a long established fact that a reader will be by the readable content of a page layout.',
      date: DateTime(2001, 1, 25),
      status: 'Completed',
      isPositive: false,
    ),
    Transaction(
      id: 'WD - 6465',
      type: 'Deposit',
      amount: 10.00,
      accountNumber: '5 901063',
      remark: 'It is a long established fact that a reader will be by the readable content of a page layout.',
      date: DateTime(2001, 1, 25),
      status: 'Completed',
      isPositive: true,
    ),
    Transaction(
      id: 'WD - 6465',
      type: 'Deposit',
      amount: 340.00,
      accountNumber: '5 901063',
      remark: 'It is a long established fact that a reader will be by the readable content of a page layout.',
      date: DateTime(2001, 1, 25),
      status: 'Approved',
      isPositive: true,
    ),
  ].obs;

  void updateAccount(String account) {
    selectedAccount.value = account;
    filterTransactions();
  }

  void updateDate(String date) {
    selectedDate.value = date;
    filterTransactions();
  }

  void updateTransactionType(String type) {
    selectedTransactionType.value = type;
    filterTransactions();
  }

  void selectTransaction(int index) {
    selectedTransactionIndex.value = index;
  }

  void goBack() {
    selectedTransactionIndex.value = -1;
  }

  void filterTransactions() {
    // Implement filtering logic here based on selected filters
    // For demo purposes, we're showing all transactions
  }

  void openDatePicker() {
    // Implement date picker
    Get.snackbar(
      'Date Picker',
      'Date picker would open here',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
