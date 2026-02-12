import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/lesson_model.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap; // Отримуємо функцію натискання

  const LessonCard({
    super.key, 
    required this.lesson,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('HH:mm');
    Color typeColor;

    switch (lesson.type) {
      case LessonType.lecture: typeColor = Colors.blueAccent; break;
      case LessonType.practice: typeColor = Colors.orangeAccent; break;
      case LessonType.exam: typeColor = Colors.redAccent; break;
      default: typeColor = const Color(0xFF2D5A40);
    }

    // ВАЖЛИВО: Обгортаємо Container у GestureDetector
    return GestureDetector(
      onTap: onTap, // Передаємо сюди функцію
      behavior: HitTestBehavior.opaque, // Щоб реагувало на натискання по всій площі
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.white.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(dateFormat.format(lesson.startTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  height: 30,
                  width: 4,
                  decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(2)),
                ),
                Text(dateFormat.format(lesson.endTime), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 5),
                  if (lesson.description.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.sticky_note_2_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(child: Text(lesson.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
                      ],
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]), 
          ],
        ),
      ),
    );
  }
}