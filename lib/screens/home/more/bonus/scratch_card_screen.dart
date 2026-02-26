import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:scratcher/scratcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_app/constants/color.dart';

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────
class ScratchCardModel {
  final String id;
  final String reward;
  final String expiresOn;
  bool isRevealed;

  ScratchCardModel({
    required this.id,
    required this.reward,
    required this.expiresOn,
    this.isRevealed = false,
  });

  String get prefKey => 'scratch_revealed_$id';
}

// ─────────────────────────────────────────────
// CONTROLLER
// ─────────────────────────────────────────────
class ScratchCardListController extends GetxController {
  RxList<ScratchCardModel> cards = <ScratchCardModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final rawCards = [
      ScratchCardModel(id: '1', reward: '₹100', expiresOn: '16th Sep'),
      ScratchCardModel(id: '2', reward: '₹250', expiresOn: '20th Sep'),
      ScratchCardModel(id: '3', reward: '₹50', expiresOn: '21st Sep'),
      ScratchCardModel(id: '4', reward: '₹500', expiresOn: '24th Sep'),
      ScratchCardModel(id: '5', reward: '₹75', expiresOn: '28th Sep'),
    ];
    for (final c in rawCards) {
      c.isRevealed = prefs.getBool(c.prefKey) ?? false;
    }
    cards.assignAll(rawCards);
  }

  void markRevealed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final idx = cards.indexWhere((c) => c.id == id);
    if (idx != -1) {
      cards[idx].isRevealed = true;
      await prefs.setBool(cards[idx].prefKey, true);
      cards.refresh();
    }
  }
}

