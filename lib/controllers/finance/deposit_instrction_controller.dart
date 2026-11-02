import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crm_app/routes/app_pages.dart';
import 'package:crm_app/widgets/custom_toast.dart';

import 'dart:io';
import 'dart:async';

import '../../constants/api_const.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/api_service.dart';
import '../../services/secure_storage_service.dart';
import '../../screens/home/more/finance/deposit_camera_screen.dart';
import '../../controllers/app_notification_controller.dart';
import '../../services/language_service.dart';

class DepositInstructionController extends GetxController {
  // Observable variables

  final isLoading = false.obs;
  final amount = ''.obs;
  final cryptoAddress = 'UGIGfjdsofijofijwesef'.obs;
  var selectedImage = Rx<File?>(null);

  // Cregis-specific fields
  final cregisNetworks = <String>[].obs;
  final selectedCregisNetwork = ''.obs;
  final cregisDepositAddress = ''.obs;
  final cregisQrPath = ''.obs;
  final cregisCheckoutUrl = ''.obs;
  final isAddressLoading = false.obs;
  final cregisReferenceNumber = ''.obs;
  final cregisPollingStatus = ''.obs;
  final cregisChainId = ''.obs;
  Map<String, dynamic>? cregisNetworkMap;

  /// Captured at the moment the user taps the Generate-Address / Submit button.
  /// Passed to the Cregis wait screens via `tapTimeIso` route arg so the screens
  /// can show debug info / know how long the user has been waiting. The actual
  /// success detection does NOT depend on this — `referenceNumber`-match against
  /// `/transactions` is the source of truth.
  DateTime? _cregisTapTime;

  /// Keeps the deposit_instruction_screen badge working. The actual polling
  /// loop now lives on the wait screens; the controller is only a state holder
  /// so that the form-screen badge reflects current polling lifecycle.
  int _pollingAttempts = 0;
  int get cregisPollingAttemptCount => _pollingAttempts;

  /// Set by the wait screens to update the form-screen badge.
  void setPollingStatus(String status) {
    cregisPollingStatus.value = status;
  }

  /// Set by the wait screens on each poll cycle. Resets when polling ends.
  void setPollingAttemptCount(int count) {
    _pollingAttempts = count;
  }

  /// Clears badge state when polling ends (success / timeout / cancel).
  void clearPollingState() {
    cregisPollingStatus.value = '';
    _pollingAttempts = 0;
  }

  /// Surfaces the tap-time as an ISO8601 string for route args. Returns ''
  /// when no tap-time is captured yet.
  String get tapTimeIso =>
      _cregisTapTime == null ? '' : _cregisTapTime!.toIso8601String();

  // Text editing controller
  final amountController = TextEditingController();

  // Camera controller for taking pictures
  CameraController? cameraController;
  List<CameraDescription>? cameras;

  @override
  void onInit() {
    super.onInit();
    // Initialize any data or fetch crypto address from API
    fetchCryptoAddress();
    // Initialize camera
    initializeCamera();
  }

  @override
  void onClose() {
    amountController.dispose();
    _disposeCamera();
    super.onClose();
  }

  // Dispose camera controller safely
  Future<void> _disposeCamera() async {
    if (cameraController != null) {
      try {
        final camController = cameraController;
        cameraController = null; // Clear reference first
        if (camController!.value.isInitialized) {
          await camController.dispose();
        } else {
          // If not initialized, just dispose
          await camController.dispose();
        }
      } catch (e) {
        print('Error disposing camera: $e');
        // Try to dispose anyway
        try {
          await cameraController?.dispose();
        } catch (e2) {
          print('Error in final camera disposal: $e2');
        }
        cameraController = null;
      }
    }
  }

