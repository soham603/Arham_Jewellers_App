import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPlugin, FlutterImplicitEngineDelegate {
  private var channel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - FlutterPlugin

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.arhamjewellers/file_saver",
      binaryMessenger: registrar.messenger()
    )
    let instance = AppDelegate()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
    let path = saveToDocuments(data: data, fileName: fileName)

    if let path = path {
      result(path)
    } else {
      result(FlutterError(code: "SAVE_FAILED", message: "Could not save file", details: nil))
    }
  }

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
