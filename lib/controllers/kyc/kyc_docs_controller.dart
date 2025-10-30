import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pipze/constants/api_const.dart';
import 'package:pipze/services/api_service.dart';
import 'package:pipze/services/secure_storage_service.dart';
import 'package:pipze/widgets/custom_toast.dart';

class KycDocsController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString _authToken = ''.obs;

  // Document images
  final Rx<File?> idProofFront = Rx<File?>(null);
  final Rx<File?> idProofBack = Rx<File?>(null);
  final Rx<File?> addressProofFront = Rx<File?>(null);
  final Rx<File?> addressProofBack = Rx<File?>(null);

  // Existing server documents map: subdocument_type -> {status, image_url, id}
  final RxMap<String, Map<String, dynamic>> existingDocuments =
      <String, Map<String, dynamic>>{}.obs;

  // Upload states
  final RxBool isIdProofFrontUploaded = false.obs;
  final RxBool isIdProofBackUploaded = false.obs;
  final RxBool isAddressProofFrontUploaded = false.obs;
  final RxBool isAddressProofBackUploaded = false.obs;

  // Upload progress
  final RxMap<String, double> uploadProgress = <String, double>{}.obs;

  // Pick image from camera or gallery
  Future<void> pickImage({
    required String documentType,
    required ImageSource source,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 60, // Reduced from 80 to 60 for smaller file size
        maxWidth: 1200, // Reduced from 1920 to 1200
        maxHeight: 1200, // Reduced from 1080 to 1200
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Check file size and compress if needed
        final fileSize = await imageFile.length();
        print(
          '📸 Original image size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
        );

        // If file is larger than 1MB, show warning
        if (fileSize > 1024 * 1024) {
          print(
            '⚠️ Large image detected: ${(fileSize / 1024).toStringAsFixed(2)} KB',
          );
          CustomToastService.showWarning(
            message: 'Large image detected. Upload may take longer.',
          );
        }

        switch (documentType) {
          case 'id_proof_front':
            idProofFront.value = imageFile;
            break;
          case 'id_proof_back':
            idProofBack.value = imageFile;
            break;
          case 'address_proof_front':
            addressProofFront.value = imageFile;
            break;
          case 'address_proof_back':
            addressProofBack.value = imageFile;
            break;
        }

        // Don't auto-upload - wait for save button press
        CustomToastService.showSuccess(message: 'Image selected successfully!');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      errorMessage.value = 'Error picking image: $e';
      CustomToastService.showError(message: 'Error picking image: $e');
    }
  }

  @override
  void onInit() {
    super.onInit();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    try {
      isLoading.value = true;
      final token = await SecureStorageService.getAuthToken();
      _authToken.value = token ?? '';

      final response = await ApiService.get(
        endpoint: ApiConstants.kycStatus,
        token: token,
      );

      if (!response.success) {
        errorMessage.value = response.message ?? 'Failed to load KYC status';
        return;
      }

      final data = response.data;
      if (data is Map &&
          data['data'] != null &&
          data['data']['documents'] != null) {
        final List docs = data['data']['documents'] as List;
        final Map<String, Map<String, dynamic>> mapped = {};
        for (final d in docs) {
          final sub = d['subdocument_type']?.toString() ?? '';
          if (sub.isEmpty) continue;
          mapped[sub] = {
            'status': d['status']?.toString() ?? 'pending',
            'image_url': d['image_url']?.toString() ?? '',
            'id': d['id'],
            'remark': d['remark']?.toString() ?? '',
          };
        }
        existingDocuments.assignAll(mapped);
      }
    } catch (e) {
      errorMessage.value = 'Error fetching KYC status: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Helpers for UI
  Map<String, dynamic>? getExistingDoc(String subdocumentType) {
    return existingDocuments[subdocumentType];
  }

  String? getExistingDocUrl(String subdocumentType) {
    final doc = existingDocuments[subdocumentType];
    if (doc == null) return null;
    final url = doc['image_url']?.toString();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  Map<String, String> get authImageHeaders => {
    if (_authToken.value.isNotEmpty)
      'Authorization': 'Bearer ${_authToken.value}',
    'Accept': 'image/*',
  };

  // Upload document to API
  Future<void> uploadDocument(String documentType, File imageFile) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check file size before upload
      final fileSize = await imageFile.length();
      print('📤 Uploading file: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      if (fileSize > 2 * 1024 * 1024) {
        // 2MB limit
        throw Exception('File size too large. Please select a smaller image.');
      }

      final token = await SecureStorageService.getAuthToken();

      // Determine subdocument type and back side requirement
      String subdocumentType;
      bool backSideRequired = false;

      switch (documentType) {
        case 'id_proof_front':
          subdocumentType = 'id_proof_front';
          backSideRequired = false;
          break;
        case 'id_proof_back':
          subdocumentType = 'id_proof_back';
          backSideRequired = true;
          break;
        case 'address_proof_front':
          subdocumentType = 'address_proof_front';
          backSideRequired = false;
          break;
        case 'address_proof_back':
          subdocumentType = 'address_proof_back';
          backSideRequired = true;
          break;
        default:
          throw Exception('Invalid document type');
      }

      // Prepare form data
      final Map<String, dynamic> formData = {
        'document_type': 'kyc',
        'subdocument_type': subdocumentType,
        'back_side_required': backSideRequired ? '1' : '0',
      };

      print('📤 Starting upload for $documentType...');

      // Upload image with timeout
      final response = await ApiService.uploadFile(
        endpoint: ApiConstants.kycUpload,
        file: imageFile,
        formData: formData,
        token: token,
        onProgress: (progress) {
          uploadProgress[documentType] = progress;
          print('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      ).timeout(
        Duration(minutes: 5), // 5 minute timeout
        onTimeout: () {
          throw Exception('Upload timeout. Please try again.');
        },
      );

      if (response.success) {
        // Mark as uploaded
        switch (documentType) {
          case 'id_proof_front':
            isIdProofFrontUploaded.value = true;
            break;
          case 'id_proof_back':
            isIdProofBackUploaded.value = true;
            break;
          case 'address_proof_front':
            isAddressProofFrontUploaded.value = true;
            break;
          case 'address_proof_back':
            isAddressProofBackUploaded.value = true;
            break;
        }

        CustomToastService.showSuccess(
          message:
              '${_getDocumentDisplayName(documentType)} uploaded successfully!',
        );
      } else {
        errorMessage.value = response.message ?? 'Upload failed';
        CustomToastService.showError(
          message: response.message ?? 'Upload failed',
        );
      }
    } catch (e) {
      print('❌ Upload error for $documentType: $e');
      errorMessage.value = 'Error uploading document: $e';

      // Show specific error messages based on error type
      String userErrorMessage = 'Upload failed. Please try again.';
      if (e.toString().contains('timeout')) {
        userErrorMessage =
            'Upload timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('too large')) {
        userErrorMessage =
            'File size too large. Please select a smaller image.';
      } else if (e.toString().contains('network')) {
        userErrorMessage =
            'Network error. Please check your internet connection.';
      }

      CustomToastService.showError(message: userErrorMessage);
    } finally {
      isLoading.value = false;
      uploadProgress.remove(documentType);
      print('📤 Upload process completed for $documentType');
    }
  }

  // Get display name for document type
  String _getDocumentDisplayName(String documentType) {
    switch (documentType) {
      case 'id_proof_front':
        return 'ID Proof Front';
      case 'id_proof_back':
        return 'ID Proof Back';
      case 'address_proof_front':
        return 'Address Proof Front';
      case 'address_proof_back':
        return 'Address Proof Back';
      default:
        return 'Document';
    }
  }

  // Check if all required documents are selected
  bool get areAllRequiredDocumentsSelected {
    return idProofFront.value != null && addressProofFront.value != null;
  }

  // Check if all required documents are uploaded
  bool get areAllDocumentsUploaded {
    return isIdProofFrontUploaded.value && isAddressProofFrontUploaded.value;
  }

  // Check if specific document is uploaded
  bool isDocumentUploaded(String documentType) {
    switch (documentType) {
      case 'id_proof_front':
        return isIdProofFrontUploaded.value;
      case 'id_proof_back':
        return isIdProofBackUploaded.value;
      case 'address_proof_front':
        return isAddressProofFrontUploaded.value;
      case 'address_proof_back':
        return isAddressProofBackUploaded.value;
      default:
        return false;
    }
  }

  // Get image file for document type
  File? getImageFile(String documentType) {
    switch (documentType) {
      case 'id_proof_front':
        return idProofFront.value;
      case 'id_proof_back':
        return idProofBack.value;
      case 'address_proof_front':
        return addressProofFront.value;
      case 'address_proof_back':
        return addressProofBack.value;
      default:
        return null;
    }
  }

  // Upload all selected documents individually with correct subdocument types
  Future<void> uploadAllDocuments() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final token = await SecureStorageService.getAuthToken();

      // Upload each document individually with correct subdocument_type
      await _uploadDocument(
        idProofFront.value,
        'id_proof_front',
        'ID Proof Front',
        token ?? '',
      );
      await _uploadDocument(
        idProofBack.value,
        'id_proof_back',
        'ID Proof Back',
        token ?? '',
      );
      await _uploadDocument(
        addressProofFront.value,
        'address_proof_front',
        'Address Proof Front',
        token ?? '',
      );
      await _uploadDocument(
        addressProofBack.value,
        'address_proof_back',
        'Address Proof Back',
        token ?? '',
      );

      // Check if all required documents are uploaded
      bool allRequiredUploaded =
          isIdProofFrontUploaded.value && isAddressProofFrontUploaded.value;

      if (allRequiredUploaded) {
        CustomToastService.showSuccess(
          message: 'All required documents uploaded successfully!',
        );
      } else {
        CustomToastService.showError(
          message: 'Some documents failed to upload. Please try again.',
        );
      }
    } catch (e) {
      errorMessage.value = 'Error uploading documents: $e';
      CustomToastService.showError(message: 'Error uploading documents: $e');
    } finally {
      isLoading.value = false;
      uploadProgress.clear();
    }
  }

  // Upload individual document
  Future<void> _uploadDocument(
    File? file,
    String subdocumentType,
    String documentName,
    String token,
  ) async {
    if (file == null) return;

    try {
      // Prepare form data for this specific document
      final Map<String, dynamic> formData = {
        'document_type': 'kyc',
        'subdocument_type': subdocumentType,
        'back_side_required': '1',
      };

      // Upload single file
      final response = await ApiService.uploadFile(
        endpoint: ApiConstants.kycUpload,
        file: file,
        formData: formData,
        token: token,
        onProgress: (progress) {
          uploadProgress[subdocumentType] = progress;
        },
      );

      if (response.success) {
        // Mark this specific document as uploaded
        switch (subdocumentType) {
          case 'id_proof_front':
            isIdProofFrontUploaded.value = true;
            break;
          case 'id_proof_back':
            isIdProofBackUploaded.value = true;
            break;
          case 'address_proof_front':
            isAddressProofFrontUploaded.value = true;
            break;
          case 'address_proof_back':
            isAddressProofBackUploaded.value = true;
            break;
        }

        print('✅ $documentName uploaded successfully');
      } else {
        print('❌ $documentName upload failed: ${response.message}');
      }
    } catch (e) {
      print('❌ $documentName upload error: $e');
    }
  }

  // Clear all data
  void clearAllData() {
    idProofFront.value = null;
    idProofBack.value = null;
    addressProofFront.value = null;
    addressProofBack.value = null;

    isIdProofFrontUploaded.value = false;
    isIdProofBackUploaded.value = false;
    isAddressProofFrontUploaded.value = false;
    isAddressProofBackUploaded.value = false;

    uploadProgress.clear();
    errorMessage.value = '';
  }
}
