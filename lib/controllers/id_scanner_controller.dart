

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/home/more/camera_screen.dart';

class IdScannerController extends GetxController {
  var frontImagePath = ''.obs;
  var backImagePath = ''.obs;
  var isLoading = false.obs;
  var currentSide = 'front'.obs; // 'front' or 'back'

  CameraController? cameraController;
  List<CameraDescription>? cameras;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future<void> startCamera() async {
    await requestCameraPermission();

    if (cameras != null && cameras!.isNotEmpty) {
      cameraController = CameraController(
        cameras![0],
        ResolutionPreset.high,
      );

      try {
        await cameraController!.initialize();
        Get.to(() => CameraScreen());
      } catch (e) {
        print('Error starting camera: $e');
        Get.snackbar(
          'Error',
          'Failed to start camera. Please check permissions.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> captureImage() async {
    if (cameraController != null && cameraController!.value.isInitialized) {
      try {
        isLoading.value = true;
        final image = await cameraController!.takePicture();

        if (currentSide.value == 'front') {
          frontImagePath.value = image.path;
        } else {
          backImagePath.value = image.path;
        }

        await cameraController!.dispose();
        cameraController = null;
        Get.back();

        Get.snackbar(
          'Success',
          '${currentSide.value.capitalizeFirst} side captured successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        print('Error capturing image: $e');
        Get.snackbar(
          'Error',
          'Failed to capture image',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  void setCameraForFrontSide() {
    currentSide.value = 'front';
    startCamera();
  }

  void setCameraForBackSide() {
    currentSide.value = 'back';
    startCamera();
  }

  void submitRequest() {
    if (frontImagePath.value.isEmpty) {
      Get.snackbar(
        'Missing Image',
        'Please capture the front side of your ID',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Handle submission logic here
    Get.snackbar(
      'Success',
      'ID card submitted successfully!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}