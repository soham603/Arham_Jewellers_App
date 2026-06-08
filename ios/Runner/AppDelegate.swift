import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 1. ALWAYS register standard plugins first to prevent channel errors
    GeneratedPluginRegistrant.register(with: self)
    
    // 2. Use the plugin registrar to get a binary messenger (avoids rootViewController warnings)
    guard let registrar = self.registrar(forPlugin: "CustomFileSaver") else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // 3. Set up the Method Channel
    let fileSaverChannel = FlutterMethodChannel(
      name: "com.arhamjewellers/file_saver",
      binaryMessenger: registrar.messenger()
    )
    
    // 4. Handle Method Calls
    fileSaverChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      guard let self = self else { return }
      
      guard call.method == "saveToDownloads" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard let args = call.arguments as? [String: Any],
            let bytes = args["bytes"] as? FlutterStandardTypedData,
            let fileName = args["fileName"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "bytes and fileName are required", details: nil))
        return
      }

      let data = bytes.data
      let path = self.saveToDocuments(data: data, fileName: fileName)

      if let path = path {
        result(path)
      } else {
        result(FlutterError(code: "SAVE_FAILED", message: "Could not save file", details: nil))
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
}