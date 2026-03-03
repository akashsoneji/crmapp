import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:crm_app/models/tenax_broker_model.dart';
import 'package:crm_app/utils/encryption_helper.dart';

class TenaxBrokerService {
  static const String _url = 'https://broker.tenaxcode.com/api/mobile/brokers';
  static const Duration _timeout = Duration(seconds: 30);

  Future<List<TenaxBrokerModel>> fetchBrokers({String search = ''}) async {
    final params = <String, String>{
      'q': search.trim(),
    };

    final uri = Uri.parse(_url).replace(queryParameters: params);
    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Broker API failed with status ${response.statusCode}');
    }

    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw const FormatException('Broker API response must be an object');
    }

    final status = responseBody['status'];
    if (status != true) {
      throw Exception(responseBody['message'] ?? 'Unable to fetch brokers');
    }

    final dynamic data = responseBody['data'];
    final brokersJson = _extractBrokerList(data);

    return brokersJson
        .whereType<Map<String, dynamic>>()
        .map(TenaxBrokerModel.fromJson)
        .where((broker) => broker.displayName.trim().isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> fetchBrokerConfigBySlug(String slug) async {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) {
      throw const FormatException('Broker slug is missing');
    }

    final uri = Uri.parse('$_url/$normalizedSlug');
    final response = await http
        .get(
          uri,
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Broker detail API failed with status ${response.statusCode}',
      );
    }

    final responseBody = jsonDecode(response.body);
    if (responseBody is! Map<String, dynamic>) {
      throw const FormatException('Broker detail response must be an object');
    }

    if (responseBody['status'] != true) {
      throw Exception(responseBody['message'] ?? 'Broker not found');
    }

    final data = responseBody['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Broker detail data is invalid');
    }

    final payload = data['payload']?.toString();
    final iv = data['iv']?.toString();
    if (payload == null || iv == null || payload.isEmpty || iv.isEmpty) {
      throw const FormatException('Encrypted broker payload is incomplete');
    }

    final decryptedString = EncryptionHelper.decryptPayload(payload, iv);
    final decrypted = jsonDecode(decryptedString);
    if (decrypted is Map<String, dynamic>) {
      return decrypted;
    }
    throw const FormatException('Decrypted broker payload is not an object');
  }

  Future<String?> downloadLogoToLocal({
    required String logoUrl,
    required String slug,
  }) async {
    final normalizedUrl = logoUrl.trim();
    if (normalizedUrl.isEmpty) return null;
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      return null;
    }

    final response = await http.get(Uri.parse(normalizedUrl)).timeout(_timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final extension = path.extension(Uri.parse(normalizedUrl).path);
    final safeSlug = slug.trim().isEmpty ? 'default' : slug.trim();
    final filename = extension.isNotEmpty ? 'tenax_$safeSlug$extension' : 'tenax_$safeSlug.png';
    final filePath = path.join(directory.path, filename);
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  List<dynamic> _extractBrokerList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }

    if (responseData is Map<String, dynamic>) {
      final candidateKeys = ['brokers', 'data', 'items', 'list'];
      for (final key in candidateKeys) {
        final value = responseData[key];
        if (value is List) {
          return value;
        }
      }
    }

    return const [];
  }
}
