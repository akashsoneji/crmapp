// IB Status Response Model
class IBStatusResponse {
  bool? status;
  bool? success;
  String? message;
  IBStatusData? data;

  IBStatusResponse({this.status, this.success, this.message, this.data});

  factory IBStatusResponse.fromJson(Map<String, dynamic> json) {
    return IBStatusResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? IBStatusData.fromJson(json['data']) : null,
    );
  }
}

class IBStatusData {
  String? ibStatus;
  int? profileCompletion;
  IBStageCompletion? stageCompletion;
  String? referenceLinkId;
  dynamic availableRebate;
  bool? isApproved;
  String? ibType;

  IBStatusData({
    this.ibStatus,
    this.profileCompletion,
    this.stageCompletion,
    this.referenceLinkId,
    this.availableRebate,
    this.isApproved,
    this.ibType,
  });

  factory IBStatusData.fromJson(Map<String, dynamic> json) {
    return IBStatusData(
      ibStatus: json['ib_status'],
      profileCompletion: json['profile_completion'],
      stageCompletion:
          json['stage_completion'] != null
              ? IBStageCompletion.fromJson(json['stage_completion'])
              : null,
      referenceLinkId: json['reference_link_id'],
      availableRebate: json['available_rebate'],
      isApproved: json['is_approved'],
      ibType: json['ib_type'],
    );
  }
}

class IBStageCompletion {
  String? mobileVerified;
  String? emailVerified;
  bool? personalDetails;
  bool? identityVerified;
  bool? addressProofVerified;

  IBStageCompletion({
    this.mobileVerified,
    this.emailVerified,
    this.personalDetails,
    this.identityVerified,
    this.addressProofVerified,
  });

  factory IBStageCompletion.fromJson(Map<String, dynamic> json) {
    return IBStageCompletion(
      mobileVerified: json['mobile_verified'],
      emailVerified: json['email_verified'],
      personalDetails: json['personal_details'],
      identityVerified: json['identity_verified'],
      addressProofVerified: json['address_proof_verified'],
    );
  }
}

// IB Application Response Model
class IBApplicationResponse {
  bool? status;
  bool? success;
  String? message;
  IBApplicationData? data;

  IBApplicationResponse({this.status, this.success, this.message, this.data});

  factory IBApplicationResponse.fromJson(Map<String, dynamic> json) {
    return IBApplicationResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null
              ? IBApplicationData.fromJson(json['data'])
              : null,
    );
  }
}

class IBApplicationData {
  int? applicationId;
  String? status;

  IBApplicationData({this.applicationId, this.status});

  factory IBApplicationData.fromJson(Map<String, dynamic> json) {
    return IBApplicationData(
      applicationId: json['application_id'],
      status: json['status'],
    );
  }
}

// IB Dashboard Response Model
class IBDashboardResponse {
  bool? status;
  bool? success;
  String? message;
  IBDashboardData? data;

  IBDashboardResponse({this.status, this.success, this.message, this.data});

  factory IBDashboardResponse.fromJson(Map<String, dynamic> json) {
    return IBDashboardResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null ? IBDashboardData.fromJson(json['data']) : null,
    );
  }
}

class IBDashboardData {
  UserIBDetails? userIBDetails;

  IBDashboardData({this.userIBDetails});

  factory IBDashboardData.fromJson(Map<String, dynamic> json) {
    return IBDashboardData(
      userIBDetails:
          json['userIBDetails'] != null
              ? UserIBDetails.fromJson(json['userIBDetails'])
              : null,
    );
  }
}

class UserIBDetails {
  String? availableRebate;
  String? referenceLinkId;
  String? referenceLinkNickname;
  String? referenceLinksVisitCount;

  UserIBDetails({
    this.availableRebate,
    this.referenceLinkId,
    this.referenceLinkNickname,
    this.referenceLinksVisitCount,
  });

  factory UserIBDetails.fromJson(Map<String, dynamic> json) {
    return UserIBDetails(
      availableRebate: json['available_rebate'],
      referenceLinkId: json['reference_link_id'],
      referenceLinkNickname: json['reference_link_nickname'],
      referenceLinksVisitCount: json['reference_links_visit_count'],
    );
  }
}

// IB Clients Response Model
class IBClientsResponse {
  bool? status;
  bool? success;
  String? message;
  List<IBClient>? data;

