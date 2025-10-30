// import 'dart:io';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:pipze/constants/api_const.dart';
// import 'package:pipze/services/api_service.dart';
// import 'package:pipze/services/secure_storage_service.dart';
// import 'package:pipze/widgets/custom_toast.dart';

// class KycDocsController extends GetxController {
//   final ImagePicker _picker = ImagePicker();

//   // Observable variables
//   final RxBool isLoading = false.obs;
//   final RxString errorMessage = ''.obs;
//   final RxString _authToken = ''.obs;

//   // Document images
//   final Rx<File?> idProofFront = Rx<File?>(null);
//   final Rx<File?> idProofBack = Rx<File?>(null);
//   final Rx<File?> addressProofFront = Rx<File?>(null);
//   final Rx<File?> addressProofBack = Rx<File?>(null);

//   // Existing server documents map: subdocument_type -> {status, image_url, id}
//   final RxMap<String, Map<String, dynamic>> existingDocuments =
//       <String, Map<String, dynamic>>{}.obs;

//   // Upload states
//   final RxBool isIdProofFrontUploaded = false.obs;
//   final RxBool isIdProofBackUploaded = false.obs;
//   final RxBool isAddressProofFrontUploaded = false.obs;
//   final RxBool isAddressProofBackUploaded = false.obs;

//   // Upload progress
//   final RxMap<String, double> uploadProgress = <String, double>{}.obs;

//   // Pick image from camera or gallery
//   Future<void> pickImage({
//     required String documentType,
//     required ImageSource source,
//   }) async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: source,
//         imageQuality: 60, // Reduced from 80 to 60 for smaller file size
//         maxWidth: 1200, // Reduced from 1920 to 1200
//         maxHeight: 1200, // Reduced from 1080 to 1200
//       );

//       if (image != null) {
//         final File imageFile = File(image.path);

//         // Check file size and compress if needed
//         final fileSize = await imageFile.length();
//         print(
//           '📸 Original image size: ${(fileSize / 1024).toStringAsFixed(2)} KB',
//         );

//         // If file is larger than 1MB, show warning
//         if (fileSize > 1024 * 1024) {
//           print(
//             '⚠️ Large image detected: ${(fileSize / 1024).toStringAsFixed(2)} KB',
//           );
//           CustomToastService.showWarning(
//             message: 'Large image detected. Upload may take longer.',
//           );
//         }

//         switch (documentType) {
//           case 'id_proof_front':
//             idProofFront.value = imageFile;
//             break;
//           case 'id_proof_back':
//             idProofBack.value = imageFile;
//             break;
//           case 'address_proof_front':
//             addressProofFront.value = imageFile;
//             break;
//           case 'address_proof_back':
//             addressProofBack.value = imageFile;
//             break;
//         }

//         // Don't auto-upload - wait for save button press
//         CustomToastService.showSuccess(message: 'Image selected successfully!');
//       }
//     } catch (e) {
//       print('❌ Error picking image: $e');
//       errorMessage.value = 'Error picking image: $e';
//       CustomToastService.showError(message: 'Error picking image: $e');
//     }
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     _loadKycStatus();
//   }

//   Future<void> _loadKycStatus() async {
//     try {
//       isLoading.value = true;
//       final token = await SecureStorageService.getAuthToken();
//       _authToken.value = token ?? '';

//       final response = await ApiService.get(
//         endpoint: ApiConstants.kycStatus,
//         token: token,
//       );

//       if (!response.success) {
//         errorMessage.value = response.message ?? 'Failed to load KYC status';
//         return;
//       }

