import WidgetKit
import SwiftUI

// MARK: - Data Models
struct ScheduleEntry: TimelineEntry {
    let date: Date
    let lessons: [LessonWidget]
    let groupName: String
}

struct LessonWidget: Codable {
    let title: String
    let startTime: String
    let endTime: String
    let lessonType: String
}

// MARK: - Timeline Provider
struct ScheduleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            lessons: [
                LessonWidget(title: "Математика", startTime: "09:00", endTime: "10:30", lessonType: "lecture"),
                LessonWidget(title: "Програмування", startTime: "10:45", endTime: "12:15", lessonType: "practice")
            ],
            groupName: "ІМ-31"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let lessons = ScheduleDataManager.shared.loadTodayLessons()
        let groupName = ScheduleDataManager.shared.loadGroupName()
        
        let entry = ScheduleEntry(
            date: Date(),
            lessons: lessons,
            groupName: groupName
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        var entries: [ScheduleEntry] = []
        let lessons = ScheduleDataManager.shared.loadTodayLessons()
        let groupName = ScheduleDataManager.shared.loadGroupName()

        let currentDate = Date()
        let entry = ScheduleEntry(
            date: currentDate,
            lessons: lessons,
            groupName: groupName
        )
        entries.append(entry)

        // ОновлюватиWidget кожних 15 хвилин
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View
struct ScheduleWidgetEntryView: View {
    var entry: ScheduleProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок з групою
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Розклад")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.gray)
                    Text(entry.groupName)
                        .font(.system(.headline, design: .default))
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Пар: \(entry.lessons.count)")
                        .font(.system(.caption, design: .default))
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            Divider()
            
            // Список пар
            if entry.lessons.isEmpty {
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("Немає пар")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<min(entry.lessons.count, 3), id: \.self) { index in
                        LessonRowView(lesson: entry.lessons[index])
                    }
                    
                    if entry.lessons.count > 3 {
                        Text("+ ще \(entry.lessons.count - 3)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Row View for Lessons
struct LessonRowView: View {
    let lesson: LessonWidget

    var body: some View {
        HStack(spacing: 8) {
            // Час
            VStack(alignment: .center, spacing: 0) {
                Text(lesson.startTime)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Text("-")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.gray)
                Text(lesson.endTime)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .frame(width: 50)

            // Назва пари
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .font(.system(.caption, design: .default))
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: lessonTypeIcon(lesson.lessonType))
                        .font(.system(size: 10))
                    Text(lessonTypeLabel(lesson.lessonType))
                        .font(.system(.caption2, design: .default))
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func lessonTypeIcon(_ type: String) -> String {
        switch type {
        case "lecture": return "book.fill"
        case "practice": return "pencil.circle.fill"
        case "lab": return "flask.fill"
        case "exam": return "checkmark.circle.fill"
        default: return "circle.fill"
        }
    }
    
    private func lessonTypeLabel(_ type: String) -> String {
        switch type {
        case "lecture": return "Лекція"
        case "practice": return "Практика"
        case "lab": return "Лабораторна"
        case "exam": return "Екзамен"
        default: return type
        }
    }
}

// MARK: - Widget Definition
@main
struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: ScheduleProvider()
        ) { entry in
            ScheduleWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Розклад пар")
        .description("Показує розклад на сьогодні")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOSApplicationExtension 17.0, *)
#Preview(as: .systemMedium) {
    ScheduleWidget()
} timeline: {
    ScheduleEntry(
        date: .now,
        lessons: [
            LessonWidget(title: "Математика", startTime: "09:00", endTime: "10:30", lessonType: "lecture"),
            LessonWidget(title: "Програмування", startTime: "10:45", endTime: "12:15", lessonType: "practice"),
            LessonWidget(title: "Англійська", startTime: "13:00", endTime: "14:30", lessonType: "practice")
        ],
        groupName: "ІМ-31"
    )
}
