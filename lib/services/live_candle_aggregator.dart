import 'dart:async';
import 'dart:convert';

import 'package:crm_app/controllers/chart_socket_controller.dart';
import 'package:crm_app/models/candle.dart';
import 'package:crm_app/services/market_history_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the aggregator emits on its update stream.
enum AggregatorEventKind {
  /// Full snapshot, used on bootstrap, symbol switch, and interval switch.
  /// Replaces the entire candle list on the chart.
  snapshot,

  /// Single candle changed (live tick). Replaces candle at index 0 in place.
  tickUpdate,
}

class AggregatorUpdate {
  final AggregatorEventKind kind;
  final List<Candle> candles; // newest-first; the chart's expected order
  final Candle? updated; // only set for tickUpdate
  const AggregatorUpdate.snapshot(this.candles)
    : kind = AggregatorEventKind.snapshot,
      updated = null;
  const AggregatorUpdate.tickUpdate(Candle this.updated)
    : kind = AggregatorEventKind.tickUpdate,
      candles = const [];
}

/// In-memory OHLC bucket for one (symbol, interval) pair.
class _Bucket {
  final int intervalSeconds;
  final int maxBars;
  final List<Candle> completed = []; // oldest -> newest
  Candle? current; // in-progress candle

  _Bucket(this.intervalSeconds, this.maxBars);

  /// Compute the unix-seconds bucket start for the given tick time.
  int bucketStart(int unixSeconds) {
    return (unixSeconds ~/ intervalSeconds) * intervalSeconds;
  }

  /// Apply a mid-price tick. Returns the updated in-progress candle, or null
  /// if the bucket rolled over and a new one started.
  Candle? applyTick({
    required double midPrice,
    required DateTime time,
  }) {
    final unixSeconds = time.millisecondsSinceEpoch ~/ 1000;
    final start = bucketStart(unixSeconds);

    if (current == null) {
      current = Candle(
        date: DateTime.fromMillisecondsSinceEpoch(start * 1000),
        open: midPrice,
        high: midPrice,
        low: midPrice,
        close: midPrice,
        volume: 0,
      );
      return current;
    }

    final currentStart = current!.date.millisecondsSinceEpoch ~/ 1000;
    if (start != currentStart) {
      completed.add(current!);
      if (completed.length > maxBars) {
        completed.removeRange(0, completed.length - maxBars);
      }
      current = Candle(
        date: DateTime.fromMillisecondsSinceEpoch(start * 1000),
        open: midPrice,
        high: midPrice,
        low: midPrice,
        close: midPrice,
        volume: 0,
      );
      return null; // signals rollover
    }

    final c = current!;
    final newHigh = midPrice > c.high ? midPrice : c.high;
    final newLow = midPrice < c.low ? midPrice : c.low;
    current = Candle(
      date: c.date,
      open: c.open,
      high: newHigh,
      low: newLow,
      close: midPrice,
      volume: c.volume,
    );
    return current;
  }

  /// Returns the candles newest-first, suitable for the chart.
  List<Candle> toChartList() {
    final list = <Candle>[];
    if (current != null) list.add(current!);
    for (var i = completed.length - 1; i >= 0; i--) {
      list.add(completed[i]);
    }
    return list;
  }
}

/// Aggregates live bid/ask ticks from [ChartSocketController] into OHLC
/// candles for the selected symbol + interval.
///
/// Registered as a permanent `Get` service in `main.dart` so all chart
/// consumers (main chart + preview screens) share the same buffer.
///
/// Supports ref-counted pause/resume so that when the user opens the
/// fullscreen WebView route, we stop ticking without losing accumulated
/// history. Resume catches up in under a second.
class LiveCandleAggregator extends GetxService {
  /// Max number of completed candles to keep per (symbol, interval).
  /// Persisted to SharedPreferences; older bars are dropped FIFO.
  static const int maxBars = 500;

  /// Minimum interval we accept. Anything below is clamped to this.
  static const int minIntervalSeconds = 1;

  /// Hard cap to avoid silly values from config bugs.
  static const int maxIntervalSeconds = 60 * 60 * 24 * 7; // 1 week

  static LiveCandleAggregator get instance =>
      Get.isRegistered<LiveCandleAggregator>()
          ? Get.find<LiveCandleAggregator>()
          : Get.put(LiveCandleAggregator(), permanent: true);

