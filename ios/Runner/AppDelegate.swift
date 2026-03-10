import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
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
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func updateWidgetData(lessons: [[String: Any]], groupName: String) {
    if let userDefaults = UserDefaults(suiteName: "group.com.uni-helper.app") {
      userDefaults.set(lessons, forKey: "todayLessons")
      userDefaults.set(groupName, forKey: "currentGroupName")
      userDefaults.synchronize()
      
      if #available(iOS 14.0, *) {
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
      }
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