//       final data = response.data;
//       if (data is Map &&
//           data['data'] != null &&
//           data['data']['documents'] != null) {
//         final List docs = data['data']['documents'] as List;
//         final Map<String, Map<String, dynamic>> mapped = {};
//         for (final d in docs) {
//           final sub = d['subdocument_type']?.toString() ?? '';
//           if (sub.isEmpty) continue;
//           mapped[sub] = {
//             'status': d['status']?.toString() ?? 'pending',
//             'image_url': d['image_url']?.toString() ?? '',
//             'id': d['id'],
//             'remark': d['remark']?.toString() ?? '',
//           };
//         }
//         existingDocuments.assignAll(mapped);
//       }
//     } catch (e) {
//       errorMessage.value = 'Error fetching KYC status: $e';
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Helpers for UI
//   Map<String, dynamic>? getExistingDoc(String subdocumentType) {
//     return existingDocuments[subdocumentType];
//   }

//   String? getExistingDocUrl(String subdocumentType) {
//     final doc = existingDocuments[subdocumentType];
//     if (doc == null) return null;
//     final url = doc['image_url']?.toString();
//     if (url == null || url.isEmpty) return null;
//     return url;
//   }

//   Map<String, String> get authImageHeaders => {
//     if (_authToken.value.isNotEmpty)
//       'Authorization': 'Bearer ${_authToken.value}',
//     'Accept': 'image/*',
//   };

//   // Upload a single selected document for the given type
//   Future<void> uploadSingle(String documentType) async {
//     final file = getImageFile(documentType);
//     if (file == null) {
//       CustomToastService.showError(message: 'Please select a file first');
//       return;
//     }
//     try {
//       isLoading.value = true;
//       final token = await SecureStorageService.getAuthToken() ?? '';
//       final ok = await _uploadDocument(
//         file,
//         documentType,
//         _getDocumentDisplayName(documentType),
//         token,
//       );
//       if (ok) {
//         _clearSelectedFor(documentType);
//         _markServerStatusPending(documentType);
//         await _loadKycStatus();
//         CustomToastService.showSuccess(message: 'Document uploaded');
//       }
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Upload document to API

//   // Get display name for document type
//   String _getDocumentDisplayName(String documentType) {
//     switch (documentType) {
//       case 'id_proof_front':
//         return 'ID Proof Front';
//       case 'id_proof_back':
//         return 'ID Proof Back';
//       case 'address_proof_front':
//         return 'Address Proof Front';
//       case 'address_proof_back':
//         return 'Address Proof Back';
//       default:
//         return 'Document';
//     }
//   }

//   // Check if all required documents are selected
//   bool get areAllRequiredDocumentsSelected {
//     return idProofFront.value != null && addressProofFront.value != null;
//   }

//   // Check if user has selected any document (used to enable bottom upload)
//   bool get hasAnySelected {
//     return idProofFront.value != null ||
//         idProofBack.value != null ||
//         addressProofFront.value != null ||
//         addressProofBack.value != null;
//   }

//   // Check if all required documents are uploaded
//   bool get areAllDocumentsUploaded {
//     return isIdProofFrontUploaded.value && isAddressProofFrontUploaded.value;
//   }

//   // Check if required documents are satisfied either by server approval or fresh upload
//   bool get areRequiredDocsSatisfied {
//     final idFrontServerApproved =
//         (existingDocuments['id_proof_front']?['status']
//                 ?.toString()
//                 .toLowerCase() ??
//             '') ==
//         'approved';
//     final addrFrontServerApproved =
//         (existingDocuments['address_proof_front']?['status']
//                 ?.toString()
//                 .toLowerCase() ??
//             '') ==
//         'approved';

//     final idOk = idFrontServerApproved || isIdProofFrontUploaded.value;
//     final addrOk = addrFrontServerApproved || isAddressProofFrontUploaded.value;
//     return idOk && addrOk;
//   }

//   // Check if specific document is uploaded
//   bool isDocumentUploaded(String documentType) {
//     switch (documentType) {
//       case 'id_proof_front':
//         return isIdProofFrontUploaded.value;
//       case 'id_proof_back':
//         return isIdProofBackUploaded.value;
//       case 'address_proof_front':
//         return isAddressProofFrontUploaded.value;
//       case 'address_proof_back':
//         return isAddressProofBackUploaded.value;
//       default:
//         return false;
//     }
//   }

