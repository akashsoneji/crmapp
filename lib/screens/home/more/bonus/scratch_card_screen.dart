import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:crm_app/constants/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:scratcher/scratcher.dart';
import 'package:crm_app/constants/color.dart';
import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class ScratchCardApiModel {
  final int id;
  final String status; // 'active' | 'scratched' | 'expired'
  final num? rewardAmount;
  final String refreshWindow;
  final String expiresAt;

  ScratchCardApiModel({
    required this.id,
    required this.status,
    this.rewardAmount,
    required this.refreshWindow,
    required this.expiresAt,
  });

  factory ScratchCardApiModel.fromJson(Map<String, dynamic> json) {
    final rawReward = json['reward_amount'];
    return ScratchCardApiModel(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'active',
      rewardAmount:
          (rawReward is num)
              ? rawReward.toDouble()
              : (rawReward is String && rawReward.isNotEmpty)
              ? double.tryParse(rawReward)
              : null,
      refreshWindow: json['refresh_window']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
    );
  }

  bool get isScratched => status == 'scratched';
  bool get isActive => status == 'active';

  /// Human-readable expires_at label, e.g. "20 Mar 08:00"
  String get expiresLabel {
    try {
      final dt = DateTime.parse(expiresAt).toLocal();
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
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} $h:$m';
    } catch (_) {
      return expiresAt;
    }
  }
}

class ScratchCardSummaryModel {
  final double earnedIn30Days;
  final int maxLimit30Days;
  final String? nextCardAvailableAt;

  ScratchCardSummaryModel({
    required this.earnedIn30Days,
    required this.maxLimit30Days,
    this.nextCardAvailableAt,
  });

  factory ScratchCardSummaryModel.fromJson(Map<String, dynamic> json) {
    final earned = json['earned_in_30_days'];
    final maxLimit = json['max_limit_30_days'];
    return ScratchCardSummaryModel(
      earnedIn30Days:
          (earned is num)
              ? earned.toDouble()
              : double.tryParse(earned?.toString() ?? '') ?? 0.0,
      maxLimit30Days:
          (maxLimit is num)
              ? maxLimit.toInt()
              : int.tryParse(maxLimit?.toString() ?? '') ?? 0,
      nextCardAvailableAt: json['next_card_available_at']?.toString(),
    );
  }

  /// Parsed next card available time, or null if not set / in the past
  DateTime? get nextCardDateTime {
    if (nextCardAvailableAt == null || nextCardAvailableAt!.isEmpty) return null;
    try {
      return DateTime.parse(nextCardAvailableAt!).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// True when a new card countdown is active (not null and in the future)
  bool get hasUpcomingCard {
    final dt = nextCardDateTime;
    if (dt == null) return false;
    return dt.isAfter(DateTime.now());
  }

  /// Human-readable label, e.g. "Next card: 21 Mar 20:00"
  String get nextCardLabel {
    final dt = nextCardDateTime;
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} $h:$m';
  }
}

class ScratchCardRevealModel {
  final int cardId;
  final String status;
  final double rewardAmount;
  final String scratchedAt;
  final String creditStatus; // 'none' | 'pending' | 'credited' | 'failed'
  final String creditError;

  ScratchCardRevealModel({
    required this.cardId,
    required this.status,
    required this.rewardAmount,
    required this.scratchedAt,
    required this.creditStatus,
    required this.creditError,
  });

