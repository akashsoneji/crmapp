import 'dart:async';
import 'dart:convert';

import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/models/market_history.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Loads OHLCV history for the native candlestick chart via the
/// TradingView-style `/api/market/history` endpoint exposed by the
/// backend.
///
/// The backend serves three "tiers" of history depending on how far back
/// the client asks for:
///
///   1. Hot    — last hour, capped at ~1000 bars.
///   2. Cold   — last 12 hours, capped at ~3000 bars.
///   3. Older  — anything older, also capped at ~3000 bars per request.
///
/// This service exposes a single high-level [fetchInitial] that always
/// pulls a sensible window (default: 1 day back), and a [fetchOlder]
/// method that walks further into the past one tier at a time so the
/// chart can backfill as the user scrolls left.
class MarketHistoryService {
  MarketHistoryService({
    http.Client? client,
    Duration timeout = const Duration(seconds: 12),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  /// Cancel any in-flight request. Safe to call multiple times.
  void dispose() => _client.close();

  /// Build the absolute URL for the history endpoint. Honours the
  /// per-client `chartBaseUrl` so the same code works for every broker
  /// configuration (GTX Prime, Tenax, etc.).
  Uri _buildUri({
    required String symbol,
    required int from,
    required int to,
    required int count,
    required String resolution,
  }) {
    final base = FlavorConfig.instance.chartBaseUrl;
    final normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return Uri.parse('$normalized/api/market/history').replace(
      queryParameters: {
        'symbol': symbol,
        'from': from.toString(),
        'to': to.toString(),
        'count': count.toString(),
        'resolution': resolution,
      },
    );
  }

  /// Hit the history endpoint once with the given window.
  Future<MarketHistory> _fetchRaw({
    required String symbol,
    required int from,
    required int to,
    required int count,
    required String resolution,
  }) async {
    final uri = _buildUri(
      symbol: symbol,
      from: from,
      to: to,
      count: count,
      resolution: resolution,
    );

    final response = await _client
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MarketHistoryException(
        'History HTTP ${response.statusCode} for $symbol $resolution',
        statusCode: response.statusCode,
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw const MarketHistoryException('Empty history response body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const MarketHistoryException('History response is not a JSON object');
    }

    return MarketHistory.fromJson(decoded);
  }

  /// Merge multiple tier responses into a single [MarketHistory] sorted by
  /// timestamp ascending, deduplicated by `t`. Bars with any OHLC == NaN
  /// are dropped (the model filters these out automatically; this just
  /// enforces equal array length for safety).
  MarketHistory _merge(List<MarketHistory> parts) {
    if (parts.isEmpty) {
      return const MarketHistory(
        status: 'ok',
        times: [],
        opens: [],
        highs: [],
        lows: [],
        closes: [],
        volumes: [],
      );
    }

    final byTime = <int, _Bar>{};
    for (final p in parts) {
      if (!p.isOk) continue;
      for (var i = 0; i < p.count; i++) {
        final t = p.times[i];
        if (byTime.containsKey(t)) continue;
        byTime[t] = _Bar(
          time: t,
          open: i < p.opens.length ? p.opens[i] : double.nan,
          high: i < p.highs.length ? p.highs[i] : double.nan,
          low: i < p.lows.length ? p.lows[i] : double.nan,
          close: i < p.closes.length ? p.closes[i] : double.nan,
          volume: i < p.volumes.length ? p.volumes[i] : 0.0,
        );
      }
    }

    final sorted = byTime.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return MarketHistory(
      status: 'ok',
      times: sorted.map((e) => e.value.time).toList(),
      opens: sorted.map((e) => e.value.open).toList(),
      highs: sorted.map((e) => e.value.high).toList(),
      lows: sorted.map((e) => e.value.low).toList(),
      closes: sorted.map((e) => e.value.close).toList(),
      volumes: sorted.map((e) => e.value.volume).toList(),
      from: sorted.isEmpty ? null : sorted.first.key,
      to: sorted.isEmpty ? null : sorted.last.key,
    );
  }

  /// Fetch an initial history window for the chart, in seconds. The
  /// default 86 400 (24h) covers a full trading day at every common
  /// resolution.
  Future<MarketHistory> fetchInitial({
    required String symbol,
    required String resolution,
    int lookbackSeconds = 24 * 60 * 60,
    DateTime? now,
  }) async {
    final nowSec =
        ((now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000);
    final from = nowSec - lookbackSeconds;

    // Tier 1: hot (1h, 1000 bars) — guaranteed overlap so we never miss a
    // boundary while paged calls return their own result-set.
    final hotTo = nowSec;
    final hotFrom = nowSec - 60 * 60;

    // Tier 2: cold (12h, 3000 bars).
    final coldFrom = hotFrom - 12 * 60 * 60;

    // Tier 3: older (everything else up to the requested lookback).
    final olderFrom = from;

    final futures = <Future<MarketHistory>>[
      _fetchRaw(
        symbol: symbol,
        from: hotFrom,
        to: hotTo,
        count: 1000,
        resolution: resolution,
      ),
      _fetchRaw(
        symbol: symbol,
        from: coldFrom,
        to: hotFrom,
        count: 3000,
        resolution: resolution,
      ),
      _fetchRaw(
        symbol: symbol,
        from: olderFrom,
        to: coldFrom,
        count: 3000,
        resolution: resolution,
      ),
    ];

    final results = await Future.wait(
      futures.map((f) => f.catchError((Object e, StackTrace st) {
        // Don't fail the entire load when one tier is unavailable —
        // degrade gracefully with an empty history chunk.
        if (kDebugMode) {
          debugPrint('MarketHistory: tier fetch failed: $e');
        }
        return const MarketHistory(
          status: 'ok',
          times: [],
          opens: [],
          highs: [],
          lows: [],
          closes: [],
          volumes: [],
        );
      })),
    );

    return _merge(results);
  }

  /// Fetch one batch of older bars (one tier back) for pagination as the
  /// user scrolls left. Returns an empty history when [beforeUnixSec] is
  /// null or the backend has nothing more to give.
  Future<MarketHistory> fetchOlder({
    required String symbol,
    required String resolution,
    required int beforeUnixSec,
    int tierSeconds = 12 * 60 * 60,
    int count = 3000,
  }) async {
    final to = beforeUnixSec;
    final from = beforeUnixSec - tierSeconds;
    return _fetchRaw(
      symbol: symbol,
      from: from,
      to: to,
      count: count,
      resolution: resolution,
    );
  }
}

class _Bar {
  final int time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  const _Bar({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class MarketHistoryException implements Exception {
  final String message;
  final int? statusCode;

  const MarketHistoryException(this.message, {this.statusCode});

  @override
  String toString() => 'MarketHistoryException($statusCode): $message';
}
