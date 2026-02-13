import 'dart:convert';

enum LessonType { lecture, practice, lab, exam }

class Lesson {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final LessonType type;
  final bool isUserCreated; // <-- НОВЕ ПОЛЕ

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.isUserCreated = false, // За замовчуванням false (для пар з університету)
  });

  // Перетворюємо в Map для JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.index,
      'isUserCreated': isUserCreated, // <-- Зберігаємо
    };
  }

  // Створюємо об'єкт з Map
  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      type: LessonType.values[map['type']],
      isUserCreated: map['isUserCreated'] ?? false, // <-- Завантажуємо (якщо немає - false)
    );
  }

  String toJson() => json.encode(toMap());
  factory Lesson.fromJson(String source) => Lesson.fromMap(json.decode(source));
}