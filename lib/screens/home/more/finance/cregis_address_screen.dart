import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:crm_app/controllers/dashboard_controller.dart';
import 'package:crm_app/controllers/finance/deposit_instrction_controller.dart';
import 'package:crm_app/controllers/finance/transaction_history_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CregisAddressScreen extends StatefulWidget {
  final String cregisAddress;
  final String referenceNumber;
  final String amount;
  final String networkKey;
  final String tapTimeIso;

  const CregisAddressScreen({
    super.key,
    required this.cregisAddress,
    required this.referenceNumber,
    required this.amount,
    required this.networkKey,
    this.tapTimeIso = '',
  });

  @override
  State<CregisAddressScreen> createState() => _CregisAddressScreenState();
}

class _CregisAddressScreenState extends State<CregisAddressScreen> {
  // Wait up to 120s, polling Transaction History every 5s.
  static const int _pollIntervalSeconds = 5;
  static const int _maxWaitSeconds = 120;

  Timer? _pollingTimer;
  DateTime? _pollingStartedAt;
  bool _resolved = false; // set once success/timeout/cancel fires
  String _statusText = 'Waiting for payment...';
  bool _isPolling = true;
  int _pollAttempts = 0;

  // Visible debug strip
  String _debugLastCall = '(no poll yet)';
  String _debugLastResponse = '(no response yet)';
  DateTime? _debugLastAt;

  @override
  void initState() {
    super.initState();
    final depositCtrl = _safeDepositCtrl();
    depositCtrl?.setPollingStatus('pending');
    depositCtrl?.setPollingAttemptCount(0);

    _startStatusPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    final depositCtrl = _safeDepositCtrl();
    if (depositCtrl != null && !_resolved) {
      depositCtrl.clearPollingState();
    }
    super.dispose();
  }

  DepositInstructionController? _safeDepositCtrl() {
    if (Get.isRegistered<DepositInstructionController>()) {
      return Get.find<DepositInstructionController>();
    }
    return null;
  }

  TransactionHistoryController _thCtrl() {
    if (!Get.isRegistered<TransactionHistoryController>()) {
      Get.put(TransactionHistoryController());
    }
    return Get.find<TransactionHistoryController>();
  }

  void _startStatusPolling() {
    _pollingStartedAt = DateTime.now();
    _pollAttempts = 0;
    _pollingTimer = Timer.periodic(
      const Duration(seconds: _pollIntervalSeconds),
      (timer) async {
        if (!mounted || _resolved) {
          timer.cancel();
          return;
        }

        final elapsed =
            DateTime.now().difference(_pollingStartedAt!).inSeconds;
        if (elapsed >= _maxWaitSeconds) {
          timer.cancel();
          _onTimeout();
          return;
        }

        _pollAttempts++;
        _safeDepositCtrl()?.setPollingAttemptCount(_pollAttempts);

        if (mounted) {
          setState(() {
            final remaining = _maxWaitSeconds - elapsed;
            _statusText =
                'Waiting for payment... (${remaining}s, attempt $_pollAttempts)';
          });
        }

        final ref = widget.referenceNumber;
        if (ref.trim().isEmpty) return;

        _debugLastCall =
            'GET /transactions @ ${DateTime.now().toIso8601String()} '
            '(attempt $_pollAttempts, ref=${ref.length > 10 ? '${ref.substring(0, 10)}…' : ref})';
        final res =
            await _thCtrl().fetchLatestTransactionForRef(ref, statusFilter: true);

        if (!mounted || _resolved) return;
        if (res.row != null) {
          _debugLastResponse =
              'MATCH status=${res.row!.status ?? '?'} amount=${res.row!.amount ?? '?'} '
              'created_at=${res.row!.createdAt ?? '?'}';
          _debugLastAt = DateTime.now();
          if (mounted) setState(() {});
          _onSuccess();
          return;
        }
        _debugLastResponse =
            'NO MATCH (status=${res.rawStatus}, totalRows=${res.totalRows})';
        _debugLastAt = DateTime.now();
        if (mounted) setState(() {});
      },
    );
  }

