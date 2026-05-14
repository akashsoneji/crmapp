/// API may send ints or numeric strings; [group_id] is often `""` when unset.
int _apiInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    if (value.isEmpty) return fallback;
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

double _apiDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    if (value.isEmpty) return fallback;
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

class SearchInstrumentsResponse {
  final bool status;
  final bool success;
  final String message;
  final SearchInstrumentsData? data;

  SearchInstrumentsResponse({
    required this.status,
    required this.success,
    required this.message,
    this.data,
  });

  factory SearchInstrumentsResponse.fromJson(Map<String, dynamic> json) {
    return SearchInstrumentsResponse(
      status: json['status'] ?? false,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SearchInstrumentsData.fromJson(json['data']) : null,
    );
  }
}

class SearchInstrumentsData {
  final List<SearchSymbol> symbols;

  SearchInstrumentsData({required this.symbols});

  factory SearchInstrumentsData.fromJson(Map<String, dynamic> json) {
    return SearchInstrumentsData(
      symbols: (json['symbols'] as List? ?? [])
          .map((item) => SearchSymbol.fromJson(item))
          .toList(),
    );
  }
}

class SearchSymbol {
  final int symbolId;
  final String displaySymbol;
  final String datafeedSymbol;
  final int categoryId;
  final String categoryName;
  final int digits;
  final double contractSize;
  final bool isActive;
  final bool isSynced;
  final int lpProviderId;
  final int groupId;
  final SpreadConfig spreadConfig;
  final int stopsLevel;

  SearchSymbol({
    required this.symbolId,
    required this.displaySymbol,
    required this.datafeedSymbol,
    required this.categoryId,
    required this.categoryName,
    required this.digits,
    required this.contractSize,
    required this.isActive,
    required this.isSynced,
    required this.lpProviderId,
    required this.groupId,
    required this.spreadConfig,
    required this.stopsLevel,
  });

  factory SearchSymbol.fromJson(Map<String, dynamic> json) {
    return SearchSymbol(
      symbolId: _apiInt(json['symbol_id']),
      displaySymbol: json['display_symbol'] ?? '',
      datafeedSymbol: json['datafeed_symbol'] ?? '',
      categoryId: _apiInt(json['category_id']),
      categoryName: json['category_name'] ?? '',
      digits: _apiInt(json['digits']),
      contractSize: _apiDouble(json['contract_size']),
      isActive: json['is_active'] ?? false,
      isSynced: json['is_synced'] ?? false,
      lpProviderId: _apiInt(json['lp_provider_id']),
      groupId: _apiInt(json['group_id']),
      spreadConfig: SpreadConfig.fromJson(json['spread_config'] ?? {}),
      stopsLevel: _apiInt(json['stops_level']),
    );
  }
}

class SpreadConfig {
  final double spreadDiff;
  final double bidAdjustment;
  final double askAdjustment;
  final String source;

  SpreadConfig({
    required this.spreadDiff,
    required this.bidAdjustment,
    required this.askAdjustment,
    required this.source,
  });

  factory SpreadConfig.fromJson(Map<String, dynamic> json) {
    return SpreadConfig(
      spreadDiff: (json['spread_diff'] ?? 0.0).toDouble(),
      bidAdjustment: (json['bid_adjustment'] ?? 0.0).toDouble(),
      askAdjustment: (json['ask_adjustment'] ?? 0.0).toDouble(),
      source: json['source'] ?? 'none',
    );
  }
}
