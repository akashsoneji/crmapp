import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/controllers/auth_controller.dart';
import 'package:get/get.dart' as g;

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

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      return _parseApiResponse(response.body);
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

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      return _parseApiResponse(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT: JSON body
  static Future<ApiResponse> put({
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

      _logRequest('PUT', endpoint, data: data, extraHeaders: headers);

      final uri = Uri.parse('$_baseUrl$endpoint');
      final response = await http
          .put(
            uri,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(_timeout);

      _logResponse(response);

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      return _parseApiResponse(response.body);
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

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      return _parseApiResponse(response.body);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Helper method to parse API response and check status
  static ApiResponse _parseApiResponse(String responseBody) {
    try {
      final responseData = jsonDecode(responseBody);

      // Check if the API response indicates success/failure
      if (responseData is Map<String, dynamic>) {
        final apiStatus = responseData['status'];
        if (apiStatus == false) {
          // API returned status: false, treat as error
          final message = responseData['message'] ?? 'Request failed';
          final errorData = responseData['data'];
          return ApiResponse.error(message, data: errorData);
        }
      }

      return ApiResponse.success(responseData);
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
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

  static ApiResponse _handleError(dynamic e) {
    print("object  _handleError :$e");
    if (e is http.ClientException || e is Exception) {
      return ApiResponse.error('Network error. Please check your connection.');
    } else if (e is http.Response) {
      if (e.statusCode == 401) {
        // Parse the response body to get the actual error message
        try {
          final errorData = jsonDecode(e.body);
          String errorMessage = 'Unauthorized. Please login again.';

          if (errorData is Map<String, dynamic>) {
            errorMessage = errorData['message'] ?? errorMessage;
          }

          // Handle 401 error with proper logout and navigation
          _handleUnauthenticatedError(errorMessage);

          return ApiResponse.error(errorMessage);
        } catch (parseError) {
          // If parsing fails, use default message
          _handleUnauthenticatedError(
            'Your session has expired. Please login again.',
          );
          return ApiResponse.error('Unauthorized. Please login again.');
        }
      }

      // Handle other HTTP errors
      try {
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
      } catch (parseError) {
        return ApiResponse.error('Unexpected error occurred.');
      }
    } else {
      return ApiResponse.error('Unexpected error occurred.');
    }
  }

  // Handle 401 unauthenticated error with proper logout and navigation
  static void _handleUnauthenticatedError(String message) async {
    try {
      // Show custom toast message
      CustomToastService.showInfo(message: message, title: 'Session Expired');

      // Wait a moment for the user to see the message
      await Future.delayed(Duration(seconds: 2));

      // Get auth controller and logout properly
      try {
        final authController = g.Get.find<AuthController>();
        await authController.logoutWithOutApi();
      } catch (e) {
        print('AuthController not found, clearing data manually: $e');
        // Fallback: clear auth data and navigate to login
        await SecureStorageService.clearAuthData();
        g.Get.offAllNamed(AppPages.LOGIN);
      }
    } catch (e) {
      print('Error handling unauthenticated error: $e');
      // Fallback: just show error message and navigate
      try {
        CustomToastService.showError(
          message: 'Authentication failed. Please login again.',
          title: 'Error',
        );
        await Future.delayed(Duration(seconds: 1));
        await SecureStorageService.clearAuthData();
        g.Get.offAllNamed(AppPages.LOGIN);
      } catch (fallbackError) {
        print('Fallback error handling failed: $fallbackError');
        // Last resort: just navigate
        g.Get.offAllNamed(AppPages.LOGIN);
      }
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
