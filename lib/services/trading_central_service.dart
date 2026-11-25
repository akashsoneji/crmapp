import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/models/trading_central_model.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/utils/app_logger.dart';

/// Loads the Trading Central tools and the user's deposit-based access.
class TradingCentralService {
  TradingCentralService._();

  /// Throws with the API message so the screen can show it.
  static Future<TradingCentralSettings> fetch() async {
    final response = await ApiService.get(endpoint: ApiConstants.tradingCentral);
    final payload = response.success ? extractPayload(response.data) : null;
    if (payload == null) {
      AppLogger.error('TradingCentralService: Failed - ${response.message}');
      throw Exception(response.message);
    }
    return TradingCentralSettings.fromJson(payload);
  }

  /// Accepts the full body (`{status, data: {...}}`) or just the inner `data`,
  /// since the API client may already have unwrapped it.
  static Map<String, dynamic>? extractPayload(dynamic raw) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final top = asMap(raw);
    if (top == null) return null;
    if (top.containsKey('pages') || top.containsKey('can_access')) return top;
    return asMap(top['data']) ?? top;
  }
}
