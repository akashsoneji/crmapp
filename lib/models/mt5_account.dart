class MT5Account {
  final int userId;
  final String metaAccountNumber;
  final String mt5NickName;
  final String masterGroupId;
  final int leverageId;
  final int primaryAccount;
  final String accountType;
  final String balance;
  final String credit;
  final String equity;
  final String margin;
  final String freeMargin;
  final String marginLevel;
  final String profit;
  final int totalDeposit;
  final int totalWithdrawal;
  final int commission;
  final int swap;

  MT5Account({
    required this.userId,
    required this.metaAccountNumber,
    required this.mt5NickName,
    required this.masterGroupId,
    required this.leverageId,
    required this.primaryAccount,
    required this.accountType,
    required this.balance,
    required this.credit,
    required this.equity,
    required this.margin,
    required this.freeMargin,
    required this.marginLevel,
    required this.profit,
    required this.totalDeposit,
    required this.totalWithdrawal,
    required this.commission,
    required this.swap,
  });

  factory MT5Account.fromJson(Map<String, dynamic> json) {
    return MT5Account(
      userId: _parseInt(json['user_id']) ?? 0,
      metaAccountNumber: json['meta_account_number']?.toString() ?? '',
      mt5NickName: json['mt5_nick_name']?.toString() ?? '',
      masterGroupId: json['master_group_id']?.toString() ?? '',
      leverageId: _parseInt(json['leverage_id']) ?? 0,
      primaryAccount: _parseInt(json['primary_account']) ?? 0,
      accountType: json['account_type']?.toString() ?? '',
      balance: json['balance']?.toString() ?? '0.00',
      credit: json['credit']?.toString() ?? '0.00',
      equity: json['equity']?.toString() ?? '0.00',
      margin: json['margin']?.toString() ?? '0.00',
      freeMargin: json['free_margin']?.toString() ?? '0.00',
      marginLevel: json['margin_level']?.toString() ?? '0.00',
      profit: json['profit']?.toString() ?? '0.00',
      totalDeposit: _parseInt(json['total_deposit']) ?? 0,
      totalWithdrawal: _parseInt(json['total_withdrawal']) ?? 0,
      commission: _parseInt(json['commission']) ?? 0,
      swap: _parseInt(json['swap']) ?? 0,
    );
  }

  // Helper method to safely parse int from dynamic value
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'meta_account_number': metaAccountNumber,
      'mt5_nick_name': mt5NickName,
      'master_group_id': masterGroupId,
      'leverage_id': leverageId,
      'primary_account': primaryAccount,
      'account_type': accountType,
      'balance': balance,
      'credit': credit,
      'equity': equity,
      'margin': margin,
      'free_margin': freeMargin,
      'margin_level': marginLevel,
      'profit': profit,
      'total_deposit': totalDeposit,
      'total_withdrawal': totalWithdrawal,
      'commission': commission,
      'swap': swap,
    };
  }

  // Helper method to check if this is a real account
  bool get isRealAccount => accountType == 'live';

  // Helper method to check if this is a demo account
  bool get isDemoAccount => accountType == 'demo';

  // Helper method to check if this is the primary account
  bool get isPrimaryAccount => primaryAccount == 1;
}
