import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/lesson_model.dart';
import '../widgets/lesson_card.dart';
import '../../data/schedule_repository.dart'; 

// ВИПРАВЛЕНО: Використовуємо прямий шлях через package. 
import 'package:uni_helper/features/glossary/data/pnu_event_repository.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/notification_service.dart';
import 'package:flutter/services.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final CalendarFormat _calendarFormat = CalendarFormat.week; 
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Lesson>> _events = {};

  String? _userGroup; 
  bool _isLoading = false;
  final TextEditingController _groupController = TextEditingController();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();
  final PnuEventRepository _pnuEventRepository = PnuEventRepository(); 

  Set<int> _activeReminders = {};
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadReminders(); 
    _checkUserGroup(); 
  }

  // --- ЛОГІКА НАГАДУВАНЬ ---
  Future<void> _setReminderTime(Lesson lesson, int notifId, int minutes) async {
    final reminderTime = lesson.startTime.subtract(Duration(minutes: minutes));
    
    if (reminderTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ця подія вже почалась!'))
      );
      return;
    }

    final String notifTitle = lesson.isUserCreated 
        ? 'Нагадування: ${lesson.title}' 
        : 'Скоро пара: ${lesson.title}';

    final String startTimeStr = DateFormat('HH:mm').format(lesson.startTime);
    final String notifBody = 'Почнеться через $minutes хв (о $startTimeStr)';

    await NotificationService().requestPermissions();
    await NotificationService().scheduleLessonReminder(
      id: notifId, 
      title: notifTitle, 
      body: notifBody, 
      scheduledTime: reminderTime
    );
    
    setState(() => _activeReminders.add(notifId));
    _saveReminders();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Нагадаємо о ${DateFormat('HH:mm').format(reminderTime)}'),
        backgroundColor: const Color(0xFF2D5A40),
      )
    );
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('active_reminders');
    if (saved != null) {
      setState(() => _activeReminders = saved.map(int.parse).toSet());
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('active_reminders', _activeReminders.map((e) => e.toString()).toList());
  }

  Future<void> _checkUserGroup() async {
    String? groupToLoad;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()!.containsKey('group')) {
          groupToLoad = doc.data()!['group'];
        }
      }
    } catch (e) {
      debugPrint("Помилка Firebase: $e");
    }

    if (groupToLoad == null || groupToLoad.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      groupToLoad = prefs.getString('saved_group');
    }

    if (groupToLoad != null && groupToLoad.isNotEmpty) {
      setState(() {
        _userGroup = groupToLoad;
        _groupController.text = groupToLoad!; 
      });
      await _loginWithGroup(groupToLoad); 
    }
  }

  Future<void> _loginWithGroup(String groupId) async {
    if (groupId.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final serverLessons = await _scheduleRepository.fetchSchedule(groupId);
      final pnuEvents = await _pnuEventRepository.fetchPnuEvents();

      final prefs = await SharedPreferences.getInstance();
      List<Lesson> myUserEvents = [];
      final String? savedData = prefs.getString('user_schedule_data');
      if (savedData != null) {
        final Map<String, dynamic> decodedData = json.decode(savedData);
        decodedData.forEach((dateStr, lessonsList) {
          final list = (lessonsList as List).map((l) => Lesson.fromMap(l)).toList();
          myUserEvents.addAll(list.where((l) => l.isUserCreated));
        });
      }

      await prefs.setString('saved_group', groupId);

      Map<DateTime, List<Lesson>> newEvents = {};
      void addToMap(Lesson lesson) {
        final dateKey = DateTime(lesson.startTime.year, lesson.startTime.month, lesson.startTime.day);
        newEvents.putIfAbsent(dateKey, () => []).add(lesson);
      }

      for (var lesson in serverLessons) { addToMap(lesson); }
      for (var event in pnuEvents) { addToMap(event); }
      for (var lesson in myUserEvents) { addToMap(lesson); }

      newEvents.forEach((key, list) => list.sort((a, b) => a.startTime.compareTo(b.startTime)));

      if (!mounted) return;
      setState(() {
        _userGroup = groupId;
        _events = newEvents;
      });
      await _saveEvents(); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Розклад та новини ПНУ оновлено!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logoutGroup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_group');
    setState(() {
      _userGroup = null;
      _events = {}; 
      _groupController.clear();
    });
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> exportData = {};
    _events.forEach((date, lessons) {
      exportData[date.toIso8601String()] = lessons.map((l) => l.toMap()).toList();
    });
    await prefs.setString('user_schedule_data', json.encode(exportData));
  }

  // --- МЕТОД ФІЛЬТРАЦІЇ ---
  List<Lesson> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final allEvents = _events[normalizedDay] ?? [];
    
    // ВИПРАВЛЕНО: Відфільтровуємо новини (ті, що мають префікс 'news_')
    // Тепер у розкладі будуть лише пари та власні записи.
    return allEvents.where((event) => !event.id.startsWith("news_")).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_userGroup == null) return _buildLoginScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text("Мій розклад", style: TextStyle(color: Colors.black87, fontSize: 14)),
            Text("Шифр: $_userGroup", style: const TextStyle(color: Color(0xFF2D5A40), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logoutGroup,
          )
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 10),
          Expanded(child: _buildEventList()),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 105.0),
        child: FloatingActionButton(
          onPressed: () => _showAddEventDialog(),
          backgroundColor: const Color(0xFF2D5A40),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_rounded, size: 80, color: Color(0xFF2D5A40)),
            const SizedBox(height: 30),
            const Text("Вітаємо в Uni Helper!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
            const SizedBox(height: 40),
            TextField(
              controller: _groupController,
              decoration: InputDecoration(
                labelText: "Назва групи",
                hintText: "Наприклад: ІПЗ-33",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _loginWithGroup(_groupController.text.trim()),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Отримати розклад", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [BoxShadow(color: const Color(0xFF2D5A40).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: TableCalendar<Lesson>(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        eventLoader: _getEventsForDay,
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(color: Color(0xFF2D5A40), shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return const Center(child: Text("На цей день справ немає"));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final lesson = events[index];
        return LessonCard(
          lesson: lesson,
          onTap: () => _showEventDetails(lesson),
          hasReminder: _activeReminders.contains(lesson.id.hashCode),
          onReminderToggle: () async {
            int id = lesson.id.hashCode;
            if (_activeReminders.contains(id)) {
              await NotificationService().cancelReminder(id);
              setState(() => _activeReminders.remove(id));
            } else {
              await _setReminderTime(lesson, id, 10);
            }
          },
        );
      },
    );
  }

  void _showEventDetails(Lesson lesson) {
    final RegExp urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlRegExp.firstMatch(lesson.description);
    final String? extractedUrl = match?.group(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(lesson.title, style: const TextStyle(color: Color(0xFF2D5A40))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Час: ${DateFormat('HH:mm').format(lesson.startTime)}"),
            const SizedBox(height: 10),
            SelectableText(lesson.description),
            if (extractedUrl != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: extractedUrl));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text("Копіювати посилання"),
              )
            ]
          ],
        ),
        actions: [
          if (lesson.isUserCreated) TextButton(onPressed: () { _deleteEvent(lesson); Navigator.pop(context); }, child: const Text("Видалити", style: TextStyle(color: Colors.red))),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Закрити")),
        ],
      ),
    );
  }

  void _showAddEventDialog({Lesson? eventToEdit}) { /* Логіка */ }
  void _deleteEvent(Lesson lesson, {bool save = true}) {
    final dateKey = DateTime(lesson.startTime.year, lesson.startTime.month, lesson.startTime.day);
    setState(() {
      _events[dateKey]?.removeWhere((l) => l.id == lesson.id);
      if (save) _saveEvents();
    });
  }
}