  void _onSuccess() {
    if (_resolved) return;
    _resolved = true;
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPolling = false;
        _statusText = 'Deposit confirmed!';
      });
    }
    CustomToastService.showSuccess(
      message: 'Deposit confirmed! Balance updated.',
    );

    try {
      Get.find<DashboardController>().markMT5AccountsAsStale();
    } catch (_) {}

    _safeDepositCtrl()?.clearPollingState();
    Get.offAllNamed(
      AppPages.TRANSACTION_HISTORY,
      arguments: {'from': 'finance'},
    );
  }

  void _onTimeout() {
    if (_resolved) return;
    _resolved = true;
    _pollingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isPolling = false;
        _statusText =
            'Transaction is processing. Check Transaction History for status.';
      });
    }
    CustomToastService.showWarning(
      message:
          'Transaction is processing. Please wait in Transaction History.',
      title: 'Processing',
    );
    _safeDepositCtrl()?.setPollingStatus('timeout');
    Get.offAllNamed(
      AppPages.TRANSACTION_HISTORY,
      arguments: {'from': 'finance'},
    );
  }

  /// Back arrow / device back / swipe within the wait window → confirm dialog.
  Future<void> _confirmCancel() async {
    if (_resolved) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: const Text(
          'Are you sure you want to cancel this payment? The transaction '
          'will not be processed and you will be returned to the home screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No, keep waiting'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || _resolved) return;
    _resolved = true;
    _pollingTimer?.cancel();
    CustomToastService.showError(message: 'Transaction cancelled');
    _safeDepositCtrl()?.clearPollingState();
    Get.offAllNamed(Routes.TRADING);
  }

  /// Explicit "Go to Transaction History" tap — positive action, no cancel toast.
  void _goToHistory() {
    if (_resolved) return;
    _resolved = true;
    _pollingTimer?.cancel();
    _safeDepositCtrl()?.clearPollingState();
    Get.offAllNamed(
      AppPages.TRANSACTION_HISTORY,
      arguments: {'from': 'finance'},
    );
  }

  String _getNetworkLabel(String key) {
    final labels = {
      'trc20': 'TRC-20 (TRON)',
      'erc20': 'ERC-20 (Ethereum)',
      'bep20': 'BEP-20 (BSC)',
      'polygon': 'Polygon (MATIC)',
    };
    return labels[key.toLowerCase()] ?? key.toUpperCase();
  }

  String _getSafetyCurrency(String key) {
    final currencies = {
      'trc20': 'USDT-TRC20',
      'erc20': 'USDT-ERC20',
      'bep20': 'USDT-BEP20',
      'polygon': 'USDT-POLYGON',
    };
    return currencies[key.toLowerCase()] ?? 'USDT';
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${Uri.encodeComponent(widget.cregisAddress)}';
    final networkLabel = _getNetworkLabel(widget.networkKey);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _confirmCancel,
          ),
          title: Text(
            'Direct Crypto Transfer',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Amount info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Send',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.amount} USD',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'using $networkLabel',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border!),
                ),
                child: Image.network(
                  qrUrl,
                  height: 200,
                  width: 200,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      width: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.qr_code_2,
                          size: 80,
                          color: AppColors.textGrey,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Address section
              Text(
                'Deposit Wallet Address',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.cregisAddress,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: 'monospace',
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.cregisAddress),
                        );
                        CustomToastService.showSuccess(
                          message: 'Address copied to clipboard',
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.copy,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Safety warning
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only send ${_getSafetyCurrency(widget.networkKey)} on $networkLabel. Sending other assets may result in loss.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reference
              Text(
                'Reference: ${widget.referenceNumber}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textGrey,
                ),
              ),

              const SizedBox(height: 32),

              // Polling status
              if (_isPolling)
                Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textGrey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // ── Debug strip: shows last Transaction-History poll
                    //    request/response so QA can see whether the Cregis
                    //    reference_number matched. ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug — last poll',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _debugLastCall,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _debugLastResponse,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.black87,
                            ),
                          ),
                          if (_debugLastAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'at ${_debugLastAt!.toIso8601String()}',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.orange.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.whiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text(
                          'Go to Transaction History',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Debug strip (also visible on terminal states)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Debug — last poll',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _debugLastCall,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _debugLastResponse,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.black87,
                            ),
                          ),
                          if (_debugLastAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'at ${_debugLastAt!.toIso8601String()}',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