//   // Get image file for document type
//   File? getImageFile(String documentType) {
//     switch (documentType) {
//       case 'id_proof_front':
//         return idProofFront.value;
//       case 'id_proof_back':
//         return idProofBack.value;
//       case 'address_proof_front':
//         return addressProofFront.value;
//       case 'address_proof_back':
//         return addressProofBack.value;
//       default:
//         return null;
//     }
//   }

//   // Upload all selected documents individually with correct subdocument types
//   Future<void> uploadAllDocuments() async {
//     try {
//       isLoading.value = true;
//       errorMessage.value = '';

//       final token = await SecureStorageService.getAuthToken();

//       // Upload each document individually with correct subdocument_type
//       final ok1 = await _uploadDocument(
//         idProofFront.value,
//         'id_proof_front',
//         'ID Proof Front',
//         token ?? '',
//       );
//       if (ok1) {
//         _clearSelectedFor('id_proof_front');
//         _markServerStatusPending('id_proof_front');
//       }
//       final ok2 = await _uploadDocument(
//         idProofBack.value,
//         'id_proof_back',
//         'ID Proof Back',
//         token ?? '',
//       );
//       if (ok2) {
//         _clearSelectedFor('id_proof_back');
//         _markServerStatusPending('id_proof_back');
//       }
//       final ok3 = await _uploadDocument(
//         addressProofFront.value,
//         'address_proof_front',
//         'Address Proof Front',
//         token ?? '',
//       );
//       if (ok3) {
//         _clearSelectedFor('address_proof_front');
//         _markServerStatusPending('address_proof_front');
//       }
//       final ok4 = await _uploadDocument(
//         addressProofBack.value,
//         'address_proof_back',
//         'Address Proof Back',
//         token ?? '',
//       );
//       if (ok4) {
//         _clearSelectedFor('address_proof_back');
//         _markServerStatusPending('address_proof_back');
//       }

//       // Check if all required documents are uploaded
//       bool allRequiredUploaded =
//           isIdProofFrontUploaded.value && isAddressProofFrontUploaded.value;

//       if (allRequiredUploaded) {
//         CustomToastService.showSuccess(
//           message: 'All required documents uploaded successfully!',
//         );
//       } else {
//         CustomToastService.showError(
//           message: 'Some documents failed to upload. Please try again.',
//         );
//       }
//     } catch (e) {
//       errorMessage.value = 'Error uploading documents: $e';
//       CustomToastService.showError(message: 'Error uploading documents: $e');
//     } finally {
//       isLoading.value = false;
//       uploadProgress.clear();
//     }
//   }

//   // Upload individual document
//   Future<bool> _uploadDocument(
//     File? file,
//     String subdocumentType,
//     String documentName,
//     String token,
//   ) async {
//     if (file == null) return false;

//     try {
//       // Prepare form data for this specific document
//       final Map<String, dynamic> formData = {
//         'document_type': 'kyc',
//         'subdocument_type': subdocumentType,
//         // 'back_side_required': false,
//       };

//       // Upload single file
//       final response = await ApiService.uploadFile(
//         endpoint: ApiConstants.kycUpload,
//         file: file,
//         formData: formData,
//         token: token,
//         onProgress: (progress) {
//           uploadProgress[subdocumentType] = progress;
//         },
//       );

//       if (response.success) {
//         // Mark this specific document as uploaded
//         switch (subdocumentType) {
//           case 'id_proof_front':
//             isIdProofFrontUploaded.value = true;
//             break;
//           case 'id_proof_back':
//             isIdProofBackUploaded.value = true;
//             break;
//           case 'address_proof_front':
//             isAddressProofFrontUploaded.value = true;
//             break;
//           case 'address_proof_back':
//             isAddressProofBackUploaded.value = true;
//             break;
//         }

