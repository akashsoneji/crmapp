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
      symbolId: json['symbol_id'] ?? 0,
      displaySymbol: json['display_symbol'] ?? '',
      datafeedSymbol: json['datafeed_symbol'] ?? '',
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      digits: json['digits'] ?? 0,
      contractSize: (json['contract_size'] ?? 0.0).toDouble(),
      isActive: json['is_active'] ?? false,
      isSynced: json['is_synced'] ?? false,
      lpProviderId: json['lp_provider_id'] ?? 0,
      groupId: json['group_id'] ?? 0,
      spreadConfig: SpreadConfig.fromJson(json['spread_config'] ?? {}),
      stopsLevel: json['stops_level'] ?? 0,
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
