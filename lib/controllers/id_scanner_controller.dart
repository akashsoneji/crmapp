import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/home/more/camera_screen.dart';
import '../controllers/app_notification_controller.dart';
import '../services/language_service.dart' show TranslationUtils;

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
      cameraController = CameraController(cameras![0], ResolutionPreset.high);

      try {
        await cameraController!.initialize();
        Get.to(() => CameraScreen());
      } catch (e) {
        print('Error starting camera: $e');
        if (Get.isRegistered<AppNotificationController>()) {
          Get.find<AppNotificationController>().showError(
            message: TranslationUtils.tr('id_scanner_camera_start_failed'),
            title: TranslationUtils.tr('common_error'),
          );
        }
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
        Get.back(closeOverlays: true);

        if (Get.isRegistered<AppNotificationController>()) {
          Get.find<AppNotificationController>().showSuccess(
            message: TranslationUtils.trArgs(
              'id_scanner_side_captured_successfully',
              {'side': currentSide.value.capitalizeFirst ?? currentSide.value},
            ),
            title: TranslationUtils.tr('common_success'),
          );
        }
      } catch (e) {
        print('Error capturing image: $e');
        if (Get.isRegistered<AppNotificationController>()) {
          Get.find<AppNotificationController>().showError(
            message: TranslationUtils.tr('id_scanner_capture_failed'),
            title: TranslationUtils.tr('common_error'),
          );
        }
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
      if (Get.isRegistered<AppNotificationController>()) {
        Get.find<AppNotificationController>().showError(
          message: TranslationUtils.tr('id_scanner_capture_front_required'),
          title: TranslationUtils.tr('id_scanner_missing_image'),
        );
      }
      return;
    }

    // Handle submission logic here
    if (Get.isRegistered<AppNotificationController>()) {
      Get.find<AppNotificationController>().showSuccess(
        message: TranslationUtils.tr('id_scanner_submitted_successfully'),
        title: TranslationUtils.tr('common_success'),
      );
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
