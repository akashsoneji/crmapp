import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import 'package:crm_app/constants/color.dart';
import 'package:crm_app/controllers/app_notification_controller.dart';
import 'package:crm_app/controllers/auth_controller.dart';
import 'package:crm_app/screens/home/kyc/unified_compliance_wizard_screen.dart';

// Document Type Model
class DocumentType {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  DocumentType({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

// KYC Controller
class KYCController extends GetxController {
  final RxBool showBottomSheet = false.obs;
  final RxString selectedDocument = ''.obs;
  final RxBool isUploading = false.obs;

  final List<DocumentType> documentTypes = [
    DocumentType(
      title: 'Passport',
      subtitle: 'International',
      icon: Icons.book,
      iconColor: AppColors.primary,
    ),
    DocumentType(
      title: 'ID/Aadhar card',
      subtitle: 'EU/GB Issued',
      icon: Icons.credit_card,
      iconColor: AppColors.primary,
    ),
    DocumentType(
      title: 'Driving License\'s',
      subtitle: 'EU/GB Issued',
      icon: Icons.directions_car,
      iconColor: AppColors.primary,
    ),
  ];

  bool get _mustSubmitRegulation {
    if (!Get.isRegistered<AuthController>()) return false;
    final user = Get.find<AuthController>().profileData?.data.user;
    return user?.mustSubmitRegulation ?? false;
  }

  void showDocumentSelection() {
    if (_mustSubmitRegulation) {
      Get.to(() => const UnifiedComplianceWizardScreen());
      return;
    }
    showBottomSheet.value = true;
  }

  void hideDocumentSelection() {
    showBottomSheet.value = false;
  }

  void selectDocument(DocumentType document) {
    selectedDocument.value = document.title;
    hideDocumentSelection();

    // Navigate to next step or handle document selection
    if (Get.isRegistered<AppNotificationController>()) {
      Get.find<AppNotificationController>().showSuccess(
        message: 'You selected ${document.title}',
        title: 'Document Selected',
      );
    }
  }
}
