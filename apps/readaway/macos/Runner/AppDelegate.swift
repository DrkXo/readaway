import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var initialFileMap: [String: String]?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    if let messenger = controller?.engine.binaryMessenger {
      setupMethodChannel(messenger: messenger)
    }
    super.applicationDidFinishLaunching(notification)
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

  override func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    handleIncomingFile(filename)
    return true
  }

  override func application(_ sender: NSApplication, openFiles filenames: [String]) {
    if let first = filenames.first {
      handleIncomingFile(first)
    }
    sender.reply(toOpenOrPrint: .success)
  }

  private func handleIncomingFile(_ filePath: String) {
    let fileName = (filePath as NSString).lastPathComponent
    let fileMap: [String: String] = [
      "path": filePath,
      "fileName": fileName
    ]

    if methodChannel == nil {
      initialFileMap = fileMap
    } else {
      methodChannel?.invokeMethod("openFile", arguments: fileMap)
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