  factory ScratchCardRevealModel.fromJson(Map<String, dynamic> json) {
    final reward = json['reward_amount'];
    return ScratchCardRevealModel(
      cardId: (json['card_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'scratched',
      rewardAmount:
          (reward is num)
              ? reward.toDouble()
              : double.tryParse(reward?.toString() ?? '') ?? 0.0,
      scratchedAt: json['scratched_at']?.toString() ?? '',
      creditStatus: json['credit_status']?.toString() ?? 'none',
      creditError: json['credit_error']?.toString() ?? '',
    );
  }

  bool get isWin => rewardAmount > 0;
  bool get isCreditFailed => creditStatus == 'failed';
}

// ─────────────────────────────────────────────────────────────────────────────
// SCRATCH CARD CONTROLLER  (list-level)
// ─────────────────────────────────────────────────────────────────────────────

class ScratchCardController extends GetxController {
  // ── State ──
  final RxList<ScratchCardApiModel> cards = <ScratchCardApiModel>[].obs;
  final Rxn<ScratchCardSummaryModel> summary = Rxn<ScratchCardSummaryModel>();
  final RxBool isLoading = false.obs;
  final RxBool isRevealing = false.obs;
  final RxBool isCreatingAccount = false.obs;

  /// Stored from 409 response so we can pass to create-account call
  int? _pendingScratchGroupId;

  /// The card_id we tried to reveal when we got 409 (to retry after account creation)
  int? _pendingRevealCardId;

  // ── Lifecycle ──
  @override
  void onInit() {
    super.onInit();
    fetchCards();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1) Fetch cards
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> fetchCards() async {
    try {
      isLoading.value = true;
      final response = await ApiService.get(
        endpoint: ApiConstants.getScratchCards,
      );

      if (response.success) {
        final data = response.data?['data'];
        if (data != null && data is Map<String, dynamic>) {
          // Parse summary
          if (data['summary'] != null) {
            summary.value = ScratchCardSummaryModel.fromJson(
              data['summary'] as Map<String, dynamic>,
            );
          }
          // Parse cards
          if (data['cards'] != null && data['cards'] is List) {
            final rawCards = data['cards'] as List<dynamic>;
            cards.assignAll(
              rawCards
                  .map(
                    (e) =>
                        ScratchCardApiModel.fromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            );
          }
        }
      } else {
        CustomToastService.showError(
          title: 'Error',
          message:
              (response.message?.isNotEmpty == true)
                  ? response.message!
                  : 'Failed to load scratch cards',
        );
      }
    } catch (e, t) {
      debugPrint(e.toString());
      debugPrint(t.toString());
      CustomToastService.showError(
        title: 'Error',
        message: 'Network error. Please check your connection.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2) Reveal card
  // ─────────────────────────────────────────────────────────────────────────
  String _generateRandomPassword({int length = 12}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(
      length,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
  }

  Future<ScratchCardRevealModel?> revealCard(int cardId) async {
    try {
      isRevealing.value = true;
      final response = await ApiService.post(
        endpoint: ApiConstants.revealScratchCard,
        data: {'card_id': cardId},
      );

      if (response.success) {
        final data = response.data?['data'];
        if (data != null && data is Map<String, dynamic>) {
          final reveal = ScratchCardRevealModel.fromJson(data);
          // Update card status locally to avoid re-fetching immediately
          _updateLocalCardStatus(cardId, reveal.rewardAmount);
          return reveal;
        }
      } else {
        // Check for 409 SCRATCH_ACCOUNT_REQUIRED
        final errData = response.data;
        if (errData is Map<String, dynamic> &&
            errData['code'] == 'SCRATCH_ACCOUNT_REQUIRED') {
          _pendingRevealCardId = cardId;
          _pendingScratchGroupId =
              (errData['scratch_group_id'] as num?)?.toInt();
          // Spec: no password popup.
          // Auto-generate passwords, create account, then retry reveal.
          if (_pendingScratchGroupId == null) return null;

          Get.dialog(
            const Dialog(
              backgroundColor: Colors.transparent,
              child: SizedBox(
                width: 80,
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            barrierDismissible: false,
          );

          final mainPassword = _generateRandomPassword();
          var investorPassword = _generateRandomPassword();
          while (investorPassword == mainPassword) {
            investorPassword = _generateRandomPassword();
          }

          // createScratchAccount() will retry reveal and show result dialogs.
          await createScratchAccount(
            mainPassword: mainPassword,
            investorPassword: investorPassword,
          );

          return null; // caller should not show win/lose — handled via retry
        } else {
          CustomToastService.showError(
            title: 'Error',
            message:
                (response.message?.isNotEmpty == true)
                    ? response.message!
                    : 'Failed to reveal card',
          );
        }
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Network error. Please check your connection.',
      );
    } finally {
      isRevealing.value = false;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3) Create scratch trading account (called from dialog)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> createScratchAccount({
    required String mainPassword,
    required String investorPassword,
  }) async {
    if (_pendingScratchGroupId == null) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Scratch group not found. Please try again.',
      );
      return;
    }

    try {
      isCreatingAccount.value = true;

      final response = await ApiService.post(
        endpoint: ApiConstants.createMT5Account,
        data: {
          'group_id': _pendingScratchGroupId,
          'main_password': mainPassword,
          'investor_password': investorPassword,
        },
      );

      if (response.success) {
        // Close the loading dialog
        if (Get.isDialogOpen ?? false) Get.back();

        // Auto-retry reveal
        if (_pendingRevealCardId != null) {
          final cardId = _pendingRevealCardId!;
          _pendingRevealCardId = null;
          final reveal = await revealCard(cardId);
          if (reveal != null) {
            _showRevealResultDialog(
              reveal,
              onDone: () {
                if (Get.isDialogOpen ?? false) Get.back();
                // Close the scratch UI (detail screen or dialog)
                Get.back();
                fetchCards();
              },
            );
          }
        }
      } else {
        // Close the loading dialog on failure too
        if (Get.isDialogOpen ?? false) Get.back();
        CustomToastService.showError(
          title: 'Error',
          message:
              (response.message?.isNotEmpty == true)
                  ? response.message!
                  : 'Failed to create scratch account',
        );
      }
    } catch (e) {
      CustomToastService.showError(
        title: 'Error',
        message: 'Network error. Please check your connection.',
      );
    } finally {
      isCreatingAccount.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _updateLocalCardStatus(int cardId, double rewardAmount) {
    final idx = cards.indexWhere((c) => c.id == cardId);
    if (idx != -1) {
      final old = cards[idx];
      cards[idx] = ScratchCardApiModel(
        id: old.id,
        status: 'scratched',
        rewardAmount: rewardAmount,
        refreshWindow: old.refreshWindow,
        expiresAt: old.expiresAt,
      );
      cards.refresh();
    }
  }

  void _showRevealResultDialog(
    ScratchCardRevealModel reveal, {
    VoidCallback? onDone,
  }) {
    final VoidCallback defaultDone = () {
      if (Get.isDialogOpen ?? false) Get.back();
      // If we are on detail screen, we might need to go back another level
      // but usually the caller provides onDone if they want specific navigation.
      fetchCards();
    };

    Get.dialog(
      reveal.isWin
          ? _WinResultDialog(reveal: reveal, onDone: onDone ?? defaultDone)
          : _LoseResultDialog(onDone: onDone ?? defaultDone),
      barrierDismissible: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PER-CARD SCRATCH GESTURE CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class _ScratchGestureController extends GetxController {
  final ScratchCardApiModel card;
  _ScratchGestureController(this.card);

  // 25% → trigger reveal
  static const double checkThreshold = 25.0;

  RxDouble progress = 0.0.obs;
  RxBool hasTriggeredReveal = false.obs;
  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final scratchKey = GlobalKey<ScratcherState>();

  @override
  void onInit() {
    super.onInit();
    if (card.isScratched) {
      hasTriggeredReveal.value = true;
      progressNotifier.value = 1.0;
    }
  }

  void onProgress(double value) {
    progress.value = value;
    progressNotifier.value = value / 100.0;
  }

  void onScratchEnd() {
    if (!hasTriggeredReveal.value && progress.value >= checkThreshold) {
      _doReveal();
    }
  }

  void _doReveal() {
    if (!hasTriggeredReveal.value) {
      hasTriggeredReveal.value = true;
      progressNotifier.value = 1.0;
      scratchKey.currentState?.reveal(
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  @override
  void onClose() {
    progressNotifier.dispose();
    super.onClose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCRATCH CARD LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ScratchCardListScreen extends StatelessWidget {
  const ScratchCardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScratchCardController());

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Rewards',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: controller.fetchCards,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          );
        }

        return Column(
          children: [
            // ── Summary Banner ──
            _SummaryBanner(controller: controller),

            // ── Next Card Countdown Banner ──
            // _NextCardCountdownBanner(controller: controller),

            // ── Cards Grid ──
            Expanded(
              child:
                  controller.cards.isEmpty
                      ? _EmptyState()
                      : GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12.h,
                          crossAxisSpacing: 12.w,
                          childAspectRatio: 1,
                        ),
                        itemCount: controller.cards.length +
                            (controller.summary.value?.hasUpcomingCard == true ? 1 : 0),
                        itemBuilder: (context, index) {
                          final hasLocked =
                              controller.summary.value?.hasUpcomingCard == true;
                          final totalCards = controller.cards.length;

                          // Last item = locked "next card" card
                          if (hasLocked && index == totalCards) {
                            return _LockedScratchCardGridItem(
                              summary: controller.summary.value!,
                            );
                          }

                          final card = controller.cards[index];
                          return _ScratchCardGridItem(
                            card: card,
                            onTap:
                                card.isScratched
                                    ? null
                                    : () async {
                                      await Get.dialog(
                                        _ScratchCardDialog(card: card),
                                        barrierDismissible: false,
                                      );
                                      controller.fetchCards();
                                    },
                          );
                        },
                      ),
            ),
          ],
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY BANNER
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final ScratchCardController controller;
  const _SummaryBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earned (30 days)',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 4.h),
              Obx(() {
                final s = controller.summary.value;
                final earned = s?.earnedIn30Days ?? 0.0;
                final max = s?.maxLimit30Days ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${earned.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    if (max > 0)
                      Text(
                        'of \$$max limit',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
          const Spacer(),
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEXT CARD COUNTDOWN BANNER  (yellow progress line + countdown)
// ─────────────────────────────────────────────────────────────────────────────

class _NextCardCountdownBanner extends StatefulWidget {
  final ScratchCardController controller;
  const _NextCardCountdownBanner({required this.controller});

  @override
  State<_NextCardCountdownBanner> createState() => _NextCardCountdownBannerState();
}

class _NextCardCountdownBannerState extends State<_NextCardCountdownBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every second so the countdown is live
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration diff) {
    if (diff.inSeconds <= 0) return 'Available now!';
    if (diff.inHours >= 24) {
      final d = diff.inDays;
      final h = diff.inHours % 24;
      return '${d}d ${h}h';
    }
    if (diff.inMinutes >= 60) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return '${h}h ${m}m';
    }
    final m = diff.inMinutes;
    final s = diff.inSeconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = widget.controller.summary.value;
      if (s == null || !s.hasUpcomingCard) return const SizedBox.shrink();

      final target = s.nextCardDateTime!;
      final now = DateTime.now();
      final diff = target.difference(now);
      final totalWindow = const Duration(hours: 12); // full 12-hour window
      final elapsed = totalWindow - diff;
      // Progress goes from 0 → 1 as time approaches
      final progress = (elapsed.inSeconds / totalWindow.inSeconds).clamp(0.0, 1.0);

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEA),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.yellow.shade300, width: 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange.shade700, size: 18.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Next card available at',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  s.nextCardLabel,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // Countdown + yellow progress line
            Row(
              children: [
                // Live countdown
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _formatCountdown(diff),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                // Yellow progress line
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade200,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade700,
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'New card arriving...',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard, size: 64.r, color: Colors.grey.shade300),
          SizedBox(height: 12.h),
          Text(
            'No scratch cards available',
            style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCKED (NEXT CARD) GRID ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _LockedScratchCardGridItem extends StatefulWidget {
  final ScratchCardSummaryModel summary;

  const _LockedScratchCardGridItem({required this.summary});

  @override
  State<_LockedScratchCardGridItem> createState() => _LockedScratchCardGridItemState();
}

class _LockedScratchCardGridItemState extends State<_LockedScratchCardGridItem> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(Duration diff) {
    if (diff.inSeconds <= 0) return '00:00';
    if (diff.inHours >= 24) {
      final d = diff.inDays;
      final h = diff.inHours % 24;
      return '${d}d ${h}h';
    }
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.summary.nextCardDateTime;
    if (target == null) return const SizedBox.shrink();

    final diff = target.difference(DateTime.now());
    final totalWindow = const Duration(hours: 12);
    final elapsed = totalWindow - diff;
    final progress = (elapsed.inSeconds / totalWindow.inSeconds).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
      //   Get.dialog(
      //     AlertDialog(
      //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      //       backgroundColor: AppColors.tradeBackgroundCenterColor,
      //       title: Row(
      //         children: [
      //           Icon(Icons.lock_clock, color: Colors.orange.shade700, size: 22.r),
      //           SizedBox(width: 8.w),
      //           Text(
      //             'Card Locked',
      //             style: TextStyle(
      //               fontSize: 16.sp,
      //               fontWeight: FontWeight.w700,
      //               color: AppColors.textPrimary,
      //             ),
      //           ),
      //         ],
      //       ),
      //       content: Column(
      //         mainAxisSize: MainAxisSize.min,
      //         crossAxisAlignment: CrossAxisAlignment.start,
      //         children: [
      //           Text(
      //             'Next card will be available at:',
      //             style: TextStyle(
      //               fontSize: 13.sp,
      //               color: AppColors.textSecondary,
      //             ),
      //           ),
      //           SizedBox(height: 8.h),
      //           Container(
      //             padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      //             decoration: BoxDecoration(
      //               color: Colors.orange.shade50,
      //               borderRadius: BorderRadius.circular(10.r),
      //               border: Border.all(color: Colors.orange.shade200),
      //             ),
      //             child: Row(
      //               children: [
      //                 Icon(Icons.schedule, color: Colors.orange.shade700, size: 18.r),
      //                 SizedBox(width: 8.w),
      //                 Text(
      //                   widget.summary.nextCardLabel,
      //                   style: TextStyle(
      //                     fontSize: 15.sp,
      //                     fontWeight: FontWeight.w700,
      //                     color: Colors.orange.shade800,
      //                   ),
      //                 ),
      //               ],
      //             ),
      //           ),
      //           SizedBox(height: 12.h),
      //           Row(
      //             children: [
      //               Icon(Icons.timer, color: Colors.grey.shade600, size: 16.r),
      //               SizedBox(width: 6.w),
      //               Text(
      //                 'Time remaining: ${_formatCountdown(diff)}',
      //                 style: TextStyle(
      //                   fontSize: 13.sp,
      //                   color: Colors.grey.shade600,
      //                   fontWeight: FontWeight.w500,
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ],
      //       ),
      //       actions: [
      //         TextButton(
      //           onPressed: () => Get.back(),
      //           child: Text(
      //             'OK',
      //             style: TextStyle(
      //               color: AppColors.primary,
      //               fontWeight: FontWeight.w700,
      //               fontSize: 14.sp,
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //   );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // Background SVG
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.31),
                  BlendMode.saturation,
                ),
                child: SvgPicture.asset(
                  'assets/svg/more/scratch-card.svg',
                  fit: BoxFit.cover,
                  colorMapper: PurpleToAppColorMapper(AppColors.primary),
                ),
              ),
            ),

            // Dark overlay
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.28),
              ),
            ),

            // Lock icon + countdown content
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  

               

                  SizedBox(height: 8.h),

                  // Progress bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      children: [
                    
                         Positioned(
                bottom: 10.h,
                left: 10.w,
                right: 10.w,
                child: Container(
                  height: 30.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentStatic,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Text(
                   'Unlock after: '+_formatCountdown(diff),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:  AppTextStyles.scratchCardYellow
                  ),
                ),
              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRID ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _ScratchCardGridItem extends StatelessWidget {
  final ScratchCardApiModel card;
  final VoidCallback? onTap;

  const _ScratchCardGridItem({required this.card, this.onTap});

  String _unlockAfterText() {
    final parsed = DateTime.tryParse(card.expiresAt);
    if (parsed == null) return 'Unlock';

    final diff = parsed.toLocal().difference(DateTime.now());
    if (diff.inSeconds <= 0) return 'Unlock now';

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'Unlock after ${m} min${m == 1 ? '' : 's'}';
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      return 'Unlock after ${h} hour${h == 1 ? '' : 's'}';
    }

    final d = diff.inDays;
    return 'Unlock after ${d} day${d == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            // Background SVG
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/svg/more/scratch-card.svg',
                fit: BoxFit.cover,
                colorMapper: PurpleToAppColorMapper(AppColors.primary),              ),
            ),

            // Revealed overlay
            if (card.isScratched)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.38),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon(Icons.lock_open, color: Colors.white, size: 28.r),
                        // SizedBox(height: 6.h),
                        // Text(
                        //   'Revealed',
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontWeight: FontWeight.w700,
                        //     fontSize: 14.sp,
                        //   ),
                        // ),
                        SizedBox(height: 4.h),
                        if (card.rewardAmount != null &&
                            card.rewardAmount! > 0) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal:25.0),
                                  child: Container(
                                    height: 30.h,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.accentStatic,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                                    child: Text(
                                     '\$${card.rewardAmount!.toStringAsFixed(2)}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style:  AppTextStyles.scratchCardYellow
                                    ),
                                  ),
                                ),
                        
                        ] else
                          Text(
                            'No Reward',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

           
           
             
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCRATCH CARD DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ScratchCardDetailScreen extends StatelessWidget {
  final ScratchCardApiModel card;

  const ScratchCardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final listCtrl = Get.find<ScratchCardController>();
    final ctrl = Get.put(
      _ScratchGestureController(card),
      tag: 'scratch_${card.id}',
    );

    return Scaffold(
      backgroundColor: AppColors.tradeBackgroundCenterColor,
      appBar: AppBar(
        backgroundColor: AppColors.tradeBackgroundCenterColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'My Rewards',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: SvgPicture.asset("assets/svg/trade/arro_back.svg"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Hooray! 🎉',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6.h),
                Text(
                  "You've got a scratch card reward!",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 32.h),

                // ── Scratch Area ──
                Obx(() {
                  // Look up latest card state from controller to be reactive
                  final c =
                      listCtrl.cards.firstWhereOrNull(
                        (item) => item.id == card.id,
                      ) ??
                      card;

                  if (c.isScratched) {
                    // Already revealed from API — show result card
                    return _RevealedCard(card: c);
                  }
                  if (ctrl.hasTriggeredReveal.value) {
                    // User scratched ≥ 25% — call reveal API once
                    return _RevealingCard(
                      ctrl: ctrl,
                      listCtrl: listCtrl,
                      card: c,
                    );
                  }
                  return _ActiveScratchCard(ctrl: ctrl);
                }),

                SizedBox(height: 32.h),

                // Sub-text
                Obx(() {
                  final c =
                      listCtrl.cards.firstWhereOrNull(
                        (item) => item.id == card.id,
                      ) ??
                      card;
                  if (c.isScratched || ctrl.hasTriggeredReveal.value) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      Text(
                        'Scratch the card to reveal\nyour reward',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Scratch at least 25% to unlock your reward.\nCredited to your trading account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCRATCH CARD DIALOG (new flow – shown on top of the grid)
// ─────────────────────────────────────────────────────────────────────────────
class _ScratchCardDialog extends StatelessWidget {
  final ScratchCardApiModel card;
  const _ScratchCardDialog({required this.card});

  @override
  Widget build(BuildContext context) {
    final listCtrl = Get.find<ScratchCardController>();
    final ctrl = Get.put(
      _ScratchGestureController(card),
      tag: 'scratch_dialog_${card.id}',
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hooray! 🎉',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Text(
                "You've got a scratch card reward!",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18.h),

              // ── Scratch Area ──
              Obx(() {
                final c = listCtrl.cards.firstWhereOrNull(
                      (item) => item.id == card.id,
                    ) ??
                    card;

                if (c.isScratched) {
                  return _RevealedCard(card: c);
                }
                if (ctrl.hasTriggeredReveal.value) {
                  return _RevealingCard(
                    ctrl: ctrl,
                    listCtrl: listCtrl,
                    card: c,
                  );
                }
                return _ActiveScratchCard(ctrl: ctrl);
              }),

              SizedBox(height: 14.h),

              // Sub-text
              Obx(() {
                final c = listCtrl.cards.firstWhereOrNull(
                      (item) => item.id == card.id,
                    ) ??
                    card;
                if (c.isScratched || ctrl.hasTriggeredReveal.value) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    Text(
                      'Scratch the card to reveal\nyour reward',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Scratch at least 25% to unlock your reward.\nCredited to your trading account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.icongrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVEALING CARD — calls API right after scratch threshold
// ─────────────────────────────────────────────────────────────────────────────

class _RevealingCard extends StatefulWidget {
  final _ScratchGestureController ctrl;
  final ScratchCardController listCtrl;
  final ScratchCardApiModel card;

  const _RevealingCard({
    required this.ctrl,
    required this.listCtrl,
    required this.card,
  });

  @override
  State<_RevealingCard> createState() => _RevealingCardState();
}

class _RevealingCardState extends State<_RevealingCard> {
  bool _called = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _callRevealApi());
  }

  Future<void> _callRevealApi() async {
    if (_called) return;
    _called = true;
    final reveal = await widget.listCtrl.revealCard(widget.card.id);
    if (reveal != null && mounted) {
      widget.listCtrl._showRevealResultDialog(
        reveal,
        onDone: () {
          if (Get.isDialogOpen ?? false) Get.back(); // close dialog
          Get.back(); // close detail screen
          widget.listCtrl.fetchCards(); // Refresh list
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.listCtrl.isRevealing.value) {
        return SizedBox(
          width: 250.h,
          height: 250.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
              SizedBox(height: 16.h),
              Text(
                'Revealing your reward...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }
      // API done — show reward content (win or lose will be in dialog)
      return _RewardContent(rewardAmount: null, hasResult: false);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIVE SCRATCH CARD (SVG face on top, captured as PNG for Scratcher)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveScratchCard extends StatefulWidget {
  final _ScratchGestureController ctrl;
  const _ActiveScratchCard({required this.ctrl});

  @override
  State<_ActiveScratchCard> createState() => _ActiveScratchCardState();
}

class _ActiveScratchCardState extends State<_ActiveScratchCard> {
  final GlobalKey _svgRepaintKey = GlobalKey();
  Uint8List? _svgBytes;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureSvgImage());
  }

  Future<void> _captureSvgImage() async {
    if (_capturing || !mounted) return;
    _capturing = true;
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final boundary =
          _svgRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _capturing = false;
        return;
      }

      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();

      if (mounted && byteData != null) {
        setState(() => _svgBytes = byteData.buffer.asUint8List());
      }
    } catch (_) {
      _capturing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardHeight = 250.0;
    return Container(
      width: cardHeight.h,
      height: cardHeight.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Stack(
          children: [
            // ── LAYER 1 (bottom): Scratcher ──
            if (_svgBytes != null)
              Positioned.fill(
                child: Scratcher(
                  key: widget.ctrl.scratchKey,
                  accuracy: ScratchAccuracy.low,
                  brushSize: 44,
                  threshold: 100,
                  color: Colors.transparent,
                  image: Image.memory(_svgBytes!, fit: BoxFit.cover),
                  onChange: widget.ctrl.onProgress,
                  onScratchEnd: widget.ctrl.onScratchEnd,
                  child: _RewardContent(rewardAmount: null, hasResult: false),
                ),
              ),

            // ── LAYER 2 (top): SVG overlay — fades out when bytes ready ──
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _svgBytes != null,
                child: AnimatedOpacity(
                  opacity: _svgBytes == null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: RepaintBoundary(
                    key: _svgRepaintKey,
                    child: const _ScratchCoverFace(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SVG cover face
class _ScratchCoverFace extends StatelessWidget {
  const _ScratchCoverFace();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/more/scratch_pop.svg',
      fit: BoxFit.cover,
    );
  }
}

// Reward content (shown beneath the scratch layer)
class _RewardContent extends StatelessWidget {
  final double? rewardAmount;
  final bool hasResult;
  const _RewardContent({required this.rewardAmount, required this.hasResult});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              color: Colors.yellow.shade300,
              size: 52.r,
            ),
            SizedBox(height: 10.h),
            Text(
              hasResult && rewardAmount != null
                  ? '\$${rewardAmount!.toStringAsFixed(2)}'
                  : '???',
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.w900,
                color: Colors.yellow.shade300,
                shadows: [
                  Shadow(
                    blurRadius: 12,
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              hasResult ? 'Reward Unlocked!' : 'Scratch to reveal',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REVEALED CARD (already scratched — shown in detail screen)
// ─────────────────────────────────────────────────────────────────────────────

class _RevealedCard extends StatelessWidget {
  final ScratchCardApiModel card;

  const _RevealedCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final isWin = card.rewardAmount != null && card.rewardAmount! > 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 250.h,
        height: 250.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isWin
                    ? [AppColors.primary, AppColors.primary.withOpacity(0.7)]
                    : [Colors.grey.shade400, Colors.grey.shade600],
          ),
          boxShadow: [
            BoxShadow(
              color: (isWin ? AppColors.primary : Colors.grey).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWin
                    ? Icons.emoji_events_rounded
                    : Icons.sentiment_dissatisfied_rounded,
                color: isWin ? Colors.yellow.shade300 : Colors.white.withOpacity(0.7),
                size: 52.r,
              ),
              SizedBox(height: 10.h),
              if (isWin)
                Text(
                  '\$${card.rewardAmount!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.yellow.shade300,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Better luck\nnext time!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              SizedBox(height: 8.h),
              Text(
                isWin ? 'Reward Unlocked!' : 'No reward this time',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIN RESULT DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _WinResultDialog extends StatelessWidget {
  final ScratchCardRevealModel reveal;
  final VoidCallback onDone;

  const _WinResultDialog({required this.reveal, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.yellow.shade300.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: Colors.yellow.shade300,
                size: 48.r,
              ),
            ),
            SizedBox(height: 20.h),

            Text(
              'Congratulations! 🎉',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            Text(
              'You won',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 6.h),

            Container(
              width: 170.w,
              height: 88.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.75),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 34.r,
                      color: Colors.yellow.shade300,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '\$${reveal.rewardAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Credit status
            _CreditStatusBadge(reveal: reveal),

            SizedBox(height: 24.h),

            // Done button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreditStatusBadge extends StatelessWidget {
  final ScratchCardRevealModel reveal;
  const _CreditStatusBadge({required this.reveal});

  @override
  Widget build(BuildContext context) {
    if (reveal.isCreditFailed) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.red.shade400.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange.shade200,
              size: 16.r,
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                'Credit failed: ${reveal.creditError.isNotEmpty ? reveal.creditError : 'Please contact support'}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.orange.shade200,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final label =
        reveal.creditStatus == 'credited'
            ? '✓ Credited to your trading account'
            : 'Pending — will be credited shortly';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOSE RESULT DIALOG
// ─────────────────────────────────────────────────────────────────────────────

class _LoseResultDialog extends StatelessWidget {
  final VoidCallback onDone;
  const _LoseResultDialog({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.r),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sentiment_dissatisfied_rounded,
                color: Colors.grey.shade400,
                size: 40.r,
              ),
            ),
            SizedBox(height: 20.h),

            Text(
              'Better Luck Next Time!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),

            Text(
              'No reward this time.\nNew cards are released every 12 hours — keep scratching!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE SCRATCH ACCOUNT DIALOG  (shows on 409 SCRATCH_ACCOUNT_REQUIRED)
// ─────────────────────────────────────────────────────────────────────────────

class _CreateScratchAccountDialog extends StatefulWidget {
  const _CreateScratchAccountDialog();

  @override
  State<_CreateScratchAccountDialog> createState() =>
      _CreateScratchAccountDialogState();
}

class _CreateScratchAccountDialogState
    extends State<_CreateScratchAccountDialog> {
  final _mainPwCtrl = TextEditingController();
  final _investorPwCtrl = TextEditingController();
  bool _showMainPw = false;
  bool _showInvestorPw = false;
  String? _error;

  @override
  void dispose() {
    _mainPwCtrl.dispose();
    _investorPwCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);

    final main = _mainPwCtrl.text.trim();
    final investor = _investorPwCtrl.text.trim();

    if (main.isEmpty) {
      setState(() => _error = 'Main password is required');
      return;
    }
    if (investor.isEmpty) {
      setState(() => _error = 'Investor password is required');
      return;
    }
    if (main == investor) {
      setState(() => _error = 'Main and investor passwords cannot be the same');
      return;
    }

    final ctrl = Get.find<ScratchCardController>();
    ctrl.createScratchAccount(mainPassword: main, investorPassword: investor);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ScratchCardController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.primary,
                    size: 22.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Scratch Account',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Required to scratch and reveal rewards',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Main password
            Text(
              'Main Password',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6.h),
            _PasswordField(
              controller: _mainPwCtrl,
              hint: 'Enter main password',
              obscure: !_showMainPw,
              onToggle: () => setState(() => _showMainPw = !_showMainPw),
            ),
            SizedBox(height: 14.h),

            // Investor password
            Text(
              'Investor Password',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6.h),
            _PasswordField(
              controller: _investorPwCtrl,
              hint: 'Enter investor password',
              obscure: !_showInvestorPw,
              onToggle:
                  () => setState(() => _showInvestorPw = !_showInvestorPw),
            ),

            // Error
            if (_error != null) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 14.r),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 12.sp, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 22.h),

            // Buttons
            Obx(() {
              final loading = ctrl.isCreatingAccount.value;
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: loading ? null : () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 0,
                      ),
                      child:
                          loading
                              ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                'Create',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade400,
            size: 20.r,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SVG COLOR MAPPER (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class PurpleToAppColorMapper extends ColorMapper {
  final Color targetColor;
  const PurpleToAppColorMapper(this.targetColor);

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final opaqueHex =
        color
            .withOpacity(1.0)
            .value
            .toRadixString(16)
            .substring(2)
            .toUpperCase();

    final isPurple =
        opaqueHex == '461872' ||
        opaqueHex == '5C288E' ||
        opaqueHex == 'B96BDE' ||
        opaqueHex == '9D63D8';

    if (opaqueHex == '7E41B8') {
      return AppColors.primary.withOpacity(0.9);
    }
    if (isPurple) {
      return AppColors.primary.withOpacity(0.7);
    }
    return color;
  }
}
