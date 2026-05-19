import 'trade_win_shipping_details_model.dart';
import 'trade_win_spent_detail_model.dart';

class TradeWinPastWinModel {
  final int id;
  final String productName;
  final String category;
  final String imagePath;
  final String status;
  final String claimDate;
  final String statusDate;
  final String? adminNote;
  final double prizeValue;
  final TradeWinShippingDetailsModel shippingDetails;
  final List<TradeWinSpentDetailModel> spentDetailsReadable;

  const TradeWinPastWinModel({
    required this.id,
    required this.productName,
    required this.category,
    required this.imagePath,
    required this.status,
    required this.claimDate,
    required this.statusDate,
    this.adminNote,
    required this.prizeValue,
    required this.shippingDetails,
    required this.spentDetailsReadable,
  });

  factory TradeWinPastWinModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    final spentRaw = json['spent_details_readable'];
    final spent = spentRaw is List
        ? spentRaw
            .whereType<Map>()
            .map(
              (e) => TradeWinSpentDetailModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <TradeWinSpentDetailModel>[];

    final shippingRaw = json['shipping_details'];
    final shipping = shippingRaw is Map
        ? TradeWinShippingDetailsModel.fromJson(
          Map<String, dynamic>.from(shippingRaw),
        )
        : const TradeWinShippingDetailsModel();

    return TradeWinPastWinModel(
      id: json['id'] as int? ?? 0,
      productName: json['product_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imagePath: json['image_path']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      claimDate: json['claim_date']?.toString() ?? '',
      statusDate: json['status_date']?.toString() ?? '',
      adminNote: json['admin_note']?.toString(),
      prizeValue: toDouble(json['prize_value']),
      shippingDetails: shipping,
      spentDetailsReadable: spent,
    );
  }

  String get referenceCode => 'INDP-$id';
}
