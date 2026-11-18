import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds the toolbar across the top of the landscape page.
/// [openSymbolPicker] slides the in-page symbol picker in.
typedef LandscapeToolbarBuilder =
    Widget Function(BuildContext context, VoidCallback openSymbolPicker);

/// Builds the content of the in-page symbol picker.
typedef LandscapePickerBuilder =
    Widget Function(BuildContext context, VoidCallback closePicker);

const Duration landscapeSwingDuration = Duration(milliseconds: 380);
const Duration landscapeCoverFadeDuration = Duration(milliseconds: 250);
const Duration landscapeChartRedrawDelay = Duration(milliseconds: 300);
const Duration landscapeHandBackDelay = Duration(milliseconds: 150);
const Duration landscapePickerDuration = Duration(milliseconds: 220);

// Notifiers whose landscape page is on screen, so a double tap cannot push a
// second page before the first one has flipped `isOpen`.
final Set<ValueNotifier<bool>> _activeLandscapePages = <ValueNotifier<bool>>{};

/// Shows the chart full screen in landscape WITHOUT rotating the device.
///
/// Rotating the device makes Android resize the window (and again when the
/// system bars hide), and the chart WebView paints black wherever it has not
/// redrawn yet. So the app stays portrait and the page is laid out landscape
/// inside a [LandscapeViewport].
///
/// The chart widget is shared with the portrait screen through [isOpen]: the
/// portrait screen must build the chart only while `isOpen.value` is false and
/// this page only while it is true. It flips to true once the opening swing
/// has finished, so the chart is never on screen while it turns or resizes.
Future<void> openLandscapeChartPage({
  required BuildContext context,
  required ValueNotifier<bool> isOpen,
  required Color backgroundColor,
  required WidgetBuilder chartBuilder,
  required LandscapeToolbarBuilder toolbarBuilder,
  LandscapePickerBuilder? symbolPickerBuilder,
  WidgetBuilder? overlayBuilder,
}) async {
  if (_activeLandscapePages.contains(isOpen) || isOpen.value) return;
  _activeLandscapePages.add(isOpen);

  final route = PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: landscapeSwingDuration,
    reverseTransitionDuration: landscapeSwingDuration,
    pageBuilder:
        (_, _, _) => LandscapeViewport(
          child: LandscapeChartPage(
            isOpen: isOpen,
            backgroundColor: backgroundColor,
            chartBuilder: chartBuilder,
            toolbarBuilder: toolbarBuilder,
            symbolPickerBuilder: symbolPickerBuilder,
            overlayBuilder: overlayBuilder,
          ),
        ),
    transitionsBuilder:
        (_, animation, _, child) => _LandscapeSwing(
          animation: animation,
          backgroundColor: backgroundColor,
          child: child,
        ),
  );

  Navigator.of(context, rootNavigator: true).push(route);
  final animation = route.animation!;
  void onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      isOpen.value = true;
    } else if (status == AnimationStatus.reverse) {
      _restoreSystemBars();
    }
  }

  animation.addStatusListener(onStatusChanged);
  try {
    await route.completed;
  } finally {
    animation.removeStatusListener(onStatusChanged);
    _activeLandscapePages.remove(isOpen);
    // The route can be removed without its exit animation (e.g. the whole
    // stack is replaced); hand the chart back to the portrait screen anyway.
    if (isOpen.value) isOpen.value = false;
    _restoreSystemBars();
  }
}

void _restoreSystemBars() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
}

/// Lays [child] out as a landscape screen inside a portrait-locked app:
/// turned a quarter clockwise, with a [MediaQuery] that reports the flipped
/// size and insets.
class LandscapeViewport extends StatelessWidget {
  const LandscapeViewport({super.key, required this.child});

  final Widget child;

  // Quarter turn clockwise: the page's left edge sits at the screen top, its
  // top at the screen right, its right at the bottom and its bottom at the left.
  static EdgeInsets _turn(EdgeInsets insets) =>
      EdgeInsets.fromLTRB(insets.top, insets.right, insets.bottom, insets.left);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return RotatedBox(
      quarterTurns: 1,
      child: MediaQuery(
        data: media.copyWith(
          size: media.size.flipped,
          padding: _turn(media.padding),
          viewPadding: _turn(media.viewPadding),
          systemGestureInsets: _turn(media.systemGestureInsets),
          viewInsets: EdgeInsets.zero,
        ),
        child: child,
      ),
    );
  }
}

/// At 0 the landscape page lies flat, shrunk to the screen width; at 1 it has
/// turned a quarter clockwise and fills the screen.
class _LandscapeSwing extends StatelessWidget {
  const _LandscapeSwing({
    required this.animation,
    required this.backgroundColor,
    required this.child,
  });

  final Animation<double> animation;
  final Color backgroundColor;
  final Widget child;

