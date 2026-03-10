import Flutter

public class ScheduleWidgetShared {
    /// Клас для обміну даними між основним додатком та Widget Extension
    
    static let appGroupIdentifier = "group.com.uni-helper.app"
    
    /// Зберігає дані розкладу для Widget
    /// - Parameters:
    ///   - lessons: Array словників з ключами: title, startTime, endTime, lessonType
    ///   - groupName: Назва групи
    public static func saveLessonsToWidget(lessons: [[String: String]], groupName: String) {
        if let userDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            userDefaults.set(lessons, forKey: "todayLessons")
            userDefaults.set(groupName, forKey: "currentGroupName")
            userDefaults.synchronize()
            
            // Оновити Widget
            if #available(iOS 14.0, *) {
                WidgetKit.WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    /// Отримує збережені дані про розклад
    public static func getLessonsFromWidget() -> ([[String: String]]?, String?) {
        if let userDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            let lessons = userDefaults.array(forKey: "todayLessons") as? [[String: String]]
            let groupName = userDefaults.string(forKey: "currentGroupName")
            return (lessons, groupName)
        }
        return (nil, nil)
    }
    
    /// Очищує дані Widget
    public static func clearWidgetData() {
        if let userDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            userDefaults.removeObject(forKey: "todayLessons")
            userDefaults.removeObject(forKey: "currentGroupName")
            userDefaults.synchronize()
            
            if #available(iOS 14.0, *) {
                WidgetKit.WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}