//         print('✅ $documentName uploaded successfully');
//         return true;
//       } else {
//         print('❌ $documentName upload failed: ${response.message}');
//         return false;
//       }
//     } catch (e) {
//       print('❌ $documentName upload error: $e');
//       return false;
//     }
//   }

//   void _clearSelectedFor(String documentType) {
//     switch (documentType) {
//       case 'id_proof_front':
//         idProofFront.value = null;
//         break;
//       case 'id_proof_back':
//         idProofBack.value = null;
//         break;
//       case 'address_proof_front':
//         addressProofFront.value = null;
//         break;
//       case 'address_proof_back':
//         addressProofBack.value = null;
//         break;
//     }
//   }

//   void _markServerStatusPending(String documentType) {
//     final existing = Map<String, dynamic>.from(
//       existingDocuments[documentType] ?? {},
//     );
//     existing['status'] = 'pending';
//     existingDocuments[documentType] = existing;
//     // trigger observers
//     existingDocuments.refresh();
//   }

//   // Clear all data
//   void clearAllData() {
//     idProofFront.value = null;
//     idProofBack.value = null;
//     addressProofFront.value = null;
//     addressProofBack.value = null;

//     isIdProofFrontUploaded.value = false;
//     isIdProofBackUploaded.value = false;
//     isAddressProofFrontUploaded.value = false;
//     isAddressProofBackUploaded.value = false;

