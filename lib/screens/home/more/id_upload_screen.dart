import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crm_app/constants/color.dart';
import 'dart:io';

import '../../../controllers/id_scanner_controller.dart';
import '../../../services/language_service.dart';

class IdUploadScreen extends StatelessWidget {
  final IdScannerController controller = Get.put(IdScannerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(closeOverlays: true),
        ),
        title: Text(
          'ID/Aadhar card',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The document you are providing must be valid at least 30 days and contain all of the following details:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 40),

            // Front Side Card
            Obx(
              () => _buildImageCard(
                title: Get.find<LanguageService>().tr('id_upload_front_side'),
                imagePath: controller.frontImagePath.value,
                onTap: controller.setCameraForFrontSide,
              ),
            ),

            SizedBox(height: 20),

            // Back Side Card
            Obx(
              () => _buildImageCard(
                title: Get.find<LanguageService>().tr('id_upload_back_side'),
                imagePath: controller.backImagePath.value,
                onTap: controller.setCameraForBackSide,
              ),
            ),

            SizedBox(height: 30),

            // Guidelines
            _buildGuideline(
              icon: Icons.check_circle,
              text:
                  'Upload a colourful full-size (4 sides visible) photo of the document',
              isPositive: true,
            ),

            SizedBox(height: 12),

            _buildGuideline(
              icon: Icons.cancel,
              text:
                  'Do not upload selfies, screenshots and do not modify the images in graphic editors.',
              isPositive: false,
            ),

            Spacer(),

            // Submit Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Submit Request',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child:
            imagePath.isEmpty
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        File(imagePath),
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildGuideline({
    required IconData icon,
    required String text,
    required bool isPositive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: isPositive ? Colors.green : Colors.red, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
