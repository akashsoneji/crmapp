// Unit tests for the OHLC aggregation logic inside LiveCandleAggregator.
//
// We test the public API (start / onTick behavior through the broadcast
// stream) using a stub ChartSocketController to keep the test hermetic.

import 'dart:async';

import 'package:candlesticks/candlesticks.dart';
import 'package:crm_app/models/candle.dart';
import 'package:crm_app/services/live_candle_aggregator.dart';
import 'package:crm_app/controllers/chart_socket_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight test double for [ChartSocketController] that exposes only the
/// surface [LiveCandleAggregator] uses: `priceStream` and `getCurrentPrice`.
///
/// We register this in GetX *before* constructing the aggregator so that the
/// aggregator's `_chartSocket` field is initialized against it instead of the
/// real controller.
class _StubChartSocketController extends GetxController
    implements ChartSocketController {
  final _ctrl = StreamController<Map<String, dynamic>>.broadcast();
  Map<String, dynamic>? _seed;

  void push(Map<String, dynamic> tick) => _ctrl.add(tick);
  void seed(Map<String, dynamic> tick) => _seed = tick;
  @override
  Stream<Map<String, dynamic>> get priceStream => _ctrl.stream;
  @override
  Map<String, dynamic>? getCurrentPrice() => _seed;

  // Unused ChartSocketController API — throw if a test hits them.
  @override
  noSuchMethod(Invocation i) =>
      throw UnimplementedError('stub: ${i.memberName}');

  @override
  void onClose() => _ctrl.close();
}

