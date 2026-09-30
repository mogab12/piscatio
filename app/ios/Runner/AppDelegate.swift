import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StoriesPlugin") {
      StoriesPlugin.register(with: registrar)
    }
  }
}

/// Shares a card straight to Instagram Stories: the image goes on the
/// pasteboard and Instagram opens with the story composer (Meta's documented
/// way for iOS).
final class StoriesPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "piscatio/stories", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(StoriesPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "available":
      guard let url = URL(string: "instagram-stories://share") else {
        result(false)
        return
      }
      result(UIApplication.shared.canOpenURL(url))
    case "share":
      guard let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        let appId = args["appId"] as? String,
        let data = FileManager.default.contents(atPath: path),
        let url = URL(string: "instagram-stories://share?source_application=\(appId)"),
        UIApplication.shared.canOpenURL(url)
      else {
        result(false)
        return
      }
      let sticker = args["sticker"] as? Bool ?? false
      var item: [String: Any] = [
        sticker
          ? "com.instagram.sharedSticker.stickerImage"
          : "com.instagram.sharedSticker.backgroundImage": data
      ]
      if let top = args["top"] as? String {
        item["com.instagram.sharedSticker.backgroundTopColor"] = top
      }
      if let bottom = args["bottom"] as? String {
        item["com.instagram.sharedSticker.backgroundBottomColor"] = bottom
      }
      UIPasteboard.general.setItems(
        [item], options: [.expirationDate: Date().addingTimeInterval(5 * 60)])
      UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
