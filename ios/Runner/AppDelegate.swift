import Flutter
import Photos
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Set UNUserNotificationCenter delegate for foreground notification handling
    UNUserNotificationCenter.current().delegate = self
    
    // 1. ALWAYS register standard plugins first to prevent channel errors
    GeneratedPluginRegistrant.register(with: self)
    
    // 2. Use the plugin registrar to get a binary messenger (avoids rootViewController warnings)
    guard let registrar = self.registrar(forPlugin: "CustomFileSaver") else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // 3. Set up the Method Channel.
    // Gotcha: this name must match the Dart side exactly
    // (`MethodChannel('com.shreearhamgold.ratneshgold/file_saver')` in
    // share_service.dart). It previously read `com.arhamjewellers/file_saver`,
    // so every call from Dart — including saveToDownloads — silently hit
    // FlutterMethodNotImplemented on iOS. Keep the two in sync.
    let fileSaverChannel = FlutterMethodChannel(
      name: "com.shreearhamgold.ratneshgold/file_saver",
      binaryMessenger: registrar.messenger()
    )
    
    // 4. Handle Method Calls
    fileSaverChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      guard let self = self else { return }
      
      guard let args = call.arguments as? [String: Any],
            let bytes = args["bytes"] as? FlutterStandardTypedData,
            let fileName = args["fileName"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "bytes and fileName are required", details: nil))
        return
      }

      switch call.method {
      case "saveToDownloads":
        let path = self.saveToDocuments(data: bytes.data, fileName: fileName)
        if let path = path {
          result(path)
        } else {
          result(FlutterError(code: "SAVE_FAILED", message: "Could not save file", details: nil))
        }
      case "saveImageToGallery":
        self.saveImageToPhotoLibrary(data: bytes.data, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Push Notification Handlers
  
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Forward token to Firebase/Messaging if available
    // The firebase_messaging plugin handles this automatically
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
  }
  
  // MARK: - UNUserNotificationCenterDelegate
  
  // Handle notifications when app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // Show notification even when app is in foreground
    completionHandler([.banner, .badge, .sound])
  }
  
  // Handle notification tap when app is in background or terminated
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    // The firebase_messaging plugin handles notification tap routing
    completionHandler()
  }

  // MARK: - Helper Methods
  
  private func saveToDocuments(data: Data, fileName: String) -> String? {
    guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      return nil
    }

    let fileURL = documentsDir.appendingPathComponent(fileName)

    do {
      try data.write(to: fileURL)
      return fileURL.path
    } catch {
      print("Failed to save PDF: \(error)")
      return nil
    }
  }

  private func requestPhotoLibraryAddPermission(completion: @escaping (Bool) -> Void) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        completion(status == .authorized || status == .limited)
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        completion(status == .authorized)
      }
    }
  }

  private func saveImageToPhotoLibrary(data: Data, result: @escaping FlutterResult) {
    guard let image = UIImage(data: data) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Could not decode image data", details: nil))
      return
    }

    requestPhotoLibraryAddPermission { granted in
      guard granted else {
        DispatchQueue.main.async {
          result(FlutterError(
            code: "PERMISSION_DENIED",
            message: "Photo library permission is required to save images",
            details: nil
          ))
        }
        return
      }

      PHPhotoLibrary.shared().performChanges({
        PHAssetChangeRequest.creationRequestForAsset(from: image)
      }) { success, error in
        DispatchQueue.main.async {
          if success {
            result("saved")
          } else {
            result(FlutterError(
              code: "SAVE_FAILED",
              message: error?.localizedDescription ?? "Could not save image to gallery",
              details: nil
            ))
          }
        }
      }
    }
  }
}