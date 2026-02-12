import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Navigation helper utility class for safe navigation operations
class NavigationHelper {
  /// Safely navigate back, handling snackbar controller initialization errors
  /// 
  /// This method gracefully handles errors when Get.back() tries to close
  /// snackbars but the controller is not initialized.
  /// 
  /// If context is provided, it will use Navigator.pop() as a fallback.
  static void safeBack({BuildContext? context}) {
    // First, try to close snackbars safely if possible
    try {
      Get.closeCurrentSnackbar();
    } catch (e) {
      // Ignore snackbar closing errors - not critical
    }

    // Then try to navigate back
    try {
      if (context != null && context.mounted) {
        // Prefer Navigator.pop() when context is available as it's more reliable
        Navigator.of(context).pop();
      } else {
        // Fallback to Get.back() if no context
        Get.back();
      }
    } catch (e) {
      // If Get.back() fails (e.g., snackbar controller not initialized),
      // use Navigator as fallback if context is available
      if (context != null && context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (navigatorError) {
          debugPrint('NavigationHelper: Error during Navigator.pop(): $navigatorError');
        }
      } else {
        debugPrint('NavigationHelper: Error during Get.back(): $e');
      }
    }
  }
}
