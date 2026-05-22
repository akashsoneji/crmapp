import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup deep link handler for crmapp:// scheme
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.crmapp/deeplink", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "getInitialUrl" {
        if let url = launchOptions?[.url] as? URL {
          result(url.absoluteString)
        } else {
          result(nil)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Handle deep links when app is running (not just cold start)
    if #available(iOS 13.0, *) {
      // Scene delegate will handle these
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle URL scheme when app is already running
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.crmapp/deeplink", binaryMessenger: controller.binaryMessenger)
    channel.invokeMethod("onDeepLink", arguments: url.absoluteString)
    return true
  }
}
