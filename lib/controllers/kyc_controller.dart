import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

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

  final List<DocumentType> documentTypes = [
    DocumentType(
      title: 'Passport',
      subtitle: 'International',
      icon: Icons.book,
      iconColor: const Color(0xFF7B2CBF),
    ),
    DocumentType(
      title: 'ID/Aadhar card',
      subtitle: 'EU/GB Issued',
      icon: Icons.credit_card,
      iconColor: const Color(0xFF7B2CBF),
    ),
    DocumentType(
      title: 'Driving License\'s',
      subtitle: 'EU/GB Issued',
      icon: Icons.directions_car,
      iconColor: const Color(0xFF7B2CBF),
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
      backgroundColor: const Color(0xFF7B2CBF),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