  IBClientsResponse({this.status, this.success, this.message, this.data});

  factory IBClientsResponse.fromJson(Map<String, dynamic> json) {
    return IBClientsResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null
              ? List<IBClient>.from(
                json['data'].map((x) => IBClient.fromJson(x)),
              )
              : null,
    );
  }
}

class IBClient {
  int? id;
  String? name;
  String? email;
  int? totalClients;
  double? totalDeposit;
  double? totalRebate;
  int? totalSubIBs;
  String? avatar;
  // Additional fields from API
  String? accountNumber;
  double? deposit;
  double? withdraw;
  double? lots;
  double? rebate;
  double? equity;
  String? status;
  String? ibType;
  bool? isSubIbApproved;
  int? subIbCount;

  IBClient({
    this.id,
    this.name,
    this.email,
    this.totalClients,
    this.totalDeposit,
    this.totalRebate,
    this.totalSubIBs,
    this.avatar,
    this.accountNumber,
    this.deposit,
    this.withdraw,
    this.lots,
    this.rebate,
    this.equity,
    this.status,
    this.ibType,
    this.isSubIbApproved,
    this.subIbCount,
  });

  factory IBClient.fromJson(Map<String, dynamic> json) {
    return IBClient(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      totalClients: json['totalClients'] ?? json['total_clients'],
      totalDeposit:
          json['totalDeposit'] != null
              ? (json['totalDeposit'] is int
                  ? json['totalDeposit'].toDouble()
                  : json['totalDeposit'])
              : (json['deposit'] != null
                  ? (json['deposit'] is int
                      ? json['deposit'].toDouble()
                      : json['deposit'])
                  : null),
      totalRebate:
          json['totalRebate'] != null
              ? (json['totalRebate'] is int
                  ? json['totalRebate'].toDouble()
                  : json['totalRebate'])
              : (json['rebate'] != null
                  ? (json['rebate'] is int
                      ? json['rebate'].toDouble()
                      : json['rebate'])
                  : null),
      totalSubIBs: json['totalSubIBs'] ?? json['total_sub_ibs'] ?? json['sub_ib_count'],
      avatar: json['avatar'],
      accountNumber: json['accountNumber'] ?? json['account_number'],
      deposit:
          json['deposit'] != null
              ? (json['deposit'] is int
                  ? json['deposit'].toDouble()
                  : json['deposit'])
              : null,
      withdraw:
          json['withdraw'] != null
              ? (json['withdraw'] is int
                  ? json['withdraw'].toDouble()
                  : json['withdraw'])
              : null,
      lots:
          json['lots'] != null
              ? (json['lots'] is int
                  ? json['lots'].toDouble()
                  : json['lots'])
              : null,
      rebate:
          json['rebate'] != null
              ? (json['rebate'] is int
                  ? json['rebate'].toDouble()
                  : json['rebate'])
              : null,
      equity:
          json['equity'] != null
              ? (json['equity'] is int
                  ? json['equity'].toDouble()
                  : json['equity'])
              : null,
      status: json['status'],
      ibType: json['ib_type'],
      isSubIbApproved: json['is_sub_ib_approved'],
      subIbCount: json['sub_ib_count'],
    );
  }
}

// IB Sub-IBs Response Model (same structure as Clients)
class IBSubIBsResponse {
  bool? status;
  bool? success;
  String? message;
  List<IBClient>? data; // Same structure as IBClient

  IBSubIBsResponse({this.status, this.success, this.message, this.data});

  factory IBSubIBsResponse.fromJson(Map<String, dynamic> json) {
    return IBSubIBsResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null
              ? List<IBClient>.from(
                json['data'].map((x) => IBClient.fromJson(x)),
              )
              : null,
    );
  }
}

// IB Trade History Response Model
class IBTradeHistoryResponse {
  bool? status;
  bool? success;
  String? message;
  List<IBTradeHistory>? data;

  IBTradeHistoryResponse({this.status, this.success, this.message, this.data});

  factory IBTradeHistoryResponse.fromJson(Map<String, dynamic> json) {
    return IBTradeHistoryResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null
              ? List<IBTradeHistory>.from(
                json['data'].map((x) => IBTradeHistory.fromJson(x)),
              )
              : null,
    );
  }
}