  static const Interval _fade = Interval(0, 0.3, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final startScale = screen.width / screen.height;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, page) {
        final value = animation.value;
        final t = Curves.easeInOutCubic.transform(value);
        final opacity = _fade.transform(value);
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: opacity, child: ColoredBox(color: backgroundColor)),
            Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: -(1 - t) * math.pi / 2,
                child: Transform.scale(
                  scale: lerpDouble(startScale, 1, t)!,
                  child: page,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class LandscapeChartPage extends StatefulWidget {
  const LandscapeChartPage({
    super.key,
    required this.isOpen,
    required this.backgroundColor,
    required this.chartBuilder,
    required this.toolbarBuilder,
    this.symbolPickerBuilder,
    this.overlayBuilder,
  });

  static const Key chartCoverKey = ValueKey('landscape-chart-cover');
  static const Key symbolPickerKey = ValueKey('landscape-symbol-picker');

  final ValueNotifier<bool> isOpen;
  final Color backgroundColor;
  final WidgetBuilder chartBuilder;
  final LandscapeToolbarBuilder toolbarBuilder;
  final LandscapePickerBuilder? symbolPickerBuilder;
  final WidgetBuilder? overlayBuilder;

  @override
  State<LandscapeChartPage> createState() => _LandscapeChartPageState();
}

class _LandscapeChartPageState extends State<LandscapeChartPage> {
  Timer? _revealTimer;
  bool _isRevealed = false;
  bool _isClosing = false;
  bool _isPickerOpen = false;

  @override
  void initState() {
    super.initState();
    widget.isOpen.addListener(_onOpenChanged);
    _onOpenChanged();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    widget.isOpen.removeListener(_onOpenChanged);
    super.dispose();
  }

  // The chart has just been moved into this page; give the WebView time to
  // redraw at its new size before the cover fades off it.
  void _onOpenChanged() {
    if (!widget.isOpen.value || _isClosing || _isRevealed) return;
    _revealTimer?.cancel();
    _revealTimer = Timer(landscapeChartRedrawDelay, () {
      if (mounted && !_isClosing) setState(() => _isRevealed = true);
    });
  }

  // Cover the chart, hand it back to the portrait screen behind this page,
  // let it redraw there, then swing out.
  Future<void> _close() async {
    if (_isClosing) return;
    _revealTimer?.cancel();
    setState(() {
      _isClosing = true;
      _isRevealed = false;
    });

    await Future<void>.delayed(landscapeCoverFadeDuration);
    if (!mounted) return;
    widget.isOpen.value = false;

    await Future<void>.delayed(landscapeHandBackDelay);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _openPicker() {
    if (widget.symbolPickerBuilder == null || _isClosing) return;
    setState(() => _isPickerOpen = true);
  }

  void _closePicker() {
    if (_isPickerOpen) setState(() => _isPickerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isPickerOpen) {
          _closePicker();
        } else {
          _close();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: widget.backgroundColor,
        body: Stack(
          children: [
            SafeArea(
              top: false,
              bottom: false,
              child: Column(
                // Stretch so the toolbar and chart span the full page width.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.toolbarBuilder(context, _openPicker),
                  Expanded(child: _buildChartSlot()),
                ],
              ),
            ),
            if (widget.overlayBuilder != null) widget.overlayBuilder!(context),
            if (widget.symbolPickerBuilder != null) ..._buildPickerLayers(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSlot() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: widget.isOpen,
          builder:
              (context, isOpen, _) =>
                  isOpen ? widget.chartBuilder(context) : const SizedBox.shrink(),
        ),
        // The chart is a platform view: hide it behind an opaque cover while
        // it moves or redraws instead of animating its own opacity.
        IgnorePointer(
          child: AnimatedOpacity(
            key: LandscapeChartPage.chartCoverKey,
            opacity: _isRevealed ? 0 : 1,
            duration: landscapeCoverFadeDuration,
            curve: Curves.easeInOut,
            child: ColoredBox(color: widget.backgroundColor),
          ),
        ),
      ],
    );
  }

  // Built inside the page: dialogs and sheets would open outside the
  // LandscapeViewport, in portrait.
  List<Widget> _buildPickerLayers() {
    return [
      Positioned.fill(
        child: IgnorePointer(
          ignoring: !_isPickerOpen,
          child: AnimatedOpacity(
            opacity: _isPickerOpen ? 1 : 0,
            duration: landscapePickerDuration,
            child: GestureDetector(
              onTap: _closePicker,
              child: const ColoredBox(color: Colors.black54),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        bottom: 0,
        width: 300,
        child: IgnorePointer(
          ignoring: !_isPickerOpen,
          child: AnimatedSlide(
            key: LandscapeChartPage.symbolPickerKey,
            offset: _isPickerOpen ? Offset.zero : const Offset(1, 0),
            duration: landscapePickerDuration,
            curve: Curves.easeOutCubic,
            child: Material(
              color: widget.backgroundColor,
              child: SafeArea(
                left: false,
                child: widget.symbolPickerBuilder!(context, _closePicker),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
