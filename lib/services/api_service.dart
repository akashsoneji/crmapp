import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/routes/app_pages.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/services/http_client_service.dart';
import 'package:pipze/widgets/custom_toast.dart';
import 'package:pipze/controllers/auth_controller.dart';
import 'package:get/get.dart' as g;

class ApiService {
  static String _baseUrl = ApiConstants.baseUrl;
  static const Duration _timeout = Duration(seconds: 30);

  // Flag to prevent multiple simultaneous 401 error handlers
  static bool _isHandlingUnauthenticated = false;

  /// GET: Fetch data with optional query parameters
  static Future<ApiResponse> get({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    try {
      // Check network connectivity for critical requests (like login)
      if (endpoint.contains('/login') || endpoint.contains('login')) {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          return ApiResponse.error('No internet connection. Please check your network.');
        }
      }

      // If no token provided, try to get from secure storage
      String? authToken = token;
      if (authToken == null) {
        authToken = await SecureStorageService.getAuthToken();
      }

      // Use persistent client with Keep-Alive headers
      final httpClient = HttpClientService.instance;
      final headers = {
        'Accept': 'application/json',
        // Temporarily disable keep-alive headers for login requests
        if (!endpoint.contains('/login') && !endpoint.contains('login'))
          ...httpClient.keepAliveHeaders, // Add Keep-Alive headers
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

      // Use persistent HTTP client for connection reuse
      final response = await httpClient.client
          .get(uri, headers: headers)
          .timeout(_timeout);

      _logResponse(response);

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      return _parseApiResponse(response.body);
    } catch (e, t) {
      print("object $t");
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

      // Use persistent client with Keep-Alive headers
      final httpClient = HttpClientService.instance;
      final headers = {
        'Content-Type': 'application/json',
        ...httpClient.keepAliveHeaders, // Add Keep-Alive headers
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      _logRequest('POST', endpoint, data: data, extraHeaders: headers);

      final uri = Uri.parse('$_baseUrl$endpoint');

      // Use shorter timeout for login requests to fail faster
      final timeout = (endpoint.contains('/login') || endpoint.contains('login') || endpoint.contains('user/login'))
          ? const Duration(seconds: 15)
          : _timeout;

      // Use fresh client for login requests to avoid keep-alive issues
      final clientToUse = (endpoint.contains('/login') || endpoint.contains('login') || endpoint.contains('user/login'))
          ? httpClient.getFreshClient()
          : httpClient.client;

      final response = await clientToUse
          .post(
            uri,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          )
          .timeout(timeout);

      // Close fresh client after use
      if (clientToUse != httpClient.client) {
        clientToUse.close();
      }

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

      // Use persistent client with Keep-Alive headers
      final httpClient = HttpClientService.instance;
      final headers = {
        'Content-Type': 'application/json',
        ...httpClient.keepAliveHeaders, // Add Keep-Alive headers
        if (authToken != null && authToken.isNotEmpty)
          'Authorization': 'Bearer $authToken',
      };

      _logRequest('PUT', endpoint, data: data, extraHeaders: headers);

      final uri = Uri.parse('$_baseUrl$endpoint');

      // Use persistent HTTP client for connection reuse
      final response = await httpClient.client
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
        final message = responseData['message'] ?? 'Request failed';

        if (apiStatus == false) {
          // API returned status: false, treat as error
          // Only use data if it's actually a map (not an empty array)
          final errorData = responseData['data'];
          final validErrorData =
              errorData is Map<String, dynamic> ? errorData : null;
          return ApiResponse.error(message, data: validErrorData);
        }

        // API returned status: true, return success
        return ApiResponse.success(responseData);
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
    // Prevent multiple simultaneous 401 handlers
    if (_isHandlingUnauthenticated) {
      print('ApiService: Already handling unauthenticated error, skipping...');
      return;
    }

    try {
      _isHandlingUnauthenticated = true;

      // Check if user is actually authenticated before auto-logout
      // This prevents auto-logout during app reconnection when session is still valid
      bool shouldLogout = false;
      try {
        final authController = g.Get.find<AuthController>();
        // Only logout if user is actually authenticated
        // If not authenticated, this might be a reconnection issue, not a real session expiry
        if (authController.isAuthenticated) {
          // Verify token still exists in storage
          final token = await SecureStorageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            shouldLogout = true;
            if (kDebugMode) {
              developer.log('ApiService: User is authenticated with valid token, session expired - logging out');
            }
          } else {
            if (kDebugMode) {
              developer.log('ApiService: Token not found in storage, user may already be logged out - skipping auto-logout');
            }
          }
        } else {
          if (kDebugMode) {
            developer.log('ApiService: User not authenticated, 401 might be from reconnection - skipping auto-logout');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('ApiService: Error checking auth state: $e - proceeding with caution');
        }
        // If we can't check auth state, be conservative and don't auto-logout
        // This prevents logout during app reconnection issues
        shouldLogout = false;
      }

      // Only proceed with logout if user is actually authenticated
      if (!shouldLogout) {
        if (kDebugMode) {
          developer.log('ApiService: Skipping auto-logout - user not authenticated or token missing');
        }
        _isHandlingUnauthenticated = false;
        return;
      }

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
        g.Get.offAllNamed(AppPages.GET_STARTED);
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
        g.Get.offAllNamed(AppPages.GET_STARTED);
      } catch (fallbackError) {
        print('Fallback error handling failed: $fallbackError');
        // Last resort: just navigate
        g.Get.offAllNamed(AppPages.GET_STARTED);
      }
    } finally {
      // Reset flag after handling is complete
      _isHandlingUnauthenticated = false;
    }
  }

  /// UPLOAD: Upload file with form data
  static Future<ApiResponse> uploadFile({
    required String endpoint,
    required File file,
    required Map<String, dynamic> formData,
    String? token,
    Function(double)? onProgress,
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
        'UPLOAD',
        endpoint,
        queryParameters: formData,
        extraHeaders: headers,
      );

      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(headers);

      // Don't set Content-Type for multipart requests - let the framework handle it
      // The multipart request will automatically set the correct Content-Type with boundary

      // Ensure we have the correct content type
      request.headers.remove(
        'Content-Type',
      ); // Remove any existing content type

      // Add form data
      formData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Debug: Log form data
      developer.log('Form data being sent:', name: 'ApiService');
      formData.forEach((key, value) {
        developer.log('$key: $value', name: 'ApiService');
      });

      // Add file - try different field names that the server might expect
      // Common field names: 'file', 'image', 'document', 'upload'
      // Based on the iOS code, it might expect 'document' or 'image'

      // Check if file exists and is readable
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      // Add file - try different field names that the server might expect
      // Based on the error, the server is not receiving the file data
      request.files.add(
        await http.MultipartFile.fromPath(
          'files[]', // Use 'files[]' as expected by server
          file.path,
        ),
      );

      // Debug: Log the request details
      developer.log('Upload request details:', name: 'ApiService');
      developer.log('Files count: ${request.files.length}', name: 'ApiService');
      developer.log('Fields: ${request.fields}', name: 'ApiService');
      developer.log('File path: ${file.path}', name: 'ApiService');
      developer.log('File exists: ${await file.exists()}', name: 'ApiService');
      developer.log('File size: ${await file.length()}', name: 'ApiService');

      // Log the actual multipart request details
      developer.log('Request headers: ${request.headers}', name: 'ApiService');
      developer.log('Request URL: ${request.url}', name: 'ApiService');

      // Log each file being sent
      for (int i = 0; i < request.files.length; i++) {
        final fileField = request.files[i];
        developer.log(
          'File $i: field=${fileField.field}, filename=${fileField.filename}, length=${fileField.length}',
          name: 'ApiService',
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response);

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      final responseData = json.decode(response.body);

      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: responseData['message'] ?? 'Upload completed',
        data: responseData,
      );
    } catch (e) {
      developer.log('Upload error: $e', name: 'ApiService');
      return ApiResponse(
        success: false,
        message: 'Upload failed: $e',
        data: null,
      );
    }
  }

  /// UPLOAD: Upload file with form data
  static Future<ApiResponse> uploadImageDepositRequest({
    required String endpoint,
    required File file,
    required Map<String, dynamic> formData,
    String? token,
    Function(double)? onProgress,
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
        'DepositRequest',
        endpoint,
        queryParameters: formData,
        extraHeaders: headers,
      );

      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(headers);

      // Don't set Content-Type for multipart requests - let the framework handle it
      // The multipart request will automatically set the correct Content-Type with boundary

      // Ensure we have the correct content type
      request.headers.remove(
        'Content-Type',
      ); // Remove any existing content type

      // Add form data
      formData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Debug: Log form data
      developer.log('Form data being sent:', name: 'ApiService');
      formData.forEach((key, value) {
        developer.log('$key: $value', name: 'ApiService');
      });

      // Add file - try different field names that the server might expect
      // Common field names: 'file', 'image', 'document', 'upload'
      // Based on the iOS code, it might expect 'document' or 'image'

      // Check if file exists and is readable
      // Compress if file size > 1.5 MB
      file = await FileCompressionHelper.compressIfNeeded(file);

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      // Add file - try different field names that the server might expect
      // Based on the error, the server is not receiving the file data
      request.files.add(await http.MultipartFile.fromPath('proof', file.path));

      // Debug: Log the request details
      developer.log('Upload request details:', name: 'ApiService');
      developer.log('Files count: ${request.files.length}', name: 'ApiService');
      developer.log('Fields: ${request.fields}', name: 'ApiService');
      developer.log('File path: ${file.path}', name: 'ApiService');
      developer.log('File exists: ${await file.exists()}', name: 'ApiService');
      developer.log('File size: ${await file.length()}', name: 'ApiService');

      // Log the actual multipart request details
      developer.log('Request headers: ${request.headers}', name: 'ApiService');
      developer.log('Request URL: ${request.url}', name: 'ApiService');

      // Log each file being sent
      for (int i = 0; i < request.files.length; i++) {
        final fileField = request.files[i];
        developer.log(
          'File $i: field=${fileField.field}, filename=${fileField.filename}, length=${fileField.length}',
          name: 'ApiService',
        );
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response);

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      final responseData = json.decode(response.body);
      file.delete();
      return ApiResponse(
        success: responseData['status'] as bool,
        message:
            responseData['message'] ?? 'Deposit request created successfully',
        data: responseData,
      );
    } catch (e) {
      developer.log('Upload error: $e', name: 'ApiService');
      return ApiResponse(
        success: false,
        message: 'Deposit request failed: $e',
        data: null,
      );
    }
  }

