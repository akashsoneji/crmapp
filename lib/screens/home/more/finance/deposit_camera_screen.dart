import 'package:crm_app/constants/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../../../controllers/finance/deposit_instrction_controller.dart';
import '../../../../widgets/common_loading_widget.dart';

class DepositCameraScreen extends StatefulWidget {
  @override
  State<DepositCameraScreen> createState() => _DepositCameraScreenState();
}

class _DepositCameraScreenState extends State<DepositCameraScreen> {
  final DepositInstructionController controller =
      Get.find<DepositInstructionController>();
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Widget _buildCameraPreview(CameraController camController) {
    try {
      // Double check controller is still valid before building preview
      if (camController.value.isInitialized) {
        return CameraPreview(camController);
      }
    } catch (e) {
      print('Error building camera preview: $e');
    }
    return   Center(
      child: CommonLoadingWidget(size: 40.0, color: AppColors.onColoredBackground),
    );
  }

  void _closeCamera() async {
    if (_isDisposed) return;

    try {
      if (controller.cameraController != null) {
        final camController = controller.cameraController;
        controller.cameraController = null; // Clear reference first
        controller.update(); // Notify GetBuilder
        await Future.delayed(const Duration(milliseconds: 50));
        await camController?.dispose();
      }
    } catch (e) {
      print('Error disposing camera: $e');
    }

    if (mounted && !_isDisposed) {
      Get.back(closeOverlays: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _closeCamera();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cameraBackground,
        appBar: AppBar(
          backgroundColor: AppColors.cameraBackground,
          leading: IconButton(
            icon:   Icon(Icons.close, color: AppColors.onColoredBackground),
            onPressed: _closeCamera,
          ),
          title:   Text(
            'Take Payment Proof Photo',
            style: TextStyle(color: AppColors.onColoredBackground),
          ),
        ),
        body: GetBuilder<DepositInstructionController>(
          builder: (controller) {
            // Check if controller is valid and initialized
            final camController = controller.cameraController;
            final isValid =
                camController != null && camController.value.isInitialized;

            return Stack(
              children: [
                // Camera Preview
                Positioned.fill(
                  child:
                      isValid
                          ? _buildCameraPreview(camController)
                          :   Center(
                            child: CommonLoadingWidget(
                              size: 40.0,
                              color: AppColors.onColoredBackground,
                            ),
                          ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel button
                      GestureDetector(
                        onTap: _closeCamera,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.onColoredBackground.withOpacity(0.24),
                            shape: BoxShape.circle,
                          ),
                          child:   Icon(
                            Icons.close,
                            color: AppColors.onColoredBackground,
                            size: 28,
                          ),
                        ),
                      ),

                      // Capture button
                      Obx(
                        () => GestureDetector(
                          onTap:
                              controller.isLoading.value
                                  ? null
                                  : controller.captureImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.onColoredBackground,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.onColoredBackground, width: 4),
                            ),
                            child:
                                controller.isLoading.value
                                    ? Center(
                                      child: CommonLoadingWidget(
                                        size: 30.0,
                                        color: AppColors.onColoredBackground,
                                      ),
                                    )
                                    : Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration:   BoxDecoration(
                                        color: AppColors.onColoredBackground,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
