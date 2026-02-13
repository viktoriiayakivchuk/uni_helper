import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdaptationPlanPage extends StatefulWidget {
  const AdaptationPlanPage({super.key});

  @override
  State<AdaptationPlanPage> createState() => _AdaptationPlanPageState();
}

class _AdaptationPlanPageState extends State<AdaptationPlanPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  Map<String, bool> _completionStatus = {};

  final List<Map<String, dynamic>> _tasks = [
    {
      'id': 'task_1',
      'title': 'Знайти свою групу та познайомитися зі старостою',
      'week': 1
    },
    {
      'id': 'task_2',
      'title': 'Розібратися в розкладі занять (чисельник/знаменник)',
      'week': 1
    },
    {'id': 'task_3', 'title': 'Отримати студентський квиток', 'week': 1},
    {'id': 'task_4', 'title': 'Зареєструватися в системі d-learn', 'week': 2},
    {'id': 'task_5', 'title': 'Налаштувати університетську пошту', 'week': 2},
    {
      'id': 'task_6',
      'title': 'Підписатися на офіційні канали факультету',
      'week': 2
    },
    {'id': 'task_7', 'title': 'Записатися до бібліотеки', 'week': 3},
    {
      'id': 'task_8',
      'title': 'Дізнатися про студентські організації та клуби',
      'week': 3
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    if (_user == null) {
      setState(() {
        _completionStatus = {};
        _isLoading = false;
      });
      return;
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          List<dynamic> completedIds = data['adaptationProgress'] ?? [];
          for (var task in _tasks) {
            _completionStatus[task['id']] = completedIds.contains(task['id']);
          }
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTask(String taskId, bool isChecked) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Увійдіть в акаунт, щоб зберегти прогрес'),
          backgroundColor: Color(0xFF1B3A29),
        ),
      );
      return;
    }

    setState(() {
      _completionStatus[taskId] = isChecked;
    });

    List<String> completedTasks = _completionStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'adaptationProgress': completedTasks,
      }, SetOptions(merge: true));

      if (completedTasks.length == _tasks.length) {
        _showCongratulationDialog();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showCongratulationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Вітаємо! 🎉',
            style: TextStyle(
                color: Color(0xFF1B3A29), fontWeight: FontWeight.bold)),
        content: const Text(
          'Ви успішно пройшли всі етапи адаптації! Тепер ви справжній студент КНУ.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Супер!',
                style: TextStyle(
                    color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (_tasks.isEmpty) return 0.0;
    int completedCount = _completionStatus.values.where((v) => v).length;
    return completedCount / _tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF1B3A29))),
      );
    }

    final double progress = _calculateProgress();
    final Map<int, List<Map<String, dynamic>>> groupedTasks = {};
    for (var task in _tasks) {
      groupedTasks.putIfAbsent(task['week'], () => []).add(task);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Мій старт',
            style: TextStyle(
                color: Color(0xFF1B3A29), fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B3A29)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTipCard(),
            _buildProgressHeader(progress),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: groupedTasks.keys.map((week) {
                  return _buildWeekSection(week, groupedTasks[week]!);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D5A40).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2D5A40).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF1B3A29)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Порада: Не бійся запитувати дорогу у старшокурсників — вони теж колись були на твоєму місці! 😊',
              style: TextStyle(
                  color: const Color(0xFF1B3A29).withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(double progress) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B3A29).withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFF1B3A29).withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ваша адаптація',
                  style: TextStyle(
                      color: Color(0xFF1B3A29),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      color: Color(0xFF1B3A29), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF1B3A29).withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2D5A40)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSection(int week, List<Map<String, dynamic>> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 20, bottom: 12),
          child: Text(
            'ТИЖДЕНЬ $week',
            style: TextStyle(
                color: Colors.black.withOpacity(0.4),
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1.5),
          ),
        ),
        ...tasks.map((task) => _buildTaskCard(task)),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    bool isCompleted = _completionStatus[task['id']] ?? false;

    return GestureDetector(
      onTap: () => _toggleTask(task['id'], !isCompleted),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFF2D5A40).withOpacity(0.05)
              : const Color(0xFF2D5A40).withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isCompleted
                  ? const Color(0xFF2D5A40).withOpacity(0.3)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                task['title'],
                style: TextStyle(
                  color: isCompleted ? Colors.black38 : Colors.black87,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isCompleted ? const Color(0xFF1B3A29) : Colors.transparent,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF1B3A29)
                      : const Color(0xFF1B3A29).withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
