import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import 'package:pipze/constants/color.dart';

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

  void showDocumentSelection() {
    showBottomSheet.value = true;
  }

  void hideDocumentSelection() {
    showBottomSheet.value = false;
  }

  void selectDocument(DocumentType document) {
    selectedDocument.value = document.title;
    hideDocumentSelection();

    // Navigate to next step or handle document selection
    Get.snackbar(
      'Document Selected',
      'You selected ${document.title}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
