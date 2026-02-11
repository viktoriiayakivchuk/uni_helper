import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/adaptation_service.dart';
import '../../domain/adaptation_model.dart';

class AdaptationPlanPage extends StatefulWidget {
  const AdaptationPlanPage({super.key});

  @override
  State<AdaptationPlanPage> createState() => _AdaptationPlanPageState();
}

class _AdaptationPlanPageState extends State<AdaptationPlanPage> {
  final AdaptationService _service = AdaptationService();
  List<AdaptationCategory> _categories = [];
  double _progress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.loadAdaptationPlan();
    setState(() {
      _categories = data;
      _calculateProgress();
      _isLoading = false;
    });
  }

  void _calculateProgress() {
    int total = 0;
    int completed = 0;
    for (var cat in _categories) {
      total += cat.tasks.length;
      completed += cat.tasks.where((t) => t.isCompleted).length;
    }
    setState(() {
      _progress = total > 0 ? completed / total : 0.0;
    });
  }

  void _toggleTask(AdaptationTask task, bool? value) async {
    final newValue = value ?? false;
    await _service.updateTaskStatus(task.id, newValue);
    setState(() {
      task.isCompleted = newValue;
      _calculateProgress();
    });

    if (_progress == 1.0) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Вітаємо! 🎉",
            style: TextStyle(color: Color(0xFF2D5A40))),
        content: const Text(
            "Ти успішно пройшов усі етапи адаптації. Успіхів у навчанні!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ДЯКУЮ",
                style: TextStyle(
                    color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Мій старт",
            style: TextStyle(
                color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D5A40)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Фоновий градієнт як на MainScreen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF0F4F1), Color(0xFFD9E8DD)],
              ),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2D5A40)))
              : SafeArea(
                  child: Column(
                    children: [
                      _buildProgressCard(), // Картка з прогресом
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            return _buildCategorySection(_categories[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // Картка прогресу (Header)
  Widget _buildProgressCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Твій успіх:",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5A40))),
              Text("${(_progress * 100).toInt()}%",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5A40))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.5),
              color: const Color(0xFF2D5A40),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Виконуй завдання, щоб швидше адаптуватися!",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Секція категорії завдань
  Widget _buildCategorySection(AdaptationCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          child: Text(
            category.title.toUpperCase(),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                letterSpacing: 1.2),
          ),
        ),
        ...category.tasks.map((task) => _buildTaskItem(task)).toList(),
        const SizedBox(height: 10),
      ],
    );
  }

  // Окремий елемент завдання (Task Item)
  Widget _buildTaskItem(AdaptationTask task) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: task.isCompleted
            ? Colors.white.withOpacity(0.6)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: task.isCompleted
                ? const Color(0xFF2D5A40).withOpacity(0.3)
                : Colors.white.withOpacity(0.5)),
      ),
      child: CheckboxListTile(
        activeColor: const Color(0xFF2D5A40),
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        value: task.isCompleted,
        onChanged: (val) => _toggleTask(task, val),
        title: Text(
          task.text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: task.isCompleted ? Colors.black45 : const Color(0xFF2D5A40),
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          task.hint,
          style: TextStyle(
              fontSize: 12,
              color: task.isCompleted ? Colors.black26 : Colors.black54),
        ),
        secondary: Icon(
          task.isCompleted
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: task.isCompleted ? const Color(0xFF2D5A40) : Colors.black38,
        ),
      ),
    );
  }
}