void main() {
  late _StubChartSocketController stub;

  setUp(() async {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();
    stub = _StubChartSocketController();
    // Register under BOTH the stub type and the ChartSocketController type so
    // the aggregator's `Get.find<ChartSocketController>()` finds it.
    Get.put<_StubChartSocketController>(stub, permanent: true);
    Get.put<ChartSocketController>(stub, permanent: true);
  });

  tearDown(Get.reset);

  test('start emits a snapshot with the seed price as the first candle', () async {
    stub.seed({'symbol': 'XAUUSD', 'bid': 1900.0, 'ask': 1900.5});

    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);

    final snapshot = <List<Candle>>[];
    final sub = agg.updates.listen((u) {
      if (u.kind == AggregatorEventKind.snapshot) snapshot.add(u.candles);
    });

    final candles = await agg.start('XAUUSD', 60);
    // Let microtasks settle.
    await Future<void>.delayed(Duration.zero);

    expect(candles, isNotEmpty);
    expect(snapshot, isNotEmpty, reason: 'should emit at least one snapshot');
    final c = snapshot.last.first;
    expect(c.open, closeTo(1900.25, 0.0001));
    expect(c.high, closeTo(1900.25, 0.0001));
    expect(c.low, closeTo(1900.25, 0.0001));
    expect(c.close, closeTo(1900.25, 0.0001));

    await sub.cancel();
  });

  test('ticks in the same bucket update OHLC in place and tickUpdate emits',
      () async {
    stub.seed({'symbol': 'EURUSD', 'bid': 1.10, 'ask': 1.10020});

    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('EURUSD', 60);

    final updates = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updates.add);

    stub.push({'symbol': 'EURUSD', 'bid': 1.10, 'ask': 1.10020});
    stub.push({'symbol': 'EURUSD', 'bid': 1.101, 'ask': 1.1012});
    stub.push({'symbol': 'EURUSD', 'bid': 1.099, 'ask': 1.0992});

    // Wait beyond the 50 ms tick debounce.
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(updates.where((u) => u.kind == AggregatorEventKind.tickUpdate),
        isNotEmpty,
        reason: 'expected at least one tickUpdate event');

    final c = agg.candles.first;
    expect(c.high, greaterThanOrEqualTo(1.101));
    expect(c.low, lessThanOrEqualTo(1.0991));

    await sub.cancel();
  });

  test('pause stops tick processing; resume restarts it', () async {
    stub.seed({'symbol': 'XAUUSD', 'bid': 1900, 'ask': 1901});

    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('XAUUSD', 60);

    agg.pause();
    expect(agg.isPaused, isTrue);

    final updatesDuringPause = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updatesDuringPause.add);

    stub.push({'symbol': 'XAUUSD', 'bid': 1950, 'ask': 1951});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(updatesDuringPause, isEmpty,
        reason: 'paused aggregator must not emit');

    agg.resume();
    expect(agg.isPaused, isFalse);

    stub.push({'symbol': 'XAUUSD', 'bid': 1960, 'ask': 1961});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(updatesDuringPause.where((u) => u.kind == AggregatorEventKind.tickUpdate),
        isNotEmpty,
        reason: 'after resume, ticks should be processed again');

    await sub.cancel();
  });

  test('symbol filter ignores ticks for other symbols', () async {
    stub.seed({'symbol': 'XAUUSD', 'bid': 1900, 'ask': 1901});

    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('XAUUSD', 60);

    final updates = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updates.add);

    stub.push({'symbol': 'EURUSD', 'bid': 1.05, 'ask': 1.06});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(updates, isEmpty,
        reason: 'tick for a different symbol must be ignored');

    await sub.cancel();
  });

  test('symbol with suffix matches base symbol', () async {
    stub.seed({'symbol': 'XAUUSD.c', 'bid': 1900, 'ask': 1901});

    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('XAUUSD', 60);

    final updates = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updates.add);

    stub.push({'symbol': 'XAUUSD.r', 'bid': 1950, 'ask': 1951});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(updates.where((u) => u.kind == AggregatorEventKind.tickUpdate),
        isNotEmpty,
        reason: 'suffix variants should still match base symbol');

    await sub.cancel();
  });
  test('no seed: emits snapshot on first tick (not empty snapshot)', () async {
    // No seed price.
    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('GBPUSD', 60);

    final updates = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updates.add);

    // No snapshot yet (no seed + no buffer).
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(updates, isEmpty,
        reason: 'must NOT emit empty snapshot before first tick');

    // First tick should bootstrap a candle + emit a snapshot.
    stub.push({'symbol': 'GBPUSD', 'bid': 1.27, 'ask': 1.2702});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(updates.where((u) => u.kind == AggregatorEventKind.snapshot),
        isNotEmpty,
        reason: 'first tick should emit a snapshot to unblock loading state');
    expect(agg.candles, isNotEmpty,
        reason: 'candles should be populated after bootstrap tick');

    await sub.cancel();
  });

  test('subsequent ticks after bootstrap emit tickUpdate only', () async {
    stub.seed({'symbol': 'USDJPY', 'bid': 150.0, 'ask': 150.02});

    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('USDJPY', 60);

    final updates = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updates.add);

    // Note: the seed snapshot is emitted inside start() before the listener
    // attaches, so we only observe post-bootstrap ticks here.
    stub.push({'symbol': 'USDJPY', 'bid': 150.5, 'ask': 150.52});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final tickUpdates = updates
        .where((u) => u.kind == AggregatorEventKind.tickUpdate)
        .length;

    expect(tickUpdates, greaterThanOrEqualTo(1),
        reason: 'post-bootstrap ticks should produce tickUpdate events');

    await sub.cancel();
  });

  test('cold start: first tick mints synthetic backfill candles', () async {
    // No seed price.
    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('EURUSD', 60);

    final updates = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updates.add);

    // No snapshot yet (no seed + no buffer).
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(updates, isEmpty);

    // First tick triggers snapshot.
    stub.push({'symbol': 'EURUSD', 'bid': 1.10, 'ask': 1.1002});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final snapshot = updates
        .where((u) => u.kind == AggregatorEventKind.snapshot)
        .first;
    // Backfill produces 30 candles + 1 in-progress = 31.
    expect(snapshot.candles.length, greaterThanOrEqualTo(30),
        reason: 'cold start should backfill 30 synthetic candles');
    // All backfill candles should be near 1.10 (within ~0.5% drift).
    for (final c in snapshot.candles.skip(1)) {
      // skip index 0 which is the in-progress live tick
      expect(c.close, closeTo(1.10, 0.01),
          reason: 'backfill candles should anchor around first tick price');
    }
    // The very last candle (oldest backfill) should still be in range.
    final last = snapshot.candles.last;
    expect(last.high, greaterThan(last.low),
        reason: 'backfill candles should have visible H/L wicks');

    await sub.cancel();
  });

  test('symbol change: emits empty snapshot to clear chart, then bootstraps new symbol',
      () async {
    // Start with GBPUSD and seed it.
    stub.seed({'symbol': 'GBPUSD', 'bid': 1.32, 'ask': 1.3202});
    final agg = LiveCandleAggregator();
    Get.put<LiveCandleAggregator>(agg, permanent: true);
    await agg.start('GBPUSD', 60);
    expect(agg.candles, isNotEmpty);

    final updates = <AggregatorUpdate>[];
    final sub = agg.updates.listen(updates.add);

    // Switch to EURUSD. The socket still has GBPUSD cached as
    // getCurrentPrice() — but the aggregator must NOT seed the new
    // bucket with the stale GBPUSD price.
    await agg.start('EURUSD', 60);

    // First emitted event should be an empty snapshot that clears the
    // chart.
    final snapshots = updates
        .where((u) => u.kind == AggregatorEventKind.snapshot)
        .toList();
    expect(snapshots, isNotEmpty,
        reason: 'symbol switch should emit at least one snapshot');
    expect(snapshots.first.candles, isEmpty,
        reason: 'symbol switch should clear the chart first');

    // Subsequent EURUSD ticks should bootstrap EURUSD candles (around 1.10),
    // NOT around the stale GBPUSD price (~1.32).
    stub.push({'symbol': 'EURUSD', 'bid': 1.10, 'ask': 1.1002});
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final bootstrapSnapshot = updates
        .where((u) =>
            u.kind == AggregatorEventKind.snapshot && u.candles.isNotEmpty)
        .last;
    expect(bootstrapSnapshot.candles, isNotEmpty);
    for (final c in bootstrapSnapshot.candles.skip(1)) {
      expect(c.close, closeTo(1.10, 0.01),
          reason: 'EURUSD backfill must anchor around EURUSD price, not stale GBPUSD');
    }

    await sub.cancel();
  });
}