  final ChartSocketController _chartSocket =
      Get.isRegistered<ChartSocketController>()
          ? Get.find<ChartSocketController>()
          : Get.put(ChartSocketController());

  final _updates = StreamController<AggregatorUpdate>.broadcast();
  Stream<AggregatorUpdate> get updates => _updates.stream;

  /// Current buffered candles (newest-first).
  List<Candle> candles = const [];

  String _symbol = '';
  int _intervalSeconds = 60;
  _Bucket? _bucket;
  StreamSubscription<Map<String, dynamic>>? _tickSub;
  Timer? _tickDebounce;
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);
  String _lastPersistedSymbol = '';
  int _lastPersistedInterval = 0;
  int _lastPersistedCount = -1;

  int _pausedRefCount = 0;
  bool _awaitingBootstrap = false;

  /// Symbol currently being aggregated (empty if not started).
  String get symbol => _symbol;

  /// Interval currently being aggregated (seconds).
  int get intervalSeconds => _intervalSeconds;

  /// True while at least one consumer has paused ticking.
  bool get isPaused => _pausedRefCount > 0;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Synthetic backfill (used on cold start with no history)
  // ---------------------------------------------------------------------------

  /// Build a short series of synthetic candles that brackets [anchorPrice]
  /// with a small realistic drift. Used on cold start so the chart can
  /// render a meaningful Y-axis range and visible H/L on day-one, before
  /// any real ticks have arrived.
  ///
  /// The synthetic series is anchored at the most-recent bucket so the very
  /// first live tick (which becomes [LiveCandleAggregator._bucket.current])
  /// sits at the right edge of the chart.
  ///
  /// The candles are deterministic given the same anchor and timestamp
  /// (uses a lightweight linear congruential generator keyed on the
  /// timestamp), so two cold starts 100 ms apart produce visibly different
  /// but always sensible series.
  List<Candle> _synthesizeBackfill(double anchorPrice, int count) {
    if (count <= 0 || anchorPrice <= 0) return const [];
    // Drift band: 0.15% of anchor per candle. For 1.32 that's ~0.002, which
    // is well above the spread (0.00025 for GBPUSD) so the chart is
    // visually rich.
    final driftPct = 0.0015;
    final out = <Candle>[];
    final now = DateTime.now();
    final rngSeed = now.millisecondsSinceEpoch;
    var rng = rngSeed & 0x7fffffff;
    double nextRand() {
      // Linear congruential generator (Numerical Recipes constants).
      rng = (rng * 1664525 + 1013904223) & 0x7fffffff;
      return rng / 0x7fffffff;
    }

    // Walk backwards from anchor.
    double price = anchorPrice;
    for (var i = 0; i < count; i++) {
      final bucketStart =
          ((now.millisecondsSinceEpoch ~/ 1000) ~/ _intervalSeconds) *
                  _intervalSeconds -
              _intervalSeconds * (count - i);
      final open = price;
      // Alternate up/down bias for visual variety.
      final bias = (i.isEven ? 1.0 : -1.0) * (0.3 + 0.7 * nextRand());
      final closeDelta = anchorPrice * driftPct * bias;
      final close = open + closeDelta;
      final high =
          (open > close ? open : close) + anchorPrice * driftPct * nextRand();
      final low =
          (open < close ? open : close) - anchorPrice * driftPct * nextRand();
      out.add(Candle(
        date: DateTime.fromMillisecondsSinceEpoch(bucketStart * 1000),
        open: open,
        high: high,
        low: low,
        close: close,
        volume: 0,
      ));
      price = close;
    }
    // Final candle is the most recent. We want the live tick to land in
    // the BUCKET that follows these backfill candles, so set [price] to the
    // last candle close (caller will append the real tick to a new bucket).
    return out;
  }

  /// Number of synthetic candles to mint on cold start. Kept small so the
  /// user immediately sees the real price action, not pretend history.
  static const int _backfillCount = 30;

  /// Start (or restart) aggregation for the given symbol + interval.
  Future<List<Candle>> start(String symbol, int intervalSeconds) async {
    final cleanSymbol = symbol.trim();
    if (cleanSymbol.isEmpty) return const [];

    final cleanInterval = intervalSeconds
        .clamp(minIntervalSeconds, maxIntervalSeconds)
        .toInt();

    final sameConfig =
        cleanSymbol == _symbol && cleanInterval == _intervalSeconds;
    if (sameConfig && _bucket != null) {
      return candles;
    }

    await _persistIfNeeded();

    // If we are switching symbols, clear the chart immediately so the user
    // doesn't see stale candles from the previous symbol while waiting for
    // the first tick of the new one. We emit an empty snapshot BEFORE any
    // new ticks land; the chart will show its loading state until the new
    // symbol's first tick arrives.
    final isSymbolSwitch = _symbol.isNotEmpty && _symbol != cleanSymbol;
    if (isSymbolSwitch) {
      candles = const [];
      _updates.add(AggregatorUpdate.snapshot(List.unmodifiable(candles)));
    }

    _symbol = cleanSymbol;
    _intervalSeconds = cleanInterval;

    _bucket = _Bucket(_intervalSeconds, maxBars);

    List<Candle> loaded = [];
    try {
      final resolution = _getResolution(_intervalSeconds);
      final lookback = _intervalSeconds * maxBars;
      final history = await MarketHistoryService().fetchInitial(
        symbol: _symbol,
        resolution: resolution,
        lookbackSeconds: lookback,
      );
      if (history.isOk) {
        for (var i = 0; i < history.count; i++) {
          loaded.add(Candle(
            date: DateTime.fromMillisecondsSinceEpoch(history.times[i] * 1000),
            open: i < history.opens.length ? history.opens[i] : 0.0,
            high: i < history.highs.length ? history.highs[i] : 0.0,
            low: i < history.lows.length ? history.lows[i] : 0.0,
            close: i < history.closes.length ? history.closes[i] : 0.0,
            volume: i < history.volumes.length ? history.volumes[i] : 0.0,
          ));
        }
      }
    } catch (e) {
      debugPrint('LiveCandleAggregator: failed to fetch initial history from API: $e');
    }

    if (loaded.isEmpty) {
      loaded = await _loadBuffer(_symbol, _intervalSeconds);
    }

    if (loaded.isNotEmpty) {
      final lastCandle = loaded.last;
      final unixSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final currentBucketStart = _bucket!.bucketStart(unixSeconds);
      final lastCandleStart = lastCandle.date.millisecondsSinceEpoch ~/ 1000;

      if (lastCandleStart == currentBucketStart) {
        _bucket!.current = lastCandle;
        _bucket!.completed.addAll(loaded.sublist(0, loaded.length - 1));
      } else {
        _bucket!.completed.addAll(loaded);
      }
    }

    // Seed with the current socket price ONLY when:
    //   (a) the seed price's symbol matches the new symbol we're
    //       aggregating, AND
    //   (b) we are NOT switching symbols (so the cached price is reliably
    //       for the new symbol).
    // Otherwise the seed price may belong to the previous symbol and
    // would corrupt the new symbol's first candle.
    if (_bucket!.current == null) {
      final seedPrice = isSymbolSwitch ? null : _chartSocket.getCurrentPrice();
      double? seedMid;
      if (seedPrice != null) {
        final seedSym =
            (seedPrice['symbol'] ?? seedPrice['Symbol'])?.toString() ?? '';
        final symbolMatches =
            seedSym.isEmpty || _symbolMatches(seedSym, _symbol);
        if (symbolMatches) {
          final bid = _readNum(seedPrice, 'bid') ?? _readNum(seedPrice, 'Bid');
          final ask = _readNum(seedPrice, 'ask') ?? _readNum(seedPrice, 'Ask');
          if (bid != null && ask != null) {
            seedMid = (bid + ask) / 2;
          } else if (bid != null) {
            seedMid = bid;
          } else if (ask != null) {
            seedMid = ask;
          }
          if (seedMid != null) {
            _bucket!.applyTick(midPrice: seedMid, time: DateTime.now());
          }
        }
      }
    }

    _attachTickSubscription();

    // Bootstrap rules:
    //   1. If we already have history (loaded buffer or seed tick) → emit
    //      snapshot immediately so the chart paints without flicker.
    //   2. If neither is available → wait for the very first tick, then
    //      emit a snapshot. To avoid the log-scale issue (one candle near
    //      1.0 triggers log Y-axis with span 100...0.1), we ALSO mint a
    //      short synthetic backfill series centered on the seed price (if
    //      available) or a placeholder price (1.0) once the first tick
    //      arrives. The backfill is created lazily inside _onTick to
    //      guarantee it brackets the actual market price.
    final hasHistory =
        _bucket!.completed.isNotEmpty || _bucket!.current != null;
    if (hasHistory) {
      candles = _bucket!.toChartList();
      _updates.add(AggregatorUpdate.snapshot(List.unmodifiable(candles)));
      _awaitingBootstrap = false;
    } else {
      // Mark that we're waiting for a bootstrap tick. _onTick will see this
      // flag, mint a synthetic backfill series around the first tick price,
      // and emit a snapshot instead of just a tickUpdate event.
      _awaitingBootstrap = true;
    }

    return candles;
  }

  /// Switch to a different interval (e.g. 1m -> 5m).
  Future<List<Candle>> setInterval(int newIntervalSeconds) async {
    if (_symbol.isEmpty) return const [];
    final cleanInterval = newIntervalSeconds
        .clamp(minIntervalSeconds, maxIntervalSeconds)
        .toInt();
    if (cleanInterval == _intervalSeconds) return candles;

    final oldBucket = _bucket;
    if (oldBucket != null) {
      await _persistIfNeeded();
      final reBucketed = _reBucket(oldBucket.completed, cleanInterval);
      _bucket = _Bucket(cleanInterval, maxBars)..completed.addAll(reBucketed);
    } else {
      _bucket = _Bucket(cleanInterval, maxBars);
    }

    _intervalSeconds = cleanInterval;
    candles = _bucket!.toChartList();
    _awaitingBootstrap = false;
    _updates.add(AggregatorUpdate.snapshot(List.unmodifiable(candles)));

    return candles;
  }

  /// Prepend older candles loaded from pagination to the beginning of
  /// completed history. Deduplicates against existing completed/current
  /// candles.
  void addOlderCandles(List<Candle> older) {
    if (older.isEmpty || _bucket == null) return;

    final existingDates = _bucket!.completed.map((c) => c.date).toSet();
    if (_bucket!.current != null) {
      existingDates.add(_bucket!.current!.date);
    }

    final newOlder = older.where((c) => !existingDates.contains(c.date)).toList();
    if (newOlder.isEmpty) return;

    newOlder.sort((a, b) => a.date.compareTo(b.date));
    _bucket!.completed.insertAll(0, newOlder);
    candles = _bucket!.toChartList();
    _updates.add(AggregatorUpdate.snapshot(List.unmodifiable(candles)));
  }

  String _getResolution(int intervalSeconds) {
    if (intervalSeconds >= 86400) return 'D';
    if (intervalSeconds >= 14400) return '240';
    if (intervalSeconds >= 3600) return '60';
    if (intervalSeconds >= 1800) return '30';
    if (intervalSeconds >= 900) return '15';
    if (intervalSeconds >= 300) return '5';
    if (intervalSeconds >= 60) return '1';
    return '1';
  }

  /// Ref-counted pause.
  void pause() {
    _pausedRefCount++;
    if (_pausedRefCount == 1) {
      _detachTickSubscription();
    }
  }

  /// Ref-counted resume. Safe to call without a matching pause.
  void resume() {
    if (_pausedRefCount == 0) return;
    _pausedRefCount--;
    if (_pausedRefCount == 0) {
      _attachTickSubscription();
    }
  }

  @override
  void onClose() {
    _detachTickSubscription();
    _tickDebounce?.cancel();
    _persistIfNeeded();
    _updates.close();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _attachTickSubscription() {
    _detachTickSubscription();
    _tickSub = _chartSocket.priceStream.listen(_onTick);
  }

  void _detachTickSubscription() {
    _tickSub?.cancel();
    _tickSub = null;
  }

  void _onTick(Map<String, dynamic> data) {
    if (_bucket == null || _symbol.isEmpty) return;

    final sym = (data['symbol'] ?? data['Symbol'])?.toString() ?? '';
    if (sym.isNotEmpty && !_symbolMatches(sym, _symbol)) return;

    final bid = _readNum(data, 'bid') ?? _readNum(data, 'Bid');
    final ask = _readNum(data, 'ask') ?? _readNum(data, 'Ask');
    final last = _readNum(data, 'last') ?? _readNum(data, 'Last');

    double? midPrice;
    if (bid != null && ask != null) {
      midPrice = (bid + ask) / 2;
    } else if (bid != null) {
      midPrice = bid;
    } else if (ask != null) {
      midPrice = ask;
    } else if (last != null) {
      midPrice = last;
    }
    if (midPrice == null || midPrice <= 0) return;

    final now = DateTime.now();

    // Cold-start backfill: on the very first tick with no history, mint a
    // short synthetic series anchored at the live price so the chart can
    // render a meaningful Y-axis range (no log scale, visible H/L wicks).
    if (_awaitingBootstrap && _bucket!.completed.isEmpty && _bucket!.current == null) {
      _bucket!.completed.addAll(_synthesizeBackfill(midPrice, _backfillCount));
    }

    final result = _bucket!.applyTick(midPrice: midPrice, time: now);
    if (result == null) {
      // Rollover: persist asynchronously.
      _schedulePersist();
    }
    final updated = _bucket!.current;
    if (updated == null) return;

    candles = _bucket!.toChartList();

    // First tick after start() with no seed/buffer: emit a snapshot so the
    // chart unblocks its loading state with the freshly bootstrapped candle.
    final wasBootstrapping = _awaitingBootstrap;
    _awaitingBootstrap = false;

    if (_tickDebounce != null) return;
    _tickDebounce = Timer(const Duration(milliseconds: 50), () {
      _tickDebounce = null;
      if (wasBootstrapping) {
        _updates.add(
          AggregatorUpdate.snapshot(List.unmodifiable(candles)),
        );
      } else {
        _updates.add(AggregatorUpdate.tickUpdate(updated));
      }
    });
  }

  void _schedulePersist() {
    final now = DateTime.now();
    if (now.difference(_lastPersist).inSeconds < 5) return;
    _lastPersist = now;
    _persistIfNeeded();
  }

  Future<void> _persistIfNeeded() async {
    final b = _bucket;
    if (b == null || _symbol.isEmpty) return;
    if (_lastPersistedSymbol == _symbol &&
        _lastPersistedInterval == _intervalSeconds &&
        b.completed.length == _lastPersistedCount) {
      return;
    }
    final key = _storageKey(_symbol, _intervalSeconds);
    final prefs = await SharedPreferences.getInstance();
    final list = b.completed.map((c) => c.toJson()).toList();
    await prefs.setString(key, jsonEncode(list));
    _lastPersistedSymbol = _symbol;
    _lastPersistedInterval = _intervalSeconds;
    _lastPersistedCount = b.completed.length;
  }

  Future<List<Candle>> _loadBuffer(String symbol, int intervalSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(symbol, intervalSeconds));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final list = <Candle>[];
      for (final entry in decoded) {
        if (entry is Map<String, dynamic>) {
          try {
            list.add(Candle.fromJson(entry));
          } catch (_) {}
        }
      }
      if (list.length > maxBars) {
        return list.sublist(list.length - maxBars);
      }
      return list;
    } catch (e) {
      debugPrint('LiveCandleAggregator: failed to load buffer: $e');
      return const [];
    }
  }

  /// Re-bucket candles (oldest -> newest) into a new interval.
  List<Candle> _reBucket(List<Candle> source, int newIntervalSeconds) {
    if (source.isEmpty) return const [];
    final out = <Candle>[];

    Candle? accum;
    int groupBucketStart = 0;
    bool hasGroup = false;

    void flushGroup() {
      if (hasGroup && accum != null) {
        out.add(accum!);
      }
      accum = null;
      hasGroup = false;
    }

    for (final c in source) {
      final cs = c.date.millisecondsSinceEpoch ~/ 1000;
      final bucketStart = (cs ~/ newIntervalSeconds) * newIntervalSeconds;
      if (!hasGroup || bucketStart != groupBucketStart) {
        flushGroup();
        groupBucketStart = bucketStart;
        accum = Candle(
          date: DateTime.fromMillisecondsSinceEpoch(bucketStart * 1000),
          open: c.open,
          high: c.high,
          low: c.low,
          close: c.close,
          volume: c.volume,
        );
        hasGroup = true;
      } else {
        final cur = accum!;
        accum = Candle(
          date: cur.date,
          open: cur.open,
          high: cur.high > c.high ? cur.high : c.high,
          low: cur.low < c.low ? cur.low : c.low,
          close: c.close,
          volume: cur.volume + c.volume,
        );
      }
    }
    flushGroup();

    if (out.length > maxBars) {
      return out.sublist(out.length - maxBars);
    }
    return out;
  }

  String _storageKey(String symbol, int intervalSeconds) =>
      'candles_${symbol}_${intervalSeconds}';

  static double? _readNum(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _symbolMatches(String a, String b) {
    if (a == b) return true;
    String base(String s) =>
        s.contains('.') ? s.substring(0, s.lastIndexOf('.')) : s;
    return base(a).toUpperCase() == base(b).toUpperCase();
  }
}