enum LessonType { lecture, practice, lab, exam, custom }

class Lesson {
  final String id;
  final String title;      // Назва предмету
  final String description;// Викладач або аудиторія
  final DateTime startTime;
  final DateTime endTime;
  final LessonType type;
  final bool isCustom;     // Чи це власна подія студента

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isCustom = false,
  });
}