  /// UPLOAD: Upload multiple files with form data
  static Future<ApiResponse> uploadFiles({
    required String endpoint,
    required List<FileUploadData> files,
    required Map<String, dynamic> formData,
    String? token,
    Function(double)? onProgress,
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
        'UPLOAD',
        endpoint,
        queryParameters: formData,
        extraHeaders: headers,
      );

      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll(headers);

      // Add form data
      formData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add all files with their specific subdocument types
      List<String> subdocumentTypes = [];
      for (int i = 0; i < files.length; i++) {
        var fileData = files[i];
        if (await fileData.file.exists()) {
          final fileSize = await fileData.file.length();
          if (fileSize > 0) {
            // Add file with specific subdocument type
            request.files.add(
              await http.MultipartFile.fromPath(
                'files[]', // Use 'files[]' for multiple files as expected by server
                fileData.file.path,
              ),
            );

            // Collect subdocument types for this specific file
            subdocumentTypes.add(fileData.subdocumentType);

            developer.log(
              'Added file: ${fileData.file.path} for ${fileData.subdocumentType}',
              name: 'ApiService',
            );
          }
        }
      }

      // Add subdocument types as array - each type corresponds to each file
      for (int i = 0; i < subdocumentTypes.length; i++) {
        request.fields['subdocument_types[]'] = subdocumentTypes[i];
      }

      // Debug: Log the request details
      developer.log('Upload request details:', name: 'ApiService');
      developer.log('Files count: ${request.files.length}', name: 'ApiService');
      developer.log('Fields: ${request.fields}', name: 'ApiService');

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response);

      // Check for 401 status code
      if (response.statusCode == 401) {
        return _handleError(response);
      }

      final responseData = json.decode(response.body);

      return ApiResponse(
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: responseData['message'] ?? 'Upload completed',
        data: responseData,
      );
    } catch (e) {
      developer.log('Upload error: $e', name: 'ApiService');
      return ApiResponse(
        success: false,
        message: 'Upload failed: $e',
        data: null,
      );
    }
  }
}

class FileUploadData {
  final File file;
  final String documentType;
  final String subdocumentType;

  FileUploadData({
    required this.file,
    required this.documentType,
    required this.subdocumentType,
  });
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

class FileCompressionHelper {
  static const int maxFileSize = 1500 * 1024; // 1.5 MB

  static Future<File> compressIfNeeded(File file) async {
    final int fileSize = await file.length();
    if (fileSize <= maxFileSize) return file; // No need to compress

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 85, // Adjust if still larger than 1.5MB
      minWidth: 1080, // Optional but helps reduce size
      minHeight: 1080,
    );

    if (result == null) return file;
    return File(result.path);
  }
}
