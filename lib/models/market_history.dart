/// Response model for the TradingView-style `/api/market/history` endpoint.
///
/// The wire format (and field naming) mirrors the TradingView UDF contract
/// used by member.gtxprime.com and the other broker clients:
/// `s` = status ("ok" | "error"), and parallel arrays `t`, `o`, `h`, `l`,
/// `c`, `v` of equal length.
class MarketHistory {
  /// "ok" on success, anything else on failure (see [errorMessage]).
  final String status;

  /// Unix seconds for each bar's start.
  final List<int> times;

  /// Open / High / Low / Close prices (same length as [times]).
  final List<double> opens;
  final List<double> highs;
  final List<double> lows;
  final List<double> closes;

  /// Volume per bar (may be empty on some feeds).
  final List<double> volumes;

  /// Optional error message returned when [status] != "ok".
  final String? errorMessage;

  /// `from` (inclusive) echoed back from the request, or null.
  final int? from;

  /// `to` (inclusive) echoed back from the request, or null.
  final int? to;

  const MarketHistory({
    required this.status,
    required this.times,
    required this.opens,
    required this.highs,
    required this.lows,
    required this.closes,
    required this.volumes,
    this.errorMessage,
    this.from,
    this.to,
  });

  /// True when the response is well-formed and carries at least one bar.
  bool get isOk => status == 'ok' && times.isNotEmpty;

  /// Number of bars in the response. Always equal across all parallel arrays.
  int get count => times.length;

  factory MarketHistory.fromJson(Map<String, dynamic> json) {
    List<double> _numbers(dynamic val) {
      if (val is! List) return const <double>[];
      final list = val
          .map((e) => e == null ? double.nan : double.tryParse(e.toString()) ?? double.nan)
          .where((d) => !d.isNaN)
          .toList();
      return list;
    }

    return MarketHistory(
      status: (json['s'] ?? json['status'] ?? '').toString(),
      times: ((json['t'] ?? json['times']) as List?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList() ??
          const <int>[],
      opens: _numbers(json['o'] ?? json['opens']),
      highs: _numbers(json['h'] ?? json['highs']),
      lows: _numbers(json['l'] ?? json['lows']),
      closes: _numbers(json['c'] ?? json['closes']),
      volumes: _numbers(json['v'] ?? json['volumes']),
      errorMessage: json['errmsg']?.toString(),
      from: int.tryParse(json['from']?.toString() ?? ''),
      to: int.tryParse(json['to']?.toString() ?? ''),
    );
  }

  /// JSON for SharedPreferences persistence.
  Map<String, dynamic> toJson() => {
        's': status,
        't': times,
        'o': opens,
        'h': highs,
        'l': lows,
        'c': closes,
        'v': volumes,
        if (errorMessage != null) 'errmsg': errorMessage,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };

  factory MarketHistory.fromCache(Map<String, dynamic> json) =>
      MarketHistory.fromJson(json);
}