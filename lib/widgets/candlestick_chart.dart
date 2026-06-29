import 'package:candlesticks/candlesticks.dart';
import 'package:crm_app/models/candle_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Wraps the third-party `candlesticks` package's [Candlesticks] widget with
/// the project's [CandleStyle] and a sensible default
/// [CandlesticksController].
class CandlestickChart extends StatefulWidget {
  /// Candles in newest-first order, exactly as required by `candlesticks`.
  final List<Candle> candles;

  /// Visual style. When null, the package picks from the current theme.
  final CandleStyle style;

  /// Optional externally-owned controller (for programmatic zoom/scroll).
  /// When null, the widget manages its own.
  final CandlesticksController? controller;

  /// Called when the user scrolls near the oldest loaded candle. The
  /// aggregator does not currently support fetching older candles (the
  /// backend does not expose OHLC history), so this is a no-op by default.
  final Future<void> Function()? onLoadMoreCandles;

  /// Custom loading widget shown when [candles] is empty.
  final Widget? loadingWidget;

  /// If true (default), the chart is automatically switched to linear price
  /// scale on first paint by tapping the package's hidden "L" toggle button.
  /// This is a workaround for the package defaulting to log scale (which
  /// makes 1.32-anchored pairs render Y-axis labels 0.1/1/10/100 and crush
  /// the candles to a flat line).
  final bool forceLinearScale;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.style = const CandleStyle(),
    this.controller,
    this.onLoadMoreCandles,
    this.loadingWidget,
    this.forceLinearScale = true,
  });

  @override
  State<CandlestickChart> createState() => CandlestickChartState();
}

class CandlestickChartState extends State<CandlestickChart> {
  late final CandlesticksController _internalController;

  /// Key attached to the inner [Candlesticks] widget so we can walk the
  /// render tree to find its internal "L" / linear-scale toggle button.
  final GlobalKey _chartKey = GlobalKey();

  /// True once we have auto-tapped the linear-scale button. Prevents
  /// re-tapping on every rebuild.
  bool _scaleToggled = false;

  @override
  void initState() {
    super.initState();
    _internalController = CandlesticksController();
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  /// Public API: switch the underlying package chart to linear price scale
  /// by dispatching a synthetic tap on its internal "L" button. Safe to call
  /// multiple times — only the first call per build does work.
  void forceLinearScaleOnce() {
    if (_scaleToggled) return;
    _scaleToggled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tapLinearScaleButton();
    });
  }

  /// Public API: reset the linear-scale latch so the next call to
  /// [forceLinearScaleOnce] will re-tap the package's L button. Use this
  /// when the symbol changes so the package's chart state is normalised
  /// for the new price range.
  void resetLinearScaleLatch() {
    _scaleToggled = false;
  }

  void _tapLinearScaleButton() {
    if (!mounted) return;
    final ctx = _chartKey.currentContext;
    if (ctx == null) return;

    // Walk the element tree to find the package's internal "L" button. The
    // package renders it as an ElevatedButton whose child is a Text widget
    // with data == "L", sitting in a Row at the bottom-right corner of the
    // chart (22x22 hit target).
    BuildContext? buttonCtx;
    void visitElement(Element el) {
      if (buttonCtx != null) return;
      el.visitChildren(visitElement);
      final w = el.widget;
      if (w is ElevatedButton) {
        final child = w.child;
        if (child is Text && (child.data == 'L' || child.data == 'l')) {
          buttonCtx = el;
        }
      }
    }

    visitElement(ctx as Element);
    if (buttonCtx == null) return;

    final box = buttonCtx!.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));

    // Dispatch a raw pointer tap on the button's centre. The package's
    // ElevatedButton listens via the standard gesture arena, so a synthetic
    // PointerDown + PointerUp pair at the centre of the hit target is
    // enough to trigger its onPressed callback (which is what
    // onPriceScaleToggle is wired to).
    final down = PointerDownEvent(
      pointer: 0,
      position: center,
      kind: PointerDeviceKind.touch,
    );
    final up = PointerUpEvent(
      pointer: 0,
      position: center,
      kind: PointerDeviceKind.touch,
    );
    GestureBinding.instance.handlePointerEvent(down);
    GestureBinding.instance.handlePointerEvent(up);
  }

  @override
  Widget build(BuildContext context) {
    // The candlesticks widget requires at least 2 candles or an empty list
    // to show the loading widget. We bridge the bootstrap gap by padding
    // with the latest candle duplicated when only 1 is available.
    final candles = widget.candles.length == 1
        ? <Candle>[widget.candles.first, widget.candles.first]
        : widget.candles;

    return KeyedSubtree(
      key: _chartKey,
      child: Candlesticks(
        candles: candles,
        style: widget.style.style,
        controller: widget.controller,
        onLoadMoreCandles: widget.onLoadMoreCandles,
        loadingWidget:
            widget.loadingWidget ??
            Center(
              child: CircularProgressIndicator(
                color: widget.style.style?.loadingIndicatorColor,
              ),
            ),
      ),
    );
  }
}