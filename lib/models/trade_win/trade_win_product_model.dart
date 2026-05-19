class TradeWinProductModel {
  final int id;
  final String name;
  final String category;
  final String description;
  final String imagePath;
  final double requiredLots;
  final double requiredPoints;
  final double prizeValue;
  final int stock;
  final String status;
  final int claimsCount;
  final double eligibleLots;
  final double availableLots;
  final double calculatedPoints;

  const TradeWinProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imagePath,
    required this.requiredLots,
    required this.requiredPoints,
    required this.prizeValue,
    required this.stock,
    required this.status,
    required this.claimsCount,
    required this.eligibleLots,
    required this.availableLots,
    required this.calculatedPoints,
  });

  factory TradeWinProductModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v, [double fallback = 0]) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    return TradeWinProductModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
      requiredLots: toDouble(json['required_lots'], 1),
      requiredPoints: toDouble(json['required_points'], 1),
      prizeValue: toDouble(json['prize_value']),
      stock: json['stock'] as int? ?? 0,
      status: json['status']?.toString() ?? 'active',
      claimsCount: json['claims_count'] as int? ?? 0,
      eligibleLots: toDouble(json['eligible_lots']),
      availableLots: toDouble(json['available_lots']),
      calculatedPoints: toDouble(json['calculated_points']),
    );
  }

  bool get isActive => status.toLowerCase() == 'active';

  bool get canRedeem =>
      isActive &&
      stock > 0 &&
      availableLots >= requiredLots &&
      calculatedPoints >= requiredPoints;

  double get progressFraction {
    if (requiredLots <= 0) return 0;
    return (availableLots / requiredLots).clamp(0.0, 1.0);
  }
}