class IBTradeHistory {
  int? id;
  String? clientName;
  String? clientEmail;
  String? mt5Account;
  String? symbol;
  String? type;
  double? volume;
  String? commission;
  double? profit;
  double? openPrice;
  String? closePrice;
  String? openTime;
  String? closeTime;

  IBTradeHistory({
    this.id,
    this.clientName,
    this.clientEmail,
    this.mt5Account,
    this.symbol,
    this.type,
    this.volume,
    this.commission,
    this.profit,
    this.openPrice,
    this.closePrice,
    this.openTime,
    this.closeTime,
  });

  factory IBTradeHistory.fromJson(Map<String, dynamic> json) {
    return IBTradeHistory(
      id: json['id'],
      clientName: json['client_name'],
      clientEmail: json['client_email'],
      mt5Account: json['mt5_account'],
      symbol: json['symbol'],
      type: json['type'],
      volume:
          json['volume'] != null
              ? (json['volume'] is int
                  ? json['volume'].toDouble()
                  : json['volume'])
              : null,
      commission: json['commission'],
      profit:
          json['profit'] != null
              ? (json['profit'] is int
                  ? json['profit'].toDouble()
                  : json['profit'])
              : null,
      openPrice:
          json['open_price'] != null
              ? (json['open_price'] is int
                  ? json['open_price'].toDouble()
                  : json['open_price'])
              : null,
      closePrice: json['close_price'],
      openTime: json['open_time'],
      closeTime: json['close_time'],
    );
  }
}

// IB Stats Response Model
class IBStatsResponse {
  bool? status;
  bool? success;
  String? message;
  IBStatsData? data;

  IBStatsResponse({this.status, this.success, this.message, this.data});

  factory IBStatsResponse.fromJson(Map<String, dynamic> json) {
    return IBStatsResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? IBStatsData.fromJson(json['data']) : null,
    );
  }
}

class IBStatsData {
  double? totalDeposits;
  double? totalWithdrawals;
  double? totalCommissions;
  double? totalVolume;
  String? availableRebate;
  int? totalClients;
  double? totalWithdrawal;
  double? ibWithdrawalRebate;
  double? totalDeposited;
  double? totalEquity;
  String? totalRebateGenerated;
  int? ibPendingRequests;
  double? totalLots;
  int? marginLevelBelow100;
  int? referenceLinks;
  double? directCommission;
  double? subIbCommission;
  double? myCommission;
  double? totalCommission;
  double? commissionThisMonth;
  double? commissionThisQuarter;
  double? commissionThisYear;
  double? directCommissionThisMonth;
  double? subIbCommissionThisMonth;
  double? directCommissionThisQuarter;
  double? subIbCommissionThisQuarter;
  double? directCommissionThisYear;
  double? subIbCommissionThisYear;
  double? myCommissionThisMonth;
  double? myCommissionThisQuarter;
  double? myCommissionThisYear;

  IBStatsData({
    this.totalDeposits,
    this.totalWithdrawals,
    this.totalCommissions,
    this.totalVolume,
    this.availableRebate,
    this.totalClients,
    this.totalWithdrawal,
    this.ibWithdrawalRebate,
    this.totalDeposited,
    this.totalEquity,
    this.totalRebateGenerated,
    this.ibPendingRequests,
    this.totalLots,
    this.marginLevelBelow100,
    this.referenceLinks,
    this.directCommission,
    this.subIbCommission,
    this.myCommission,
    this.totalCommission,
    this.commissionThisMonth,
    this.commissionThisQuarter,
    this.commissionThisYear,
    this.directCommissionThisMonth,
    this.subIbCommissionThisMonth,
    this.directCommissionThisQuarter,
    this.subIbCommissionThisQuarter,
    this.directCommissionThisYear,
    this.subIbCommissionThisYear,
    this.myCommissionThisMonth,
    this.myCommissionThisQuarter,
    this.myCommissionThisYear,
  });

