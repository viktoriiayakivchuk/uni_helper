import Foundation

// MARK: - Data Manager for Widget
class ScheduleDataManager {
    static let shared = ScheduleDataManager()
    
    private let appGroupIdentifier = "group.com.uni-helper.app"
    private let lessonsKey = "todayLessons"
    private let groupNameKey = "currentGroupName"
    
    private lazy var userDefaults: UserDefaults? = {
        return UserDefaults(suiteName: appGroupIdentifier)
    }()
    
    // MARK: - Save Data
    func saveLessons(_ lessons: [[String: String]]) {
        if let data = try? JSONSerialization.data(withJSONObject: lessons) {
            userDefaults?.set(data, forKey: lessonsKey)
            userDefaults?.synchronize()
        }
    }
    
    func saveGroupName(_ name: String) {
        userDefaults?.set(name, forKey: groupNameKey)
        userDefaults?.synchronize()
    }
    
    // MARK: - Load Data
    func loadTodayLessons() -> [LessonWidget] {
        guard let data = userDefaults?.data(forKey: lessonsKey),
              let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }
        
        return jsonArray.compactMap { dict in
            guard let title = dict["title"],
                  let startTime = dict["startTime"],
                  let endTime = dict["endTime"],
                  let lessonType = dict["lessonType"] else {
                return nil
            }
            
            return LessonWidget(
                title: title,
                startTime: startTime,
                endTime: endTime,
                lessonType: lessonType
            )
        }
    }
    
    func loadGroupName() -> String {
        return userDefaults?.string(forKey: groupNameKey) ?? "Група"
    }
    
    // MARK: - Clear Data
    func clearAllData() {
        userDefaults?.removeObject(forKey: lessonsKey)
        userDefaults?.removeObject(forKey: groupNameKey)
        userDefaults?.synchronize()
    }
    
    // MARK: - Trigger Widget Update
    func triggerWidgetRefresh() {
        WidgetKit.WidgetCenter.shared.reloadAllTimelines()
    }
}
