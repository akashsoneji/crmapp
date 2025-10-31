class TradeHistoryResponse {
  final String message;
  final bool status;
  final List<TradeHistoryItem> data;
  final PaginationInfo pagination;
  final TradeHistoryTotals? totals;

  TradeHistoryResponse({
    required this.message,
    required this.status,
    required this.data,
    required this.pagination,
    this.totals,
  });

  factory TradeHistoryResponse.fromJson(Map<String, dynamic> json) {
    return TradeHistoryResponse(
      message: json['message'] ?? '',
      status: json['status'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => TradeHistoryItem.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
      totals:
          json['totals'] != null
              ? TradeHistoryTotals.fromJson(json['totals'])
              : null,
    );
  }
}

class TradeHistoryItem {
  final int mt5Account;
  final int tradePositionId;
  final String tradeType;
  final String tradeSymbol;
  final String tradeVolume;
  final String tradePriceOrder;
  final String tradeOpenTime;
  final String tradeCloseTime;
  final String tradePriceClose;
  final String tradeProfit;
  final String tradePriceTp;
  final String tradePriceSl;
  final String tradeCommission;

  TradeHistoryItem({
    required this.mt5Account,
    required this.tradePositionId,
    required this.tradeType,
    required this.tradeSymbol,
    required this.tradeVolume,
    required this.tradePriceOrder,
    required this.tradeOpenTime,
    required this.tradeCloseTime,
    required this.tradePriceClose,
    required this.tradeProfit,
    required this.tradePriceTp,
    required this.tradePriceSl,
    required this.tradeCommission,
  });

  factory TradeHistoryItem.fromJson(Map<String, dynamic> json) {
    return TradeHistoryItem(
      mt5Account: json['mt5_account'] ?? 0,
      tradePositionId: json['trade_position_id'] ?? 0,
      tradeType: json['trade_type'] ?? '',
      tradeSymbol: json['trade_symbol'] ?? '',
      tradeVolume: json['trade_volume'] ?? '0',
      tradePriceOrder: json['trade_price_order'] ?? '0',
      tradeOpenTime: json['trade_open_time'] ?? '',
      tradeCloseTime: json['trade_close_time'] ?? '',
      tradePriceClose: json['trade_price_close'] ?? '0',
      tradeProfit: json['trade_profit'] ?? '0',
      tradePriceTp: json['trade_price_tp'] ?? '0',
      tradePriceSl: json['trade_price_sl'] ?? '0',
      tradeCommission: json['trade_commission'] ?? '0',
    );
  }

  // Convert to TradePosition for compatibility with existing UI
  Map<String, dynamic> toTradePositionMap() {
    return {
      'symbol': tradeSymbol,
      'flag': _getFlagForSymbol(tradeSymbol),
      'action': tradeType,
      'volume': double.tryParse(tradeVolume) ?? 0.0,
      'profitLoss': double.tryParse(tradeProfit) ?? 0.0,
      'entryPrice': tradePriceOrder,
      'currentPrice': tradePriceClose,
      'accountId': mt5Account.toString(),
      'orderId': tradePositionId.toString(),
      'isFavorite': false,
      'openTime': tradeOpenTime,
      'closeTime': tradeCloseTime,
      'reason': '',
      'orderNo': tradePositionId.toString(),
      'commission': double.tryParse(tradeCommission) ?? 0.0,
      'swap': 0.0,
      'takeProfit': tradePriceTp,
      'stopLoss': tradePriceSl,
      'mt5Account': mt5Account.toString(),
      'time': tradeCloseTime,
    };
  }

  String _getFlagForSymbol(String symbol) {
    // Map common symbols to flags
    if (symbol.contains('EUR')) return '🇪🇺';
    if (symbol.contains('USD')) return '🇺🇸';
    if (symbol.contains('GBP')) return '🇬🇧';
    if (symbol.contains('JPY')) return '🇯🇵';
    if (symbol.contains('AUD')) return '🇦🇺';
    if (symbol.contains('CAD')) return '🇨🇦';
    if (symbol.contains('CHF')) return '🇨🇭';
    if (symbol.contains('XAU')) return '🥇';
    if (symbol.contains('XAG')) return '🥈';
    if (symbol.contains('BTC')) return '₿';
    if (symbol.contains('ETH')) return 'Ξ';
    return '📈';
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      nextPageUrl: json['next_page_url'],
      prevPageUrl: json['prev_page_url'],
    );
  }

  bool get hasNextPage => nextPageUrl != null;
  bool get hasPrevPage => prevPageUrl != null;
}

class TradeHistoryTotals {
  final double balance;
  final double commission;
  final double deposit;
  final double profit;
  final double swap;
  final double withdrawal;

  TradeHistoryTotals({
    required this.balance,
    required this.commission,
    required this.deposit,
    required this.profit,
    required this.swap,
    required this.withdrawal,
  });

  factory TradeHistoryTotals.fromJson(Map<String, dynamic> json) {
    return TradeHistoryTotals(
      balance: _parseDouble(json['balance']),
      commission: _parseDouble(json['commission']),
      deposit: _parseDouble(json['deposit']),
      profit: _parseDouble(json['profit']),
      swap: _parseDouble(json['swap']),
      withdrawal: _parseDouble(json['withdrawal']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