  factory IBStatsData.fromJson(Map<String, dynamic> json) {
    return IBStatsData(
      totalDeposits:
          json['total_deposits'] != null
              ? (json['total_deposits'] is int
                  ? json['total_deposits'].toDouble()
                  : json['total_deposits'])
              : null,
      totalWithdrawals:
          json['total_withdrawals'] != null
              ? (json['total_withdrawals'] is int
                  ? json['total_withdrawals'].toDouble()
                  : json['total_withdrawals'])
              : null,
      totalCommissions:
          json['total_commissions'] != null
              ? (json['total_commissions'] is int
                  ? json['total_commissions'].toDouble()
                  : json['total_commissions'])
              : null,
      totalVolume:
          json['total_volume'] != null
              ? (json['total_volume'] is int
                  ? json['total_volume'].toDouble()
                  : json['total_volume'])
              : null,
      availableRebate: json['available_rebate']?.toString(),
      totalClients: json['total_clients'],
      totalWithdrawal:
          json['total_withdrawal'] != null
              ? (json['total_withdrawal'] is int
                  ? json['total_withdrawal'].toDouble()
                  : json['total_withdrawal'])
              : (json['total_withdrawals'] != null
                  ? (json['total_withdrawals'] is int
                      ? json['total_withdrawals'].toDouble()
                      : json['total_withdrawals'])
                  : null),
      ibWithdrawalRebate:
          json['ib_withdrawal_rebate'] != null
              ? (json['ib_withdrawal_rebate'] is int
                  ? json['ib_withdrawal_rebate'].toDouble()
                  : json['ib_withdrawal_rebate'])
              : null,
      totalDeposited:
          json['total_deposited'] != null
              ? (json['total_deposited'] is int
                  ? json['total_deposited'].toDouble()
                  : json['total_deposited'])
              : (json['total_deposit'] != null
                  ? (json['total_deposit'] is int
                      ? json['total_deposit'].toDouble()
                      : json['total_deposit'])
                  : null),
      totalEquity:
          json['total_equity'] != null
              ? (json['total_equity'] is int
                  ? json['total_equity'].toDouble()
                  : json['total_equity'])
              : (json['totalEquity'] != null
                  ? (json['totalEquity'] is int
                      ? json['totalEquity'].toDouble()
                      : json['totalEquity'])
                  : null),
      totalRebateGenerated:
          json['total_rebate_generated']?.toString() ??
          json['totalRebate']?.toString(),
      ibPendingRequests: json['ib_pending_requests'],
      totalLots:
          json['total_lots'] != null
              ? (json['total_lots'] is int
                  ? json['total_lots'].toDouble()
                  : json['total_lots'])
              : null,
      marginLevelBelow100: json['margin_level_below_100'],
      referenceLinks: json['reference_links'],
      directCommission:
          json['direct_commission'] != null
              ? (json['direct_commission'] is int
                  ? json['direct_commission'].toDouble()
                  : json['direct_commission'])
              : null,
      subIbCommission:
          json['sub_ib_commission'] != null
              ? (json['sub_ib_commission'] is int
                  ? json['sub_ib_commission'].toDouble()
                  : json['sub_ib_commission'])
              : null,
      myCommission:
          json['my_commission'] != null
              ? (json['my_commission'] is int
                  ? json['my_commission'].toDouble()
                  : json['my_commission'])
              : null,
      totalCommission:
          json['total_commission'] != null
              ? (json['total_commission'] is int
                  ? json['total_commission'].toDouble()
                  : json['total_commission'])
              : null,
      commissionThisMonth:
          json['commission_this_month'] != null
              ? (json['commission_this_month'] is int
                  ? json['commission_this_month'].toDouble()
                  : json['commission_this_month'])
              : null,
      commissionThisQuarter:
          json['commission_this_quarter'] != null
              ? (json['commission_this_quarter'] is int
                  ? json['commission_this_quarter'].toDouble()
                  : json['commission_this_quarter'])
              : null,
      commissionThisYear:
          json['commission_this_year'] != null
              ? (json['commission_this_year'] is int
                  ? json['commission_this_year'].toDouble()
                  : json['commission_this_year'])
              : null,
      directCommissionThisMonth:
          json['direct_commission_this_month'] != null
              ? (json['direct_commission_this_month'] is int
                  ? json['direct_commission_this_month'].toDouble()
                  : json['direct_commission_this_month'])
              : null,
      subIbCommissionThisMonth:
          json['sub_ib_commission_this_month'] != null
              ? (json['sub_ib_commission_this_month'] is int
                  ? json['sub_ib_commission_this_month'].toDouble()
                  : json['sub_ib_commission_this_month'])
              : null,
      directCommissionThisQuarter:
          json['direct_commission_this_quarter'] != null
              ? (json['direct_commission_this_quarter'] is int
                  ? json['direct_commission_this_quarter'].toDouble()
                  : json['direct_commission_this_quarter'])
              : null,
      subIbCommissionThisQuarter:
          json['sub_ib_commission_this_quarter'] != null
              ? (json['sub_ib_commission_this_quarter'] is int
                  ? json['sub_ib_commission_this_quarter'].toDouble()
                  : json['sub_ib_commission_this_quarter'])
              : null,
      directCommissionThisYear:
          json['direct_commission_this_year'] != null
              ? (json['direct_commission_this_year'] is int
                  ? json['direct_commission_this_year'].toDouble()
                  : json['direct_commission_this_year'])
              : null,
      subIbCommissionThisYear:
          json['sub_ib_commission_this_year'] != null
              ? (json['sub_ib_commission_this_year'] is int
                  ? json['sub_ib_commission_this_year'].toDouble()
                  : json['sub_ib_commission_this_year'])
              : null,
      myCommissionThisMonth:
          json['my_commission_this_month'] != null
              ? (json['my_commission_this_month'] is int
                  ? json['my_commission_this_month'].toDouble()
                  : json['my_commission_this_month'])
              : null,
      myCommissionThisQuarter:
          json['my_commission_this_quarter'] != null
              ? (json['my_commission_this_quarter'] is int
                  ? json['my_commission_this_quarter'].toDouble()
                  : json['my_commission_this_quarter'])
              : null,
      myCommissionThisYear:
          json['my_commission_this_year'] != null
              ? (json['my_commission_this_year'] is int
                  ? json['my_commission_this_year'].toDouble()
                  : json['my_commission_this_year'])
              : null,
    );
  }
}

