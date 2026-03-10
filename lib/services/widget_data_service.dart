import 'package:flutter/services.dart';
import 'package:uni_helper/features/schedule/domain/lesson_model.dart';

class WidgetDataService {
  static const platform = MethodChannel('com.uni_helper/widget');
  
  /// Зберігає дані розкладу на сьогодні для Widget Extension (тільки iOS)
  static Future<void> updateScheduleWidget({
    required List<Lesson> lessons,
    required String groupName,
  }) async {
    try {
      final lessonsList = lessons.map((lesson) {
        final startHour = lesson.startTime.hour.toString().padLeft(2, '0');
        final startMinute = lesson.startTime.minute.toString().padLeft(2, '0');
        final endHour = lesson.endTime.hour.toString().padLeft(2, '0');
        final endMinute = lesson.endTime.minute.toString().padLeft(2, '0');
        
        return {
          'title': lesson.title,
          'startTime': '$startHour:$startMinute',
          'endTime': '$endHour:$endMinute',
          'lessonType': lesson.type.toString().split('.').last,
        };
      }).toList();

      await platform.invokeMethod<void>(
        'updateWidget',
        {
          'lessons': lessonsList,
          'groupName': groupName,
        },
      );
    } on PlatformException catch (e) {
      print('Помилка при оновленні Widget: ${e.message}');
    }
  }

  /// Очищує дані Widget
  static Future<void> clearWidgetData() async {
    try {
      await platform.invokeMethod<void>('clearWidget');
    } on PlatformException catch (e) {
      print('Помилка при очищенні Widget: ${e.message}');
    }
  }
}
