import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/lesson_model.dart';
import '../widgets/lesson_card.dart';
import '../../data/schedule_repository.dart'; 
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

  List<Lesson> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final allEvents = _events[normalizedDay] ?? [];
    return allEvents.where((event) {
      return !event.id.startsWith("news_") && !event.id.startsWith("anon_");
    }).toList();
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
        boxShadow: [BoxShadow(color: const Color(0xFF2D5A40).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
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
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(color: Color(0xFF2D5A40), shape: BoxShape.circle),
          todayDecoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
          // ВИПРАВЛЕННЯ: Повертаємо оранжеві точки під датами
          markerDecoration: const BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
          markersMaxCount: 3,
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

  // --- СУЧАСНЕ ВІКНО ДЕТАЛЕЙ ---

  void _showEventDetails(Lesson lesson) {
    final RegExp urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlRegExp.firstMatch(lesson.description);
    final String? extractedUrl = match?.group(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.title,
              style: const TextStyle(
                color: Color(0xFF2D5A40),
                fontWeight: FontWeight.bold,
                fontSize: 22,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5A40).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2D5A40).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF2D5A40)),
                  const SizedBox(width: 8),
                  Text(
                    "${DateFormat('HH:mm').format(lesson.startTime)} — ${DateFormat('HH:mm').format(lesson.endTime)}",
                    style: const TextStyle(
                      color: Color(0xFF2D5A40),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32),
            const Text(
              "ДЕТАЛІ",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  lesson.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              if (lesson.isUserCreated)
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    _deleteEvent(lesson);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Закрити", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              if (extractedUrl != null) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5A40),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: extractedUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Посилання скопійовано!'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text("Копіювати", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- ЛОГІКА ДОДАВАННЯ ТА ІНШЕ ---

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(hour: (startTime.hour + 1) % 24, minute: startTime.minute);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Додати подію", style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController, 
                  decoration: InputDecoration(
                    labelText: "Назва",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController, 
                  decoration: InputDecoration(
                    labelText: "Опис",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: Color(0xFF2D5A40)),
                  title: Text("Початок: ${startTime.format(context)}"),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: startTime);
                    if (time != null) setDialogState(() => startTime = time);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_filled, color: Colors.orangeAccent),
                  title: Text("Кінець: ${endTime.format(context)}"),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: endTime);
                    if (time != null) setDialogState(() => endTime = time);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Скасувати")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (titleController.text.isEmpty) return;
                final now = _selectedDay ?? DateTime.now();
                final startDT = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
                final endDT = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
                
                if (endDT.isBefore(startDT)) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Кінець не може бути раніше початку!')));
                   return;
                }

                _addNewEvent(Lesson(
                  id: "user_${DateTime.now().millisecondsSinceEpoch}", 
                  title: titleController.text,
                  description: descController.text,
                  startTime: startDT,
                  endTime: endDT,
                  type: LessonType.practice,
                  isUserCreated: true,
                ));
                Navigator.pop(context);
              },
              child: const Text("Зберегти", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewEvent(Lesson lesson) {
    final dateKey = DateTime(lesson.startTime.year, lesson.startTime.month, lesson.startTime.day);
    setState(() {
      _events.putIfAbsent(dateKey, () => []).add(lesson);
      _events[dateKey]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    _saveEvents(); 
  }

  void _deleteEvent(Lesson lesson, {bool save = true}) {
    final dateKey = DateTime(lesson.startTime.year, lesson.startTime.month, lesson.startTime.day);
    setState(() {
      _events[dateKey]?.removeWhere((l) => l.id == lesson.id);
      if (save) _saveEvents();
    });
  }
}