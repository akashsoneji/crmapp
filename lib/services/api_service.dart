import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/services/secure_storage_service.dart';

class ApiService {
  static const String _baseUrl = ApiConstants.baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  /// GET: Fetch data with optional query parameters
  static Future<ApiResponse> get({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    try {
      // If no token provided, try to get from secure storage
      String? authToken = token;
      if (authToken == null) {
        authToken = await SecureStorageService.getAuthToken();
      }

      final headers = {
        'Accept': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      _logRequest(
        'GET',
        endpoint,
        queryParameters: queryParameters,
        extraHeaders: headers,
      );

      final uri = Uri.parse(
        '$_baseUrl$endpoint',
      ).replace(queryParameters: queryParameters);
      final response = await http.get(uri, headers: headers).timeout(_timeout);

      _logResponse(response);
      return ApiResponse.success(jsonDecode(response.body));
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST: JSON body
  static Future<ApiResponse> post({
    required String endpoint,
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      // If no token provided, try to get from secure storage
      String? authToken = token;
      if (authToken == null) {
        authToken = await SecureStorageService.getAuthToken();
      }

      final headers = {
        'Content-Type': 'application/json',
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      _logRequest('POST', endpoint, data: data, extraHeaders: headers);

      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .post(
            uri,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(_timeout);

      _logResponse(response);
      return ApiResponse.success(jsonDecode(response.body));
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST: Form data
  static Future<ApiResponse> postForm({
    required String endpoint,
    required Map<String, dynamic> formData,
    String? token,
    bool? isPayment = true,
  }) async {
    try {
      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final contentType =
          isPayment == true
              ? 'multipart/form-data'
              : 'application/x-www-form-urlencoded';

      _logRequest('POST_FORM', endpoint, data: formData, extraHeaders: headers);

      final uri = Uri.parse('$_baseUrl$endpoint');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers.addAll(headers)
            ..fields.addAll(
              formData.map((key, value) => MapEntry(key, value.toString())),
            );

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response);
      return ApiResponse.success(jsonDecode(response.body));
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Logging
  static void _logRequest(
    String method,
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extraHeaders,
  }) {
    developer.log('--------------------------------------------');
    developer.log('API REQUEST → $method');
    developer.log('URL → $_baseUrl$url');
    if (queryParameters != null)
      developer.log('Query Parameters → $queryParameters');
    if (data != null) developer.log('Request Body → $data');
    if (extraHeaders != null) developer.log('Headers → $extraHeaders');
    developer.log('--------------------------------------------');
  }

  static void _logResponse(http.Response response) {
    developer.log('✅ API RESPONSE');
    developer.log('URL → ${response.request?.url}');
    developer.log('Status Code → ${response.statusCode}');
    developer.log(
      'Body → ${JsonEncoder.withIndent(' ').convert(jsonDecode(response.body))}',
    );
    developer.log('--------------------------------------------');
  }

  static void _logError(dynamic e) {
    developer.log('❌ API ERROR');
    if (e is http.Response) {
      developer.log('Status Code → ${e.statusCode}');
      developer.log('Error Body → ${e.body}');
    } else if (e is http.ClientException) {
      developer.log('Message → ${e.message}');
    } else if (e is Exception) {
      developer.log('Message → ${e.toString()}');
    }
    developer.log('--------------------------------------------');
  }

  static ApiResponse _handleError(dynamic e) {
    if (e is http.ClientException || e is Exception) {
      return ApiResponse.error('Network error. Please check your connection.');
    } else if (e is http.Response) {
      if (e.statusCode == 401) {
        // TODO: Navigate to login screen
        // g.Get.offAllNamed(AppRoutes.login);
        return ApiResponse.error('Unauthorized. Please login again.');
      }
      final errorData = jsonDecode(e.body);
      String errorMessage = 'Unexpected error occurred.';
      dynamic errorDetails;

      if (errorData is Map<String, dynamic>) {
        errorMessage = errorData['message'] ?? errorMessage;
        if (errorData.containsKey('data')) {
          if (errorData['data'] is Map<String, dynamic>) {
            errorDetails = errorData['data'] as Map<String, dynamic>;
          } else if (errorData['data'] is Map &&
              errorData['data']['errors'] is List) {
            errorDetails = errorData['data']['errors'] as List<dynamic>;
          } else {
            errorDetails = errorData['data'];
          }
        }
      }

      return ApiResponse.error(errorMessage, data: errorDetails);
    } else {
      return ApiResponse.error('Unexpected error occurred.');
    }
  }
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({required this.success, this.message, this.data});

  factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);

  factory ApiResponse.error(String message, {T? data}) =>
      ApiResponse(success: false, message: message, data: data);
}