// IB Structure Response Model
class IBStructureResponse {
  bool? status;
  bool? success;
  String? message;
  IBStructureData? data;

  IBStructureResponse({this.status, this.success, this.message, this.data});

  factory IBStructureResponse.fromJson(Map<String, dynamic> json) {
    return IBStructureResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data:
          json['data'] != null ? IBStructureData.fromJson(json['data']) : null,
    );
  }
}

class IBStructureData {
  int? groupId;
  String? groupName;
  List<dynamic>? mt5Groups;

  IBStructureData({this.groupId, this.groupName, this.mt5Groups});

  factory IBStructureData.fromJson(Map<String, dynamic> json) {
    return IBStructureData(
      groupId: json['group_id'],
      groupName: json['group_name'],
      mt5Groups: json['mt5_groups'] != null ? json['mt5_groups'] : null,
    );
  }
}

// IB Approval Request Response Model
class IBApprovalRequestsResponse {
  bool? status;
  bool? success;
  String? message;
  List<IBApprovalRequest>? data;

  IBApprovalRequestsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory IBApprovalRequestsResponse.fromJson(Map<String, dynamic> json) {
    return IBApprovalRequestsResponse(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? List<IBApprovalRequest>.from(
              json['data'].map((x) => IBApprovalRequest.fromJson(x)),
            )
          : null,
    );
  }
}

class IBApprovalRequest {
  int? id;
  int? userId;
  String? status;
  String? expectedClient;
  List<String>? country;
  int? subIbId;
  String? createdAt;
  String? updatedAt;
  IBApprovalRequestUser? user;

  IBApprovalRequest({
    this.id,
    this.userId,
    this.status,
    this.expectedClient,
    this.country,
    this.subIbId,
    this.createdAt,
    this.updatedAt,
    this.user,
  });

  factory IBApprovalRequest.fromJson(Map<String, dynamic> json) {
    return IBApprovalRequest(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'],
      expectedClient: json['expected_client']?.toString(),
      country: json['country'] != null
          ? List<String>.from(json['country'])
          : null,
      subIbId: json['sub_ib_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      user: json['user'] != null
          ? IBApprovalRequestUser.fromJson(json['user'])
          : null,
    );
  }
}

class IBApprovalRequestUser {
  int? id;
  String? firstName;
  String? lastName;
  String? email;

  IBApprovalRequestUser({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory IBApprovalRequestUser.fromJson(Map<String, dynamic> json) {
    return IBApprovalRequestUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
    );
  }
}