// ─────────────────────────────────────────────
// SCRATCH CARD LIST SCREEN
// ─────────────────────────────────────────────
class ScratchCardListScreen extends StatelessWidget {
  const ScratchCardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScratchCardListController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
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
      ),
      body: Column(
        children: [
          // Total earnings banner
          Container(
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
                      'total_earnings',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Obx(() {
                      double total = 0;
                      for (final c in controller.cards) {
                        if (c.isRevealed) {
                          final parsed = double.tryParse(
                            c.reward.replaceAll('₹', '').replaceAll(',', ''),
                          );
                          if (parsed != null) total += parsed;
                        }
                      }
                      return Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      );
                    }),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: Obx(
              () => GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 0.85,
                ),
                itemCount: controller.cards.length,
                itemBuilder: (context, index) {
                  final card = controller.cards[index];
                  return _ScratchCardGridItem(
                    card: card,
                    onTap: () async {
                      await Get.to(
                        () => ScratchCardDetailScreen(card: card),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                      );
                      controller.cards.refresh();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScratchCardGridItem extends StatelessWidget {
  final ScratchCardModel card;
  final VoidCallback onTap;

  const _ScratchCardGridItem({required this.card, required this.onTap});

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
              ),
            ),

            // Revealed overlay
            if (card.isRevealed)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open, color: Colors.white, size: 28.r),
                        SizedBox(height: 6.h),
                        Text(
                          'Revealed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          card.reward,
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.w800,
                            fontSize: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Expiry label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Expires on: ${card.expiresOn}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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

// ─────────────────────────────────────────────
// PER-CARD SCRATCH CONTROLLER
// ─────────────────────────────────────────────
class _ScratchController extends GetxController {
  final ScratchCardModel card;

  _ScratchController(this.card);

  // 15% → trigger reveal on end-check
  static const double checkThreshold = 15.0;

  RxDouble progress = 0.0.obs;
  RxBool isRevealed = false.obs;
  RxBool isScratching = false.obs;

  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final scratchKey = GlobalKey<ScratcherState>();

  @override
  void onInit() {
    super.onInit();
    if (card.isRevealed) {
      isRevealed.value = true;
      progressNotifier.value = 1.0;
    }
  }

  void onProgress(double value) {
    progress.value = value;
    progressNotifier.value = value / 100.0;
    isScratching.value = true;
  }

  void onScratchEnd() {
    isScratching.value = false;
    if (progress.value >= checkThreshold) {
      _doReveal();
    }
    // We removed the reset here so the card does not refill if the user takes their hand off.
  }

  void _doReveal() {
    if (!isRevealed.value) {
      isRevealed.value = true;
      progressNotifier.value = 1.0;
      // Animate full reveal
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

// ─────────────────────────────────────────────
// SCRATCH CARD DETAIL SCREEN
// ─────────────────────────────────────────────
class ScratchCardDetailScreen extends StatelessWidget {
  final ScratchCardModel card;

  const ScratchCardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(_ScratchController(card), tag: card.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (ctrl.isRevealed.value) {
              // Persist to list controller if available
              if (Get.isRegistered<ScratchCardListController>()) {
                Get.find<ScratchCardListController>().markRevealed(card.id);
              }
            }
            Get.back();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 8.h),

              // Title
              Text(
                'Hooray!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "You've won a monthly scratch card",
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 24.h),

              // ─── Scratch Area ───
              Obx(() {
                if (ctrl.isRevealed.value) {
                  return _RevealedCard(card: card);
                }
                return _ActiveScratchCard(ctrl: ctrl);
              }),

              SizedBox(height: 24.h),

              // Subtitle
              Obx(() {
                if (ctrl.isRevealed.value) {
                  return Column(
                    children: [
                      Text(
                        'Congratulations! 🎉',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'You won ${card.reward}!',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    Text(
                      'Scratch the card to reveal\nyour reward',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your reward will be credited to your\nBeem Balance within 48 hours',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              }),

              SizedBox(height: 32.h),

              // Progress hint
              Obx(() {
                if (ctrl.isRevealed.value) return const SizedBox.shrink();
                return ValueListenableBuilder<double>(
                  valueListenable: ctrl.progressNotifier,
                  builder: (_, val, __) {
                    final pct = (val * 100).toStringAsFixed(0);
                    return Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: LinearProgressIndicator(
                              value: val,
                              minHeight: 6.h,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),

              SizedBox(height: 28.h),

              // Redeem button
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed:
                        ctrl.isRevealed.value
                            ? () {
                              if (Get.isRegistered<
                                ScratchCardListController
                              >()) {
                                Get.find<ScratchCardListController>()
                                    .markRevealed(card.id);
                              }
                              Get.back();
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          ctrl.isRevealed.value
                              ? AppColors.primary
                              : Colors.grey.shade300,
                      foregroundColor:
                          ctrl.isRevealed.value
                              ? Colors.white
                              : Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: ctrl.isRevealed.value ? 2 : 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (ctrl.isRevealed.value)
                          Icon(Icons.play_arrow, size: 20.sp)
                        else
                          Icon(
                            Icons.play_arrow,
                            size: 20.sp,
                            color: Colors.grey.shade400,
                          ),
                        SizedBox(width: 8.w),
                        Text(
                          'Redeem reward',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ACTIVE SCRATCH CARD WIDGET (SVG face on top, reward revealed below)
// ─────────────────────────────────────────────
class _ActiveScratchCard extends StatefulWidget {
  final _ScratchController ctrl;

  const _ActiveScratchCard({required this.ctrl});

  @override
  State<_ActiveScratchCard> createState() => _ActiveScratchCardState();
}

class _ActiveScratchCardState extends State<_ActiveScratchCard> {
  final GlobalKey _svgRepaintKey = GlobalKey();
  Uint8List? _svgBytes; // PNG bytes of the captured SVG
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    // Capture the on-screen SVG after flutter_svg has decoded & painted it
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureSvgImage());
  }

  Future<void> _captureSvgImage() async {
    if (_capturing || !mounted) return;
    _capturing = true;
    try {
      // 300ms: enough time for flutter_svg to decode the asset on first paint
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final boundary =
          _svgRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        _capturing = false;
        return;
      }

      // Capture the visible SVG widget as a ui.Image then convert to PNG bytes.
      // PNG bytes load via Image.memory much faster than any custom ImageProvider.
      final img = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose(); // free native memory

      if (mounted && byteData != null) {
        setState(() => _svgBytes = byteData.buffer.asUint8List());
      }
    } catch (_) {
      _capturing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardHeight = 300.0;

    return Container(
      width: double.infinity,
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
            // ── LAYER 1 (bottom): Scratcher — mounts as soon as bytes ready.
            //    Uses Image.memory for near-instant RAM decode (no async pipeline
            //    overhead like custom ImageProviders). ──
            if (_svgBytes != null)
              Positioned.fill(
                child: Scratcher(
                  key: widget.ctrl.scratchKey,
                  accuracy: ScratchAccuracy.low,
                  brushSize: 44,
                  threshold: 100,
                  // SVG bytes are the scratch COVER; transparent base is fine
                  // because Image.memory fully covers the surface.
                  color: Colors.transparent,
                  image: Image.memory(_svgBytes!, fit: BoxFit.cover),
                  onChange: widget.ctrl.onProgress,
                  onScratchEnd: widget.ctrl.onScratchEnd,
                  child: _RewardContent(ctrl: widget.ctrl),
                ),
              ),

            // ── LAYER 2 (top): SVG overlay — always visible from frame 0.
            //    Once bytes are ready the overlay fades out over 400ms.
            //    This 400ms window covers the time Image.memory needs to decode,
            //    so the Scratcher's cover is fully loaded before overlay is gone.
            //    Result: ZERO blank flash at any point. ──
            IgnorePointer(
              // Pass touches through to Scratcher once overlay is fading out
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
          ],
        ),
      ),
    );
  }
}

// SVG card face — shown as the scratch COVER (what you scratch away).
// Pure SVG only: no text, no icons — clean card design the user scratches away.
class _ScratchCoverFace extends StatelessWidget {
  const _ScratchCoverFace();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/more/scratch-card.svg',
      fit: BoxFit.cover,
    );
  }
}

// Reward content shown BELOW (revealed when you scratch the SVG away)
class _RewardContent extends StatelessWidget {
  final _ScratchController ctrl;
  const _RewardContent({required this.ctrl});

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
              size: 56.r,
            ),
            SizedBox(height: 12.h),
            Text(
              ctrl.card.reward,
              style: TextStyle(
                fontSize: 44.sp,
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
              'Reward Unlocked!',
              style: TextStyle(
                fontSize: 16.sp,
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

// ─────────────────────────────────────────────
// REVEALED CARD
// ─────────────────────────────────────────────
class _RevealedCard extends StatelessWidget {
  final ScratchCardModel card;

  const _RevealedCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: double.infinity,
        height: 300.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative SVG in the background, faded
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: SvgPicture.asset(
                  'assets/svg/more/scratch-card.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 52.r,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    card.reward,
                    style: TextStyle(
                      fontSize: 44.sp,
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
                    'Reward Unlocked!',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
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
