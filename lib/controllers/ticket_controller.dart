import 'dart:convert';
import 'dart:io';

import 'package:crm_app/constants/api_const.dart';
import 'package:crm_app/flavor_config.dart';
import 'package:crm_app/models/ticket_model.dart';
import 'package:crm_app/services/api_service.dart';
import 'package:crm_app/services/secure_storage_service.dart';
import 'package:crm_app/widgets/custom_toast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TicketController extends GetxController {
  final departments = <TicketDepartment>[].obs;
  final tickets = <Ticket>[].obs;
  final selectedDepartment = 'all'.obs;
  final selectedStatus = 'all'.obs;
  final selectedPriority = 'all'.obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final isPageLoading = false.obs;
  final currentPage = 1.obs;
  final hasMorePages = true.obs;
  final pagination = Rxn<TicketPagination>();
  final ticketDetail = Rxn<TicketDetail>();
  final isDetailLoading = false.obs;
  final isSubmitting = false.obs;

  final int perPage = 6;

  @override
  void onInit() {
    super.onInit();
    fetchDepartments();
    fetchTickets(refresh: true);
  }

  Future<void> fetchDepartments() async {
    final response = await ApiService.get(endpoint: ApiConstants.ticketDepartments);
    if (!response.success || response.data == null) {
      return;
    }

    final body = response.data as Map<String, dynamic>?;
    final rawData = body?['data'];
    if (rawData is List) {
      departments.assignAll(
        rawData
            .whereType<Map<String, dynamic>>()
            .map(TicketDepartment.fromJson)
            .toList(),
      );
    }
  }

  Future<void> fetchTickets({bool refresh = false}) async {
    if (isLoading.value || isPageLoading.value) return;
    if (!refresh && !hasMorePages.value) return;

    if (refresh) {
      currentPage.value = 1;
      hasMorePages.value = true;
      isLoading.value = true;
    } else {
      isPageLoading.value = true;
    }

    try {
      final response = await ApiService.get(
        endpoint: ApiConstants.tickets,
        queryParameters: {
          'page': currentPage.value.toString(),
          'per_page': perPage.toString(),
          'status': selectedStatus.value,
          'department': selectedDepartment.value,
          'priority': selectedPriority.value,
          'search': searchQuery.value,
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      if (!response.success || response.data == null) {
        if (refresh) tickets.clear();
        CustomToastService.showError(message: response.message ?? 'Failed to load tickets');
        return;
      }

      final body = response.data as Map<String, dynamic>?;
      final dataWrapper = body?['data'] as Map<String, dynamic>?;
      final rawTickets = dataWrapper?['data'];
      final newTickets = rawTickets is List
          ? rawTickets
              .whereType<Map<String, dynamic>>()
              .map(Ticket.fromJson)
              .toList()
          : <Ticket>[];

      final pageInfo = TicketPagination.fromJson(dataWrapper?['pagination'] as Map<String, dynamic>?);
      pagination.value = pageInfo;
      hasMorePages.value = pageInfo.currentPage < pageInfo.lastPage;
      currentPage.value = pageInfo.currentPage + 1;

      if (refresh) {
        tickets.assignAll(newTickets);
      } else {
        tickets.addAll(newTickets);
      }
    } finally {
      isLoading.value = false;
      isPageLoading.value = false;
    }
  }

  Future<bool> createTicket({
    required int departmentId,
    required String priority,
    required String title,
    required String description,
    File? attachment,
  }) async {
    isSubmitting.value = true;
    try {
      final formData = {
        'department_id': departmentId,
        'priority': priority,
        'title': title,
        'description': description,
      };

      final response = await _postMultipart(
        endpoint: ApiConstants.tickets,
        formData: formData,
        file: attachment,
        fileField: 'attachment',
      );

      if (response.success) {
        CustomToastService.showSuccess(message: response.message ?? 'Ticket created successfully');
        await fetchTickets(refresh: true);
        return true;
      }

      CustomToastService.showError(message: response.message ?? 'Failed to create ticket');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> fetchTicketDetail(String ticketId) async {
    isDetailLoading.value = true;
    try {
      final response = await ApiService.get(
        endpoint: ApiConstants.ticketDetail(ticketId),
        queryParameters: {'_t': DateTime.now().millisecondsSinceEpoch.toString()},
      );

      if (!response.success || response.data == null) {
        ticketDetail.value = null;
        CustomToastService.showError(message: response.message ?? 'Failed to load ticket');
        return;
      }

      final body = response.data as Map<String, dynamic>?;
      final detailData = body?['data'] as Map<String, dynamic>?;
      if (detailData != null) {
        ticketDetail.value = TicketDetail.fromJson(detailData);
      }
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<bool> replyToTicket(String ticketId, String message, {File? attachment}) async {
    isSubmitting.value = true;
    try {
      final formData = {'message': message};
      final response = await _postMultipart(
        endpoint: ApiConstants.ticketReply(ticketId),
        formData: formData,
        file: attachment,
        fileField: 'attachment',
      );

      if (response.success) {
        CustomToastService.showSuccess(message: response.message ?? 'Reply posted successfully');
        await fetchTicketDetail(ticketId);
        await fetchTickets(refresh: true);
        return true;
      }

      CustomToastService.showError(message: response.message ?? 'Failed to post reply');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<bool> closeTicket(String ticketId) async {
    isSubmitting.value = true;
    try {
      final response = await ApiService.post(endpoint: ApiConstants.ticketClose(ticketId));
      if (response.success) {
        CustomToastService.showSuccess(message: response.message ?? 'Ticket closed successfully');
        await fetchTicketDetail(ticketId);
        await fetchTickets(refresh: true);
        return true;
      }

      CustomToastService.showError(message: response.message ?? 'Failed to close ticket');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> downloadAttachment(String pathOrUrl) async {
    if (pathOrUrl.isEmpty) return;

    final uri = pathOrUrl.startsWith('http')
        ? Uri.parse(pathOrUrl)
        : Uri.parse('${FlavorConfig.instance.apiBaseUrl}${ApiConstants.ticketAttachment}')
            .replace(queryParameters: {'path': pathOrUrl});

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      CustomToastService.showError(message: 'Unable to open attachment');
    }
  }

  void updateDepartment(String department) {
    selectedDepartment.value = department;
    fetchTickets(refresh: true);
  }

  void updateStatus(String status) {
    selectedStatus.value = status;
    fetchTickets(refresh: true);
  }

  void updatePriority(String priority) {
    selectedPriority.value = priority;
    fetchTickets(refresh: true);
  }

  void updateSearch(String search) {
    searchQuery.value = search;
    fetchTickets(refresh: true);
  }

  void clearFilters() {
    selectedDepartment.value = 'all';
    selectedStatus.value = 'all';
    selectedPriority.value = 'all';
    searchQuery.value = '';
    fetchTickets(refresh: true);
  }

  Future<ApiResponse> _postMultipart({
    required String endpoint,
    required Map<String, dynamic> formData,
    File? file,
    required String fileField,
  }) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });
      formData.forEach((key, value) => request.fields[key] = value.toString());
      if (file != null) {
        request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401) {
        return ApiResponse.error('Authentication failed. Please login again.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ApiResponse.error('Request failed (${response.statusCode})');
      }
      final decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final isError = decoded['status'] == false || decoded['success'] == false;
        final message = decoded['message']?.toString();
        if (isError) {
          return ApiResponse.error(message ?? 'Request failed', data: decoded['data']);
        }
        return ApiResponse.success(decoded);
      }
      return ApiResponse.success(decoded);
    } catch (e) {
      return ApiResponse.error('Upload failed: $e');
    }
  }
}
