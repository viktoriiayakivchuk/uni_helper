import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Зберігаємо як instance property щоб ARC не знищив канал
  private var widgetChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    setupWidgetChannel()
    return result
  }
  
  private func setupWidgetChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      print("⚠️ Widget channel: FlutterViewController not available yet")
      return
    }
    
    widgetChannel = FlutterMethodChannel(
      name: "com.uni_helper/widget",
      binaryMessenger: controller.binaryMessenger
    )
    
    widgetChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "updateWidget":
        if let args = call.arguments as? [String: Any],
           let lessons = args["lessons"] as? [[String: Any]],
           let groupName = args["groupName"] as? String {
          self?.updateWidgetData(lessons: lessons, groupName: groupName)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
        
      case "clearWidget":
        self?.clearWidgetData()
        result(true)
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    print("✅ Widget channel registered successfully")
  }
  
  private func updateWidgetData(lessons: [[String: Any]], groupName: String) {
    if let userDefaults = UserDefaults(suiteName: "group.com.uni-helper.app") {
      let stringLessons = lessons.map { dict -> [String: String] in
        var result: [String: String] = [:]
        for (key, value) in dict {
          result[key] = "\(value)"
        }
        return result
      }
      if let jsonData = try? JSONSerialization.data(withJSONObject: stringLessons) {
        userDefaults.set(jsonData, forKey: "todayLessons")
      }
      userDefaults.set(groupName, forKey: "currentGroupName")
      userDefaults.synchronize()
      
      WidgetKit.WidgetCenter.shared.reloadAllTimelines()
      print("✅ Widget data updated: \(stringLessons.count) lessons, group: \(groupName)")
    }
  }
  
  private func clearWidgetData() {
    if let userDefaults = UserDefaults(suiteName: "group.com.uni-helper.app") {
      userDefaults.removeObject(forKey: "todayLessons")
      userDefaults.removeObject(forKey: "currentGroupName")
      userDefaults.synchronize()
      WidgetKit.WidgetCenter.shared.reloadAllTimelines()
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Якщо канал ще не зареєстровано — спробувати тут
    if widgetChannel == nil {
      setupWidgetChannel()
    }
  }
}
