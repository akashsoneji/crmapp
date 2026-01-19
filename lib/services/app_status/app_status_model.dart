/// Model for app status API response
class AppStatusModel {
  final String appVersion;
  final bool isUnderMaintenance;

  AppStatusModel({
    required this.appVersion,
    required this.isUnderMaintenance,
  });

  /// Create from JSON map
  factory AppStatusModel.fromJson(Map<String, dynamic> json) {
    return AppStatusModel(
      appVersion: json['app_version'] as String? ?? '1.0.0',
      isUnderMaintenance: json['is_under_maintenance'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'app_version': appVersion,
      'is_under_maintenance': isUnderMaintenance,
    };
  }

  @override
  String toString() {
    return 'AppStatusModel(appVersion: $appVersion, isUnderMaintenance: $isUnderMaintenance)';
  }
}