//     uploadProgress.clear();
//     errorMessage.value = '';
//   }
// }
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
      // Enforce gating at controller level as a safety net
      if (!canUpload(documentType)) {
        CustomToastService.showInfo(
          message: 'This document is optional or not allowed to upload now',
        );
        return;
      }
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
        final Map<String, DateTime> latestAt = {};
        for (final d in docs) {
          final sub = d['subdocument_type']?.toString() ?? '';
          if (sub.isEmpty) continue;
          // choose latest by created_at fallback to id
          DateTime created;
          try {
            created = DateTime.parse((d['created_at'] ?? '').toString());
          } catch (_) {
            final id =
                (d['id'] is int)
                    ? d['id'] as int
                    : int.tryParse('${d['id']}') ?? 0;
            created = DateTime.fromMillisecondsSinceEpoch(id);
          }
          final prev = latestAt[sub];
          if (prev != null && prev.isAfter(created)) {
            continue;
          }
          latestAt[sub] = created;
          mapped[sub] = {
            'status': d['status']?.toString() ?? 'pending',
            'image_url': d['image_url']?.toString() ?? '',
            'id': d['id'],
            'remark': d['remark']?.toString() ?? '',
            // correct field from API: back_side_required
            if (d.containsKey('back_side_required'))
              'back_side_required': d['back_side_required'],
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

  // ===== Requirement & gating helpers =====
  bool isBackRequired(String group) {
    final front = getExistingDoc('${group}_front');
    final requireVal = (front?['back_side_required'] ?? 0).toString();
    return requireVal == '1';
  }

  bool isRequired(String documentType) {
    if (documentType.endsWith('_front')) return true;
    final group =
        documentType.startsWith('id_proof') ? 'id_proof' : 'address_proof';
    return isBackRequired(group);
  }

  String statusFor(String documentType) {
    return (getExistingDoc(documentType)?['status'] ?? 'none')
        .toString()
        .toLowerCase();
  }

  bool canUpload(String documentType) {
    final status = statusFor(documentType);
    if (status == 'approved') return false; // don't allow uploads over approved
    if (status == 'rejected') return true; // allow re-upload of rejected
    final required = isRequired(documentType);
    final hasLocal = getImageFile(documentType) != null;
    final hasServer = getExistingDoc(documentType) != null && status != 'none';
    if (required && !hasLocal && !hasServer) return true; // first-time required
    if (!required) {
      // Optional backs: allow first-time upload, and allow if rejected; block if pending/approved
      if (!hasServer && !hasLocal) return true; // allow optional upload
      if (status == 'pending') return false;
      if (status == 'rejected') return true;
      return false; // approved handled above
    }
    return false;
  }

  // Selected-any helper to enable common upload button for multiple rejected docs
  bool get hasAnySelected {
    return idProofFront.value != null ||
        idProofBack.value != null ||
        addressProofFront.value != null ||
        addressProofBack.value != null;
  }

  // Upload document to API

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

  // Check if all required documents are selected (initial flow)
  bool get areAllRequiredDocumentsSelected {
    return idProofFront.value != null && addressProofFront.value != null;
  }

  // Check if all required documents are uploaded
  bool get areAllDocumentsUploaded {
    // Determine required types dynamically (backs depend on requirement)
    final List<String> requiredTypes = [
      'id_proof_front',
      'address_proof_front',
    ];
    if (isBackRequired('id_proof')) requiredTypes.add('id_proof_back');
    if (isBackRequired('address_proof'))
      requiredTypes.add('address_proof_back');

    bool isTypeSatisfied(String t) {
      final status = statusFor(t);
      final satisfiedByServer = status == 'pending' || status == 'approved';
      final satisfiedByLocal = isDocumentUploaded(t);
      return satisfiedByServer || satisfiedByLocal;
    }

    for (final t in requiredTypes) {
      if (!isTypeSatisfied(t)) return false;
    }
    return true;
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

      // Prepare list of selected uploads
      final uploads = <Map<String, dynamic>>[
        {
          'file': idProofFront.value,
          'type': 'id_proof_front',
          'name': 'ID Proof Front',
        },
        {
          'file': idProofBack.value,
          'type': 'id_proof_back',
          'name': 'ID Proof Back',
        },
        {
          'file': addressProofFront.value,
          'type': 'address_proof_front',
          'name': 'Address Proof Front',
        },
        {
          'file': addressProofBack.value,
          'type': 'address_proof_back',
          'name': 'Address Proof Back',
        },
      ];

      final attempted = uploads.where((u) => u['file'] != null).length;
      int succeeded = 0;

      for (final u in uploads) {
        final file = u['file'] as File?;
        if (file == null) continue;
        final ok = await _uploadDocument(
          file,
          u['type'] as String,
          u['name'] as String,
          token ?? '',
        );
        if (ok) succeeded++;
      }

      // Refresh server state once after all uploads
      await _loadKycStatus();

      if (attempted == 0) {
        CustomToastService.showError(message: 'Please select a document first');
      } else if (succeeded == attempted) {
        CustomToastService.showSuccess(message: 'Upload successful');
      } else {
        CustomToastService.showError(
          message: 'Some documents failed to upload. Please re-upload.',
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
  Future<bool> _uploadDocument(
    File file,
    String subdocumentType,
    String documentName,
    String token,
  ) async {
    try {
      // Prepare form data for this specific document
      final Map<String, dynamic> formData = {
        'document_type': 'kyc',
        'subdocument_type': subdocumentType,
        // 'back_side_required': false,
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

        // Clear local selection for this doc and optimistically set pending
        _clearSelectedFor(subdocumentType);
        _markServerStatusPending(subdocumentType);

        print('✅ $documentName uploaded successfully');
        return true;
      } else {
        print('❌ $documentName upload failed: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ $documentName upload error: $e');
      return false;
    }
  }

  void _clearSelectedFor(String documentType) {
    switch (documentType) {
      case 'id_proof_front':
        idProofFront.value = null;
        break;
      case 'id_proof_back':
        idProofBack.value = null;
        break;
      case 'address_proof_front':
        addressProofFront.value = null;
        break;
      case 'address_proof_back':
        addressProofBack.value = null;
        break;
    }
  }

  void _markServerStatusPending(String documentType) {
    final existing = Map<String, dynamic>.from(
      existingDocuments[documentType] ?? {},
    );
    existing['status'] = 'pending';
    existingDocuments[documentType] = existing;
    existingDocuments.refresh();
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
