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
    @Environment(\.widgetFamily) var family
    var entry: ScheduleProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    var entry: ScheduleProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Компактний заголовок
            HStack {
                Text(entry.groupName)
                    .font(.system(.subheadline, design: .default))
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text("\(entry.lessons.count)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            if entry.lessons.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        Text("Вільний день")
                            .font(.system(.caption2))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                // Показуємо пари компактно — тільки час і коротка назва
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(0..<min(entry.lessons.count, 4), id: \.self) { index in
                        SmallLessonRow(lesson: entry.lessons[index])
                    }
                    if entry.lessons.count > 4 {
                        Text("+\(entry.lessons.count - 4) ще")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(12)
    }
}

struct SmallLessonRow: View {
    let lesson: LessonWidget
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(lessonColor(lesson.lessonType))
                .frame(width: 4, height: 4)
            Text(lesson.startTime)
                .font(.system(size: 10, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            Text(lesson.title)
                .font(.system(size: 10))
                .lineLimit(1)
        }
    }
    
    private func lessonColor(_ type: String) -> Color {
        switch type {
        case "lecture": return .orange
        case "practice": return .green
        case "lab": return .purple
        case "exam": return .red
        default: return .gray
        }
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    var entry: ScheduleProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Заголовок
            HStack(alignment: .center) {
                Text(entry.groupName)
                    .font(.system(.headline, design: .default))
                    .fontWeight(.bold)
                    .lineLimit(1)
                Spacer()
                Label("\(entry.lessons.count) пар", systemImage: "book")
                    .font(.system(.caption, design: .default))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Divider()
            
            if entry.lessons.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        Text("Сьогодні пар немає")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            } else {
                // 2 колонки по парах для ефективного використання простору
                let maxVisible = min(entry.lessons.count, 4)
                let half = (maxVisible + 1) / 2
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(0..<half, id: \.self) { i in
                            MediumLessonRow(lesson: entry.lessons[i])
                        }
                    }
                    if maxVisible > half {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(half..<maxVisible, id: \.self) { i in
                                MediumLessonRow(lesson: entry.lessons[i])
                            }
                        }
                    }
                }
                if entry.lessons.count > 4 {
                    Text("+ ще \(entry.lessons.count - 4)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
    }
}

struct MediumLessonRow: View {
    let lesson: LessonWidget
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(lessonColor(lesson.lessonType))
                .frame(width: 3, height: 28)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(lesson.title)
                    .font(.system(size: 11))
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text("\(lesson.startTime)–\(lesson.endTime)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func lessonColor(_ type: String) -> Color {
        switch type {
        case "lecture": return .orange
        case "practice": return .green
        case "lab": return .purple
        case "exam": return .red
        default: return .gray
        }
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    var entry: ScheduleProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Розклад на сьогодні")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.secondary)
                    Text(entry.groupName)
                        .font(.system(.title3, design: .default))
                        .fontWeight(.bold)
                }
                Spacer()
                Text("\(entry.lessons.count)")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("пар")
                    .font(.system(.caption))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if entry.lessons.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 36))
                            .foregroundColor(.green)
                        Text("Сьогодні пар немає")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                // Всі пари з повною інформацією
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(0..<min(entry.lessons.count, 8), id: \.self) { index in
                        LargeLessonRow(lesson: entry.lessons[index])
                        if index < min(entry.lessons.count, 8) - 1 {
                            Divider().opacity(0.3)
                        }
                    }
                    if entry.lessons.count > 8 {
                        Text("+ ще \(entry.lessons.count - 8)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
    }
}

struct LargeLessonRow: View {
    let lesson: LessonWidget
    
    var body: some View {
        HStack(spacing: 10) {
            // Кольорова смужка
            RoundedRectangle(cornerRadius: 2)
                .fill(lessonColor(lesson.lessonType))
                .frame(width: 4, height: 32)
            
            // Час
            VStack(spacing: 0) {
                Text(lesson.startTime)
                    .font(.system(size: 12, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                Text(lesson.endTime)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
            
            // Назва і тип
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title)
                    .font(.system(.subheadline))
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(lessonTypeLabel(lesson.lessonType))
                    .font(.system(.caption2))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func lessonColor(_ type: String) -> Color {
        switch type {
        case "lecture": return .orange
        case "practice": return .green
        case "lab": return .purple
        case "exam": return .red
        default: return .gray
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
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
