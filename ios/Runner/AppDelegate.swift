import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Спочатку ініціалізуємо Flutter engine
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // Тепер Flutter engine готовий і rootViewController доступний
    if let controller = window?.rootViewController as? FlutterViewController {
      let widgetChannel = FlutterMethodChannel(
        name: "com.uni_helper/widget",
        binaryMessenger: controller.binaryMessenger
      )
      
      widgetChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        switch call.method {
        case "updateWidget":
          if let args = call.arguments as? [String: Any],
             let lessons = args["lessons"] as? [[String: Any]],
             let groupName = args["groupName"] as? String {
            self.updateWidgetData(lessons: lessons, groupName: groupName)
            result(true)
          } else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
          }
          
        case "clearWidget":
          self.clearWidgetData()
          result(true)
          
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return result
  }
  
  private func updateWidgetData(lessons: [[String: Any]], groupName: String) {
    if let userDefaults = UserDefaults(suiteName: "group.com.uni-helper.app") {
      // Конвертуємо в [[String: String]] та зберігаємо як JSON Data
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
    }
  }
  
  private func clearWidgetData() {
    if let userDefaults = UserDefaults(suiteName: "group.com.uni-helper.app") {
      userDefaults.removeObject(forKey: "todayLessons")
      userDefaults.removeObject(forKey: "currentGroupName")
      userDefaults.synchronize()
      
      if #available(iOS 14.0, *) {
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
