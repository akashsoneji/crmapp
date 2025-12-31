import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../../../controllers/kyc/kyc_docs_controller.dart';
import '../../../../widgets/common_loading_widget.dart';

class KycCameraScreen extends StatefulWidget {
  @override
  State<KycCameraScreen> createState() => _KycCameraScreenState();
}

class _KycCameraScreenState extends State<KycCameraScreen> {
  final KycDocsController controller = Get.find<KycDocsController>();
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
    return const Center(
      child: CommonLoadingWidget(
        size: 40.0,
        color: Colors.white,
      ),
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
      Get.back();
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _closeCamera,
          ),
          title: const Text(
            'Take Document Photo',
            style: TextStyle(color: Colors.white),
          ),
        ),
      body: GetBuilder<KycDocsController>(
        builder: (controller) {
          // Check if controller is valid and initialized
          final camController = controller.cameraController;
          final isValid = camController != null && camController.value.isInitialized;
          
          return Stack(
            children: [
              // Camera Preview
              Positioned.fill(
                child: isValid
                    ? _buildCameraPreview(camController)
                    : const Center(
                        child: CommonLoadingWidget(
                          size: 40.0,
                          color: Colors.white,
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
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Capture button
                Obx(() => GestureDetector(
                      onTap: controller.isLoading.value
                          ? null
                          : controller.captureImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const Center(
                                child: CommonLoadingWidget(
                                  size: 30.0,
                                  color: Colors.black,
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    )),
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

