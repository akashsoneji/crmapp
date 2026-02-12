import 'package:crm_app/core/widgets/common_loading_widget.dart';
import 'package:crm_app/core/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../../../../controllers/kyc/kyc_bank_controller.dart';

class KycBankCameraScreen extends StatefulWidget {
  @override
  State<KycBankCameraScreen> createState() => _KycBankCameraScreenState();
}

class _KycBankCameraScreenState extends State<KycBankCameraScreen> {
  final KycBankController controller = Get.find<KycBankController>();
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Widget _buildCameraPreview(CameraController camController) {
    try {
      // Double check controller is still valid before building preview
      if (!_isDisposed && 
          camController.value.isInitialized && 
          !camController.value.hasError) {
        return CameraPreview(camController);
      }
    } catch (e) {
      print('Error building camera preview: $e');
      // If preview fails, close camera screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          _closeCamera();
        }
      });
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
            'Take Proof Photo',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: GetBuilder<KycBankController>(
          builder: (controller) {
            // Check if controller is valid and initialized
            final camController = controller.cameraController;
            bool isValid = false;
            try {
              if (camController != null) {
                isValid = camController.value.isInitialized &&
                         !camController.value.hasError;
              }
            } catch (e) {
              print('Error checking camera state: $e');
              isValid = false;
              // If error checking state, close camera
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_isDisposed) {
                  _closeCamera();
                }
              });
            }
            
            // If camera is invalid, show error and close
            if (!isValid) {
              if (camController != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_isDisposed) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && !_isDisposed) {
                        CustomToastService.showError(
                          message: 'Camera initialization failed. Please try again.',
                        );
                        _closeCamera();
                      }
                    });
                  }
                });
              }
              return const Center(
                child: CommonLoadingWidget(
                  size: 40.0,
                  color: Colors.white,
                ),
              );
            }
            
            return Stack(
              children: [
                // Camera Preview with error boundary
                Positioned.fill(
                  child: _buildCameraPreview(camController!),
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

