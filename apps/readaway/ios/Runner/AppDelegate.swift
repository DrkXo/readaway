import Flutter
import UIKit
// This is required for calling FlutterLocalNotificationsPlugin.setPluginRegistrantCallback method.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var initialFileMap: [String: String]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let messenger = controller?.binaryMessenger {
      setupMethodChannel(messenger: messenger)
    }

    if let url = launchOptions?[.url] as? URL {
      handleIncomingUrl(url, isInitial: true)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    handleIncomingUrl(url, isInitial: false)
    return super.application(app, open: url, options: options)
  }

  private func setupMethodChannel(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: "dev.readaway/file_opener", binaryMessenger: messenger)
    methodChannel?.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "getInitialFile" {
        let initial = self?.initialFileMap
        self?.initialFileMap = nil
        result(initial)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }

  private func handleIncomingUrl(_ url: URL, isInitial: Bool) {
    let isAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if isAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let filePath = url.path
    let fileName = url.lastPathComponent
    let fileMap: [String: String] = [
      "path": filePath,
      "fileName": fileName
    ]

    if isInitial && methodChannel == nil {
      initialFileMap = fileMap
    } else {
      methodChannel?.invokeMethod("openFile", arguments: fileMap)
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // This is required to make any communication available in the notification
    // action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
