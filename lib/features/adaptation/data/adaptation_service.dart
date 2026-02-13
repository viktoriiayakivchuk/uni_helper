import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/adaptation_model.dart';

class AdaptationService {
  static const String _tasksPath = 'assets/data/adaptation_tasks.json';

  // Завантаження завдань з JSON та поєднання з локальним прогресом
  Future<List<AdaptationCategory>> loadAdaptationPlan() async {
    final String response = await rootBundle.loadString(_tasksPath);
    final data = json.decode(response);
    final List categoriesJson = data['categories'];

    final prefs = await SharedPreferences.getInstance();
    List<AdaptationCategory> categories = [];

    for (var catJson in categoriesJson) {
      List<AdaptationTask> tasks = [];
      for (var taskJson in catJson['tasks']) {
        final task = AdaptationTask.fromJson(taskJson);
        // Зчитуємо збережений стан: якщо порожньо — false [cite: 70]
        task.isCompleted = prefs.getBool(task.id) ?? false;
        tasks.add(task);
      }
      categories.add(AdaptationCategory(title: catJson['title'], tasks: tasks));
    }
    return categories;
  }

  // Збереження стану чекбоксу [cite: 70, 92]
  Future<void> updateTaskStatus(String taskId, bool isCompleted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(taskId, isCompleted);
  }
}
