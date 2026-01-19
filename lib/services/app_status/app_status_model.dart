/// Model for app status API response
class AppStatusModel {
  final String appVersion;
  final bool isUnderMaintenance;
  final bool isForceUpdate;

  AppStatusModel({
    required this.appVersion,
    required this.isUnderMaintenance,
    required this.isForceUpdate,
  });

  /// Create from JSON map
  factory AppStatusModel.fromJson(Map<String, dynamic> json) {
    return AppStatusModel(
      appVersion: json['app_version'] as String? ?? '1.0.0',
      isUnderMaintenance: json['is_under_maintenance'] as bool? ?? false,
      isForceUpdate: json['is_force_update'] as bool? ?? true, // Default to true for backward compatibility
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'app_version': appVersion,
      'is_under_maintenance': isUnderMaintenance,
      'is_force_update': isForceUpdate,
    };
  }

  @override
  String toString() {
    return 'AppStatusModel(appVersion: $appVersion, isUnderMaintenance: $isUnderMaintenance, isForceUpdate: $isForceUpdate)';
  }
}
