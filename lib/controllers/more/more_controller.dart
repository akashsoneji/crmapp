import 'package:get/get.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';



import 'dart:convert';

import '../../constants/api_const.dart';

DashboardModel dashboardModelFromJson(String str) => DashboardModel.fromJson(json.decode(str));

String dashboardModelToJson(DashboardModel data) => json.encode(data.toJson());

class DashboardModel {
  final bool? status;
  final String? message;
  final Data? data;

  DashboardModel({
    this.status,
    this.message,
    this.data,
  });

  DashboardModel copyWith({
    bool? status,
    String? message,
    Data? data,
  }) =>
      DashboardModel(
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
    status: json["status"],
    message: json["message"],
    data: json["data"] == null ? null : Data.fromJson(json["data"]),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  final User? user;
  final int? profileCompletionPercentage;
  final StageCompletion? stageCompletion;

  Data({
    this.user,
    this.profileCompletionPercentage,
    this.stageCompletion,
  });

  Data copyWith({
    User? user,
    int? profileCompletionPercentage,
    StageCompletion? stageCompletion,
  }) =>
      Data(
        user: user ?? this.user,
        profileCompletionPercentage: profileCompletionPercentage ?? this.profileCompletionPercentage,
        stageCompletion: stageCompletion ?? this.stageCompletion,
      );

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    profileCompletionPercentage: json["profile_completion_percentage"],
    stageCompletion: json["stage_completion"] == null ? null : StageCompletion.fromJson(json["stage_completion"]),
  );

  Map<String, dynamic> toJson() => {
    "user": user?.toJson(),
    "profile_completion_percentage": profileCompletionPercentage,
    "stage_completion": stageCompletion?.toJson(),
  };
}

class StageCompletion {
  final DateTime? mobileVerified;
  final DateTime? emailVerified;
  final bool? personalDetails;
  final bool? identityVerified;
  final bool? addressProofVerified;

  StageCompletion({
    this.mobileVerified,
    this.emailVerified,
    this.personalDetails,
    this.identityVerified,
    this.addressProofVerified,
  });

  StageCompletion copyWith({
    DateTime? mobileVerified,
    DateTime? emailVerified,
    bool? personalDetails,
    bool? identityVerified,
    bool? addressProofVerified,
  }) =>
      StageCompletion(
        mobileVerified: mobileVerified ?? this.mobileVerified,
        emailVerified: emailVerified ?? this.emailVerified,
        personalDetails: personalDetails ?? this.personalDetails,
        identityVerified: identityVerified ?? this.identityVerified,
        addressProofVerified: addressProofVerified ?? this.addressProofVerified,
      );

  factory StageCompletion.fromJson(Map<String, dynamic> json) => StageCompletion(
    mobileVerified: json["mobile_verified"] == null ? null : DateTime.parse(json["mobile_verified"]),
    emailVerified: json["email_verified"] == null ? null : DateTime.parse(json["email_verified"]),
    personalDetails: json["personal_details"],
    identityVerified: json["identity_verified"],
    addressProofVerified: json["address_proof_verified"],
  );

  Map<String, dynamic> toJson() => {
    "mobile_verified": mobileVerified?.toIso8601String(),
    "email_verified": emailVerified?.toIso8601String(),
    "personal_details": personalDetails,
    "identity_verified": identityVerified,
    "address_proof_verified": addressProofVerified,
  };
}

class User {
  final int? id;
  final String? email;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userSlug;
  final String? firstName;
  final String? lastName;
  final String? mobile;
  final DateTime? mobileVerifiedAt;
  final String? status;
  final int? regComplete;
  final String? deletedAt;
  final Userdetails? userDetails;
  final Userdetails? userdetails;

  User({
    this.id,
    this.email,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.userSlug,
    this.firstName,
    this.lastName,
    this.mobile,
    this.mobileVerifiedAt,
    this.status,
    this.regComplete,
    this.deletedAt,
    this.userDetails,
    this.userdetails,
  });