  // Initialize available cameras
  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  // Request camera permission
  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  // Fetch crypto address from API
  Future<void> fetchCryptoAddress() async {
    try {
      isLoading.value = true;

      // Example API call
      // final response = await _apiService.getCryptoAddress();
      // cryptoAddress.value = response.address;

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      cryptoAddress.value = 'UGIGfjdsofijofijwesef';
    } catch (e) {
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: 'Failed to fetch crypto address: ${e.toString()}',
          title: 'Error',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Start camera for taking payment proof photo
  Future<void> startCamera() async {
    await requestCameraPermission();

    if (cameras == null || cameras!.isEmpty) {
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: 'No camera available on this device.',
          title: 'Error',
        );
      }
      return;
    }

    // Dispose existing controller if any
    if (cameraController != null) {
      await cameraController!.dispose();
      cameraController = null;
    }

    cameraController = CameraController(
      cameras![0],
      ResolutionPreset
          .medium, // Use medium instead of high for better memory management
    );

    try {
      await cameraController!.initialize();
      // Small delay to ensure camera is fully ready
      await Future.delayed(const Duration(milliseconds: 200));
      Get.to(() => DepositCameraScreen());
    } catch (e) {
      print('Error starting camera: $e');
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: 'Failed to start camera: ${e.toString()}',
          title: 'Error',
        );
      }
      await cameraController?.dispose();
      cameraController = null;
      // Try to navigate back if camera failed
      if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
        Get.back(closeOverlays: true);
      }
    }
  }

  // Capture image from camera
  Future<void> captureImage() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: 'Camera is not ready. Please wait.',
          title: 'Error',
        );
      }
      return;
    }

    try {
      isLoading.value = true;

      // Store reference before disposing
      final camController = cameraController;
      final image = await camController!.takePicture();

      selectedImage.value = File(image.path);

      // Clear reference first, then dispose
      cameraController = null;
      update(); // Notify GetBuilder to rebuild

      // Dispose after a small delay to ensure UI has updated
      await Future.delayed(const Duration(milliseconds: 100));
      await camController.dispose();

      Get.back(closeOverlays: true);

      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showSuccess(
          message: 'Payment proof captured successfully!',
          title: 'Success',
        );
      }
    } catch (e) {
      print('Error capturing image: $e');
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: 'Failed to capture image: ${e.toString()}',
          title: 'Error',
        );
      }

      // Clean up on error
      try {
        final camController = cameraController;
        cameraController = null;
        update();
        await camController?.dispose();
      } catch (disposeError) {
        print('Error disposing camera: $disposeError');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Pick image from gallery using file_picker
  Future<void> pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        allowCompression: true,
      );

      if (result != null && result.files.single.path != null) {
        selectedImage.value = File(result.files.single.path!);
        if (Get.isRegistered<AppNotificationController>()) {
          Get.find<AppNotificationController>().showSuccess(
            message: 'Image selected from gallery',
            title: 'Success',
          );
        }
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: 'Failed to pick image from gallery. Please try again.',
          title: 'Error',
        );
      }
    }
  }

  // Copy crypto address to clipboard
  void copyCryptoAddress() {
    // Clipboard.setData(ClipboardData(text: cryptoAddress.value));

    CustomToastService.showSuccess(message: 'Copied');
  }

  /// Submit deposit instruction (Bank, Crypto, Local, etc.)
  Future<void> submitDepositInstruction(
    Map<String, dynamic> requestData,
  ) async {
    if (selectedImage.value == null) {
      CustomToastService.showError(
        message: 'Please upload a payment proof file',
      );
      return;
    }

    try {
      isLoading.value = true;
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.uploadImageDepositRequest(
        endpoint: ApiConstants.depositRequest,
        file: selectedImage.value!,
        token: token,
        formData: requestData,
      );

      if (response.success) {
        CustomToastService.showSuccess(
          message: response.message ?? 'Deposit request submitted successfully',
        );

        // Mark dashboard MT5 accounts as stale so it refreshes when user returns to dashboard
        // Don't call API here since we're navigating away from dashboard
        try {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.markMT5AccountsAsStale();
        } catch (_) {}

        Get.toNamed(
          AppPages.TRANSACTION_HISTORY,
          arguments: {'from': 'dashboard'},
        );

        amountController.clear();
        selectedImage.value = null;
      } else {
        // Clear image on error so user has to upload again
        selectedImage.value = null;
        CustomToastService.showError(
          message: response.message ?? 'Deposit submission failed',
        );
      }
    } catch (e, t) {
      print("object   imsgr error $t");
      print("object   imsgr error $e");
      // Clear image on error so user has to upload again
      selectedImage.value = null;
      CustomToastService.showError(
        message: 'Error while submitting deposit: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Submit deposit instruction (Bank, Crypto, Local, etc.)
  Future<void> submitDepositInstructionForCrypto(
    Map<String, dynamic> requestData,
  ) async {
    if (selectedImage.value == null) {
      CustomToastService.showError(
        message: 'Please upload a payment proof file',
      );
      return;
    }

    try {
      isLoading.value = true;
      final token = await SecureStorageService.getAuthToken();

      final response = await ApiService.uploadImageDepositRequest(
        endpoint: ApiConstants.depositRequest,
        file: selectedImage.value!,
        token: token,
        formData: requestData,
      );

      if (response.success) {
        CustomToastService.showSuccess(
          message: response.message ?? 'Deposit request submitted successfully',
        );

        try {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.markMT5AccountsAsStale();
        } catch (_) {}

        Get.toNamed(
          AppPages.TRANSACTION_HISTORY,
          arguments: {'from': 'finance'},
        );

        amountController.clear();
        selectedImage.value = null;
      } else {
        selectedImage.value = null;
        CustomToastService.showError(
          message: response.message ?? 'Deposit submission failed',
        );
      }
    } catch (e, t) {
      print("object   imsgr error $t");
      print("object   imsgr error $e");
      selectedImage.value = null;
      CustomToastService.showError(
        message: 'Error while submitting deposit: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Create a redirect deposit (Cregis, SafePay, ...). Cregis needs a network
  /// ([requireNetwork]); [depositApi] is the method's `deposit_api` path.
  Future<void> createCregisDepositAddress({
    required String gatewayMethodId,
    required String amount,
    required String mt5AccountId,
    bool requireNetwork = true,
    String depositApi = '',
  }) async {
    if (requireNetwork && selectedCregisNetwork.value.isEmpty) {
      CustomToastService.showError(
        message: 'Please select a network',
      );
      return;
    }

    _cregisTapTime = DateTime.now();

    try {
      isAddressLoading.value = true;
      final token = await SecureStorageService.getAuthToken();

      final requestBody = {
        'gateway_method_id': gatewayMethodId,
        'amount': amount,
        'mt5_account_id': mt5AccountId,
        if (requireNetwork) 'crypto_network': selectedCregisNetwork.value,
      };
      final endpoint = depositApi.trim().isNotEmpty
          ? _relativeDepositEndpoint(depositApi)
          : ApiConstants.cregisDepositCreate;

      final response = await ApiService.post(
        endpoint: endpoint,
        token: token,
        data: requestBody,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] ?? response.data;

        cregisReferenceNumber.value = data['reference_number']?.toString() ?? '';
        cregisChainId.value = data['chain_id']?.toString() ?? '';
        final redirectUrl = data['redirect_url']?.toString() ?? '';
        cregisCheckoutUrl.value = redirectUrl.isNotEmpty
            ? redirectUrl
            : data['checkout_url']?.toString() ?? '';
        cregisDepositAddress.value = data['cregis_address']?.toString() ?? '';
        cregisQrPath.value = data['qr_path']?.toString() ?? '';
print("object   imsgr cregisCheckoutUrl.value ${cregisCheckoutUrl.value}");
        if (cregisCheckoutUrl.value.isNotEmpty) {

          // Checkout flow - immediately open the payment URL. The wait screen
          // itself runs the polling loop; the controller no longer drives it.
          Get.toNamed(
            AppPages.CREGIS_SUCCESS,
            arguments: {
              'checkoutUrl': cregisCheckoutUrl.value,
              'referenceNumber': cregisReferenceNumber.value,
              'amount': amount,
              'tapTimeIso': tapTimeIso,
            },
          );
        } else if (cregisDepositAddress.value.isNotEmpty) {
          // Address flow - show address + start polling
          CustomToastService.showSuccess(
            message: 'Deposit address created. Send crypto to the address shown.',
          );
        } else {
          CustomToastService.showError(
            message: 'No deposit address or checkout URL returned',
          );
        }
      } else {
        CustomToastService.showError(
          message: response.message ?? 'Failed to create deposit',
        );
      }
    } catch (e) {
      print('Error creating Cregis deposit address: $e');
      CustomToastService.showError(
        message: 'Error creating deposit address: $e',
      );
    } finally {
      isAddressLoading.value = false;
    }
  }

  /// `deposit_api` is a site path (`/api/user/...`); [ApiService] prefixes a
  /// base URL that already ends in `/api/`, so strip the leading `/api/`.
  String _relativeDepositEndpoint(String depositApi) {
    var path = depositApi.trim();
    if (path.startsWith('/')) path = path.substring(1);
    if (path.startsWith('api/')) path = path.substring(4);
    return path;
  }

  /// `POST deposit/unipayment` → opens the hosted `invoice_url` in the same
  /// checkout screen Cregis uses.
  Future<void> submitUniPaymentDeposit({
    required String gatewayMethodId,
    required String mt5AccountId,
    required String amount,
  }) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
        endpoint: ApiConstants.uniPaymentDeposit,
        token: token,
        data: {
          'gateway_method_id': gatewayMethodId,
          'mt5_account_id': mt5AccountId,
          'amount': amount,
        },
      );
      final body = response.data is Map ? response.data as Map : const {};
      final data = body['data'] is Map ? body['data'] as Map : const {};
      final invoiceUrl = data['invoice_url']?.toString() ?? '';
      if (!response.success || invoiceUrl.isEmpty) {
        CustomToastService.showError(
          message: response.message?.isNotEmpty == true
              ? response.message!
              : TranslationUtils.tr('deposit_unipayment_failed'),
        );
        return;
      }
      Get.toNamed(
        AppPages.CREGIS_SUCCESS,
        arguments: {
          'checkoutUrl': invoiceUrl,
          'referenceNumber': data['reference_number']?.toString() ?? '',
          'amount': amount,
          'tapTimeIso': DateTime.now().toIso8601String(),
        },
      );
    } catch (_) {
      CustomToastService.showError(
        message: TranslationUtils.tr('deposit_unipayment_failed'),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Bank details returned by a dynamic gateway that pays by bank transfer
  /// (`data.account_number` present). Null until such a response arrives.
  final dynamicBankResult = Rxn<Map<String, dynamic>>();

  /// `POST deposit/dynamic/{gatewaySlug}` — same branching as the web
  /// `DepositRequest` submit: hosted payment page, bank details, or a push
  /// prompt sent to the payer's phone.
  Future<void> submitDynamicDeposit({
    required String gatewaySlug,
    required String gatewayMethodId,
    required String amount,
    required String mt5AccountId,
    Map<String, String> extraFields = const {},
  }) async {
    if (isLoading.value) return;
    try {
      isLoading.value = true;
      final token = await SecureStorageService.getAuthToken();
      final response = await ApiService.post(
        endpoint: ApiConstants.dynamicDeposit(gatewaySlug),
        token: token,
        data: {
          'gateway_method_id': gatewayMethodId,
          'mt5_account_id': mt5AccountId,
          'amount': amount,
          ...extraFields,
        },
      );

      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final rawData = body['data'];
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};
      final message = response.message ?? body['message']?.toString();

      if (!response.success) {
        CustomToastService.showError(
          message: message ?? TranslationUtils.tr('deposit_dynamic_failed'),
        );
        return;
      }

      final reference = data['reference_number']?.toString() ?? '';
      final redirectUrl = data['redirect_url']?.toString() ?? '';
      final accountNumber = data['account_number']?.toString() ?? '';

      if (accountNumber.isNotEmpty) {
        dynamicBankResult.value = data;
        _markDashboardAccountsStale();
        return;
      }

      if (redirectUrl.isNotEmpty) {
        _markDashboardAccountsStale();
        Get.toNamed(
          AppPages.CREGIS_SUCCESS,
          arguments: {
            'checkoutUrl': redirectUrl,
            'referenceNumber': reference,
            'amount': amount,
            'tapTimeIso': DateTime.now().toIso8601String(),
          },
        );
        return;
      }

      if (data['async_ack'] == true || data['async_ack'] == 1) {
        _markDashboardAccountsStale();
        CustomToastService.showSuccess(
          message: message ?? TranslationUtils.tr('deposit_dynamic_prompt_sent'),
        );
        Get.toNamed(
          AppPages.TRANSACTION_HISTORY,
          arguments: {'from': 'finance'},
        );
        return;
      }

      CustomToastService.showError(
        message: message ?? TranslationUtils.tr('deposit_dynamic_no_action'),
      );
    } catch (_) {
      CustomToastService.showError(
        message: TranslationUtils.tr('deposit_dynamic_failed'),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _markDashboardAccountsStale() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().markMT5AccountsAsStale();
    }
  }

  /// Confirm Cregis deposit - navigate to address or success screen
  Future<void> submitCregisDeposit({
    required String gatewayMethodId,
    required String amount,
    required String mt5AccountId,
  }) async {
    _cregisTapTime = DateTime.now();

    if (cregisCheckoutUrl.value.isNotEmpty) {
      // Checkout flow - open success screen (which opens external browser + polling).
      // The wait screen itself runs the polling loop; the controller no longer drives it.
      Get.toNamed(
        AppPages.CREGIS_SUCCESS,
        arguments: {
          'checkoutUrl': cregisCheckoutUrl.value,
          'referenceNumber': cregisReferenceNumber.value,
          'amount': amount,
          'tapTimeIso': tapTimeIso,
        },
      );
      return;
    }

    if (cregisDepositAddress.value.isEmpty) {
      CustomToastService.showError(
        message: 'Please generate a deposit address first',
      );
      return;
    }

    // Address flow - navigate to address screen (which has its own polling)
    Get.toNamed(
      AppPages.CREGIS_ADDRESS,
      arguments: {
        'cregisAddress': cregisDepositAddress.value,
        'referenceNumber': cregisReferenceNumber.value,
        'amount': amount,
        'networkKey': selectedCregisNetwork.value,
        'tapTimeIso': tapTimeIso,
      },
    );
  }
}
