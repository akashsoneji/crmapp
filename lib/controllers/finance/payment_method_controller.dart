import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pipze/services/api_service.dart';
import 'package:pipze/widgets/custom_toast.dart';

import '../../constants/api_const.dart';
import '../../screens/home/more/finance/deposit_real_screen.dart';
import '../../services/secure_storage_service.dart';

class PaymentMethodController extends GetxController {
  // Observable states
  final _isLoading = false.obs;
  final _errorMessage = ''.obs;
  final _successMessage = ''.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get successMessage => _successMessage.value;

  // KYC deposits list
  final kycDeposits = <Map<String, dynamic>>[].obs;
  final selectedKYCDeposit = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    fetchKYCDepositMethods();
  }

  /// Fetch deposit methods that require KYC
  Future<void> fetchKYCDepositMethods() async {
    try {
      _setLoading(true);
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.get(
        endpoint: ApiConstants.depositList, // <-- create/adjust this endpoint
        token: token,
      );

      if (response.success && response.data['status'] == true) {
        _setLoading(false);
        final methods = List<Map<String, dynamic>>.from(response.data['data']);
        kycDeposits.assignAll(methods);

        if (methods.isNotEmpty) {
          selectedKYCDeposit.value = methods.first;
        }
      } else {
        _setLoading(false);
        kycDeposits.clear();
      }
    } catch (e) {
      _setLoading(false);
      kycDeposits.clear();
      CustomToastService.showError(message: "Error: $e");
    } finally {
      _setLoading(false);
    }
  }


  /// Fetch icon bytes for a list of deposit methods and update them
  Future<void> loadDepositIcons(List<Map<String, dynamic>> methods) async {
    try {
      final token = await SecureStorageService.getAuthToken();
      final List<Map<String, dynamic>> updatedMethods = [];

      for (var method in methods) {
        final iconUrl = method['icon'] ?? '';
        Uint8List? bytes; // initialize properly
        if (iconUrl.isNotEmpty) {
          bytes = await fetchImageBytes(iconUrl, token!);
        }

        updatedMethods.add({
          ...method,
          'iconBytes': bytes, // store bytes for Image.memory
        });
      }

      // Update kycDeposits with new data including icon bytes
      kycDeposits.assignAll(updatedMethods);
    } catch (e) {
      print('Error loading deposit icons: $e');
    }
  }

  /// Fetch icon bytes from a URL with Authorization token
  Future<Uint8List?> fetchImageBytes(String url, String token) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode == 200) {
        final bytes = await streamedResponse.stream.toBytes();
        print("RESPONSE SUCCESS IMAGE");
        return bytes;
      } else {
        print('Failed to fetch image: ${streamedResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching image: $e');
      return null;
    }
  }

  /// Select a KYC deposit method
  void setSelectedKYCDeposit(Map<String, dynamic> method) {
    selectedKYCDeposit.value = method;
    // Get.to(Page)
    Get.to(() => DepositRealScreen(object: selectedKYCDeposit.value ?? {},));
  }

  // Helpers
  void _setLoading(bool loading) => _isLoading.value = loading;

  void clearMessages() {
    _errorMessage.value = '';
    _successMessage.value = '';
  }
}