  User copyWith({
    int? id,
    String? email,
    DateTime? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userSlug,
    String? firstName,
    String? lastName,
    String? mobile,
    DateTime? mobileVerifiedAt,
    String? status,
    int? regComplete,
    String? deletedAt,
    Userdetails? userDetails,
    Userdetails? userdetails,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        userSlug: userSlug ?? this.userSlug,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        mobile: mobile ?? this.mobile,
        mobileVerifiedAt: mobileVerifiedAt ?? this.mobileVerifiedAt,
        status: status ?? this.status,
        regComplete: regComplete ?? this.regComplete,
        deletedAt: deletedAt ?? this.deletedAt,
        userDetails: userDetails ?? this.userDetails,
        userdetails: userdetails ?? this.userdetails,
      );

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    email: json["email"],
    emailVerifiedAt: json["email_verified_at"] == null ? null : DateTime.parse(json["email_verified_at"]),
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    userSlug: json["user_slug"],
    firstName: json["first_name"],
    lastName: json["last_name"],
    mobile: json["mobile"],
    mobileVerifiedAt: json["mobile_verified_at"] == null ? null : DateTime.parse(json["mobile_verified_at"]),
    status: json["status"],
    regComplete: json["reg_complete"],
    deletedAt: json["deleted_at"],
    userDetails: json["user_details"] == null ? null : Userdetails.fromJson(json["user_details"]),
    userdetails: json["userdetails"] == null ? null : Userdetails.fromJson(json["userdetails"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "email": email,
    "email_verified_at": emailVerifiedAt?.toIso8601String(),
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "user_slug": userSlug,
    "first_name": firstName,
    "last_name": lastName,
    "mobile": mobile,
    "mobile_verified_at": mobileVerifiedAt?.toIso8601String(),
    "status": status,
    "reg_complete": regComplete,
    "deleted_at": deletedAt,
    "user_details": userDetails?.toJson(),
    "userdetails": userdetails?.toJson(),
  };
}

class Userdetails {
  final int? id;
  final int? userId;
  final String? title;
  final String? gender;
  final String? dob;
  final String? altMobile;
  final String? altEmail;
  final String? registerSource;
  final String? lastLoginAt;
  final String? kycStatus;
  final String? kycType;
  final String? kycVerifiedBy;
  final int? byPassKyc;
  final String? kycVerifiedAt;
  final String? ibAffiliateRefcode;
  final String? isIbAffiliate;
  final String? ibAffiliateDateAt;
  final int? managerId;
  final DateTime? managerAssignedAt;
  final String? branchId;
  final String? branchCode;
  final String? branchAssignedAt;
  final String? ibId;
  final String? affiliateId;
  final String? campaignId;
  final String? depositStatus;
  final String? withdrawalStatus;
  final String? transferStatus;
  final String? bonusStatus;
  final String? notes;
  final String? nationality;
  final String? country;
  final String? state;
  final String? city;
  final String? address1;
  final String? address2;
  final String? postcode;
  final String? language;
  final String? isUsCitizen;
  final String? isPoliticallyExposed;
  final String? industry;
  final String? taxIdentificationNumber;
  final String? mt5AccountLimit;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? deletedAt;
  final String? personalInfoVerifiedBy;
  final String? personalInfoVerifiedAt;
  final String? identityVerifiedBy;
  final String? identityVerifiedAt;
  final String? addressVerifiedBy;
  final String? addressVerifiedAt;
  final String? kycVerificationLevel;
  final String? kycVerificationNotes;
  final String? branch;
  final String? countryName;
  final String? stateName;
  final String? cityName;

  Userdetails({
    this.id,
    this.userId,
    this.title,
    this.gender,
    this.dob,
    this.altMobile,
    this.altEmail,
    this.registerSource,
    this.lastLoginAt,
    this.kycStatus,
    this.kycType,
    this.kycVerifiedBy,
    this.byPassKyc,
    this.kycVerifiedAt,
    this.ibAffiliateRefcode,
    this.isIbAffiliate,
    this.ibAffiliateDateAt,
    this.managerId,
    this.managerAssignedAt,
    this.branchId,
    this.branchCode,
    this.branchAssignedAt,
    this.ibId,
    this.affiliateId,
    this.campaignId,
    this.depositStatus,
    this.withdrawalStatus,
    this.transferStatus,
    this.bonusStatus,
    this.notes,
    this.nationality,
    this.country,
    this.state,
    this.city,
    this.address1,
    this.address2,
    this.postcode,
    this.language,
    this.isUsCitizen,
    this.isPoliticallyExposed,
    this.industry,
    this.taxIdentificationNumber,
    this.mt5AccountLimit,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.personalInfoVerifiedBy,
    this.personalInfoVerifiedAt,
    this.identityVerifiedBy,
    this.identityVerifiedAt,
    this.addressVerifiedBy,
    this.addressVerifiedAt,
    this.kycVerificationLevel,
    this.kycVerificationNotes,
    this.branch,
    this.countryName,
    this.stateName,
    this.cityName,
  });

  Userdetails copyWith({
    int? id,
    int? userId,
    String? title,
    String? gender,
    String? dob,
    String? altMobile,
    String? altEmail,
    String? registerSource,
    String? lastLoginAt,
    String? kycStatus,
    String? kycType,
    String? kycVerifiedBy,
    int? byPassKyc,
    String? kycVerifiedAt,
    String? ibAffiliateRefcode,
    String? isIbAffiliate,
    String? ibAffiliateDateAt,
    int? managerId,
    DateTime? managerAssignedAt,
    String? branchId,
    String? branchCode,
    String? branchAssignedAt,
    String? ibId,
    String? affiliateId,
    String? campaignId,
    String? depositStatus,
    String? withdrawalStatus,
    String? transferStatus,
    String? bonusStatus,
    String? notes,
    String? nationality,
    String? country,
    String? state,
    String? city,
    String? address1,
    String? address2,
    String? postcode,
    String? language,
    String? isUsCitizen,
    String? isPoliticallyExposed,
    String? industry,
    String? taxIdentificationNumber,
    String? mt5AccountLimit,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deletedAt,
    String? personalInfoVerifiedBy,
    String? personalInfoVerifiedAt,
    String? identityVerifiedBy,
    String? identityVerifiedAt,
    String? addressVerifiedBy,
    String? addressVerifiedAt,
    String? kycVerificationLevel,
    String? kycVerificationNotes,
    String? branch,
    String? countryName,
    String? stateName,
    String? cityName,
  }) =>
      Userdetails(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        gender: gender ?? this.gender,
        dob: dob ?? this.dob,
        altMobile: altMobile ?? this.altMobile,
        altEmail: altEmail ?? this.altEmail,
        registerSource: registerSource ?? this.registerSource,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        kycStatus: kycStatus ?? this.kycStatus,
        kycType: kycType ?? this.kycType,
        kycVerifiedBy: kycVerifiedBy ?? this.kycVerifiedBy,
        byPassKyc: byPassKyc ?? this.byPassKyc,
        kycVerifiedAt: kycVerifiedAt ?? this.kycVerifiedAt,
        ibAffiliateRefcode: ibAffiliateRefcode ?? this.ibAffiliateRefcode,
        isIbAffiliate: isIbAffiliate ?? this.isIbAffiliate,
        ibAffiliateDateAt: ibAffiliateDateAt ?? this.ibAffiliateDateAt,
        managerId: managerId ?? this.managerId,
        managerAssignedAt: managerAssignedAt ?? this.managerAssignedAt,
        branchId: branchId ?? this.branchId,
        branchCode: branchCode ?? this.branchCode,
        branchAssignedAt: branchAssignedAt ?? this.branchAssignedAt,
        ibId: ibId ?? this.ibId,
        affiliateId: affiliateId ?? this.affiliateId,
        campaignId: campaignId ?? this.campaignId,
        depositStatus: depositStatus ?? this.depositStatus,
        withdrawalStatus: withdrawalStatus ?? this.withdrawalStatus,
        transferStatus: transferStatus ?? this.transferStatus,
        bonusStatus: bonusStatus ?? this.bonusStatus,
        notes: notes ?? this.notes,
        nationality: nationality ?? this.nationality,
        country: country ?? this.country,
        state: state ?? this.state,
        city: city ?? this.city,
        address1: address1 ?? this.address1,
        address2: address2 ?? this.address2,
        postcode: postcode ?? this.postcode,
        language: language ?? this.language,
        isUsCitizen: isUsCitizen ?? this.isUsCitizen,
        isPoliticallyExposed: isPoliticallyExposed ?? this.isPoliticallyExposed,
        industry: industry ?? this.industry,
        taxIdentificationNumber: taxIdentificationNumber ?? this.taxIdentificationNumber,
        mt5AccountLimit: mt5AccountLimit ?? this.mt5AccountLimit,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        personalInfoVerifiedBy: personalInfoVerifiedBy ?? this.personalInfoVerifiedBy,
        personalInfoVerifiedAt: personalInfoVerifiedAt ?? this.personalInfoVerifiedAt,
        identityVerifiedBy: identityVerifiedBy ?? this.identityVerifiedBy,
        identityVerifiedAt: identityVerifiedAt ?? this.identityVerifiedAt,
        addressVerifiedBy: addressVerifiedBy ?? this.addressVerifiedBy,
        addressVerifiedAt: addressVerifiedAt ?? this.addressVerifiedAt,
        kycVerificationLevel: kycVerificationLevel ?? this.kycVerificationLevel,
        kycVerificationNotes: kycVerificationNotes ?? this.kycVerificationNotes,
        branch: branch ?? this.branch,
        countryName: countryName ?? this.countryName,
        stateName: stateName ?? this.stateName,
        cityName: cityName ?? this.cityName,
      );

  factory Userdetails.fromJson(Map<String, dynamic> json) => Userdetails(
    id: json["id"],
    userId: json["user_id"],
    title: json["title"],
    gender: json["gender"],
    dob: json["dob"],
    altMobile: json["alt_mobile"],
    altEmail: json["alt_email"],
    registerSource: json["register_source"],
    lastLoginAt: json["last_login_at"],
    kycStatus: json["kyc_status"],
    kycType: json["kyc_type"],
    kycVerifiedBy: json["kyc_verified_by"],
    byPassKyc: json["by_pass_kyc"],
    kycVerifiedAt: json["kyc_verified_at"],
    ibAffiliateRefcode: json["ib_affiliate_refcode"],
    isIbAffiliate: json["is_ib_affiliate"],
    ibAffiliateDateAt: json["ib_affiliate_date_at"],
    managerId: json["manager_id"],
    managerAssignedAt: json["manager_assigned_at"] == null ? null : DateTime.parse(json["manager_assigned_at"]),
    branchId: json["branch_id"],
    branchCode: json["branch_code"],
    branchAssignedAt: json["branch_assigned_at"],
    ibId: json["ib_id"],
    affiliateId: json["affiliate_id"],
    campaignId: json["campaign_id"],
    depositStatus: json["deposit_status"],
    withdrawalStatus: json["withdrawal_status"],
    transferStatus: json["transfer_status"],
    bonusStatus: json["bonus_status"],
    notes: json["notes"],
    nationality: json["nationality"],
    country: json["country"],
    state: json["state"],
    city: json["city"],
    address1: json["address_1"],
    address2: json["address_2"],
    postcode: json["postcode"],
    language: json["language"],
    isUsCitizen: json["is_us_citizen"],
    isPoliticallyExposed: json["is_politically_exposed"],
    industry: json["industry"],
    taxIdentificationNumber: json["tax_identification_number"],
    mt5AccountLimit: json["mt5_account_limit"],
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    deletedAt: json["deleted_at"],
    personalInfoVerifiedBy: json["personal_info_verified_by"],
    personalInfoVerifiedAt: json["personal_info_verified_at"],
    identityVerifiedBy: json["identity_verified_by"],
    identityVerifiedAt: json["identity_verified_at"],
    addressVerifiedBy: json["address_verified_by"],
    addressVerifiedAt: json["address_verified_at"],
    kycVerificationLevel: json["kyc_verification_level"],
    kycVerificationNotes: json["kyc_verification_notes"],
    branch: json["branch"],
    countryName: json["country_name"],
    stateName: json["state_name"],
    cityName: json["city_name"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "title": title,
    "gender": gender,
    "dob": dob,
    "alt_mobile": altMobile,
    "alt_email": altEmail,
    "register_source": registerSource,
    "last_login_at": lastLoginAt,
    "kyc_status": kycStatus,
    "kyc_type": kycType,
    "kyc_verified_by": kycVerifiedBy,
    "by_pass_kyc": byPassKyc,
    "kyc_verified_at": kycVerifiedAt,
    "ib_affiliate_refcode": ibAffiliateRefcode,
    "is_ib_affiliate": isIbAffiliate,
    "ib_affiliate_date_at": ibAffiliateDateAt,
    "manager_id": managerId,
    "manager_assigned_at": managerAssignedAt?.toIso8601String(),
    "branch_id": branchId,
    "branch_code": branchCode,
    "branch_assigned_at": branchAssignedAt,
    "ib_id": ibId,
    "affiliate_id": affiliateId,
    "campaign_id": campaignId,
    "deposit_status": depositStatus,
    "withdrawal_status": withdrawalStatus,
    "transfer_status": transferStatus,
    "bonus_status": bonusStatus,
    "notes": notes,
    "nationality": nationality,
    "country": country,
    "state": state,
    "city": city,
    "address_1": address1,
    "address_2": address2,
    "postcode": postcode,
    "language": language,
    "is_us_citizen": isUsCitizen,
    "is_politically_exposed": isPoliticallyExposed,
    "industry": industry,
    "tax_identification_number": taxIdentificationNumber,
    "mt5_account_limit": mt5AccountLimit,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt,
    "personal_info_verified_by": personalInfoVerifiedBy,
    "personal_info_verified_at": personalInfoVerifiedAt,
    "identity_verified_by": identityVerifiedBy,
    "identity_verified_at": identityVerifiedAt,
    "address_verified_by": addressVerifiedBy,
    "address_verified_at": addressVerifiedAt,
    "kyc_verification_level": kycVerificationLevel,
    "kyc_verification_notes": kycVerificationNotes,
    "branch": branch,
    "country_name": countryName,
    "state_name": stateName,
    "city_name": cityName,
  };
}


class MoreController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Store whole model
  final Rxn<DashboardModel> dashboardModel = Rxn<DashboardModel>();

  @override
  void onInit() {
    super.onInit();
    loadMoreScreenData();
  }

  Future<void> loadMoreScreenData() async {
    final token = await SecureStorageService.getAuthToken();
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await ApiService.get(
        endpoint: ApiConstants.dashboard,
        token: token,
      );

      if (response.success) {
        final data = response.data;

        if (data['status'] == true && data['data'] != null) {
          dashboardModel.value = DashboardModel.fromJson(data);
          print('More screen data loaded successfully');
        } else {
          errorMessage.value = data['message'] ?? 'Failed to load data';
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to load data';
        print('API Error: ${response.message} - ${response.data}');
      }
    } catch (e) {
      errorMessage.value = 'Error loading more screen data: $e';
      print('Exception in loadMoreScreenData: $e');
    } finally {
      isLoading.value = false;
    }
  }
}