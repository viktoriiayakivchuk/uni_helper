import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/lesson_model.dart';
import '../widgets/lesson_card.dart';
import '../../data/schedule_repository.dart'; 
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
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Lesson>> _events = {};

  String? _userGroup; 
  bool _isLoading = false;
  final TextEditingController _groupController = TextEditingController();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  Set<int> _activeReminders = {};
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadReminders(); 
    
    // ДОДАНО: Спочатку завантажуємо кеш, потім перевіряємо групу і оновлюємо з інтернету
    _loadEvents().then((_) {
      _checkUserGroup(); 
    });
  }

  Future<void> _setReminderTime(Lesson lesson, int notifId, int minutes) async {
    final reminderTime = lesson.startTime.subtract(Duration(minutes: minutes));
    
    if (reminderTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ця подія вже почалась або до її початку залишилось менше 10хв!'))
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Нагадаємо о ${DateFormat('HH:mm').format(reminderTime)}', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2D5A40),
        duration: const Duration(seconds: 2),
      )
    );
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? saved = prefs.getStringList('active_reminders');
    if (saved != null) {
      setState(() {
        _activeReminders = saved.map(int.parse).toSet();
      });
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
          final String? dbGroup = doc.data()!['group'];
          if (dbGroup != null && dbGroup.trim().isNotEmpty) {
            groupToLoad = dbGroup;
            print("✅ Групу підтягнуто з Firebase: $groupToLoad");
          }
        }
      }
    } catch (e) {
      print("Помилка отримання групи з Firebase: $e");
    }

    if (groupToLoad == null || groupToLoad.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      groupToLoad = prefs.getString('saved_group');
      if (groupToLoad != null) {
        print("📁 Групу підтягнуто з локального кешу: $groupToLoad");
      }
    }

    if (groupToLoad != null && groupToLoad.isNotEmpty) {
      setState(() {
        _userGroup = groupToLoad;
        _groupController.text = groupToLoad!; 
      });
      
      await _loginWithGroup(groupToLoad!); 
    }
  }

  Future<void> _loginWithGroup(String groupId) async {
    if (groupId.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final serverLessons = await _scheduleRepository.fetchSchedule(groupId);
      
      if (serverLessons.isEmpty) {
        throw Exception("Пар не знайдено. Перевірте шифр групи (напр. ІПЗ -33)");
      }

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
        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(lesson);
      }

      for (var lesson in serverLessons) {
        addToMap(lesson);
      }

      for (var lesson in myUserEvents) {
        addToMap(lesson);
      }

      newEvents.forEach((key, list) {
        list.sort((a, b) => a.startTime.compareTo(b.startTime));
      });

      setState(() {
        _userGroup = groupId;
        _events = newEvents;
      });
      
      await _saveEvents(); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Розклад оновлено! Ваші події (${myUserEvents.length}) збережено.')),
      );
      
    } catch (e) {
      // ДОДАНО: Дружнє повідомлення, якщо немає інтернету, але є завантажений кеш
      final errorStr = e.toString();
      final isOffline = errorStr.contains('SocketException') || errorStr.contains('Failed host lookup') || errorStr.contains('ClientException');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline && _events.isNotEmpty 
              ? 'Немає інтернету. Працюємо в офлайн-режимі 📱'
              : 'Помилка: ${errorStr.replaceAll('Exception: ', '')}'
          ),
          backgroundColor: isOffline && _events.isNotEmpty ? Colors.orange[800] : Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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

  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString('user_schedule_data');
      if (savedData != null) {
        final Map<String, dynamic> decodedData = json.decode(savedData);
        Map<DateTime, List<Lesson>> loadedEvents = {};
        decodedData.forEach((dateStr, lessonsList) {
          final date = DateTime.parse(dateStr);
          loadedEvents[date] = (lessonsList as List).map((l) => Lesson.fromMap(l)).toList();
        });
        setState(() => _events = loadedEvents);
      }
    } catch (e) {
      debugPrint("Помилка завантаження кешу: $e");
    }
  }

  List<Lesson> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (_userGroup == null) {
      return _buildLoginScreen();
    }

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
            tooltip: "Вийти (Змінити групу)",
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5A40).withOpacity(0.1),
                shape: BoxShape.circle
              ),
              child: const Icon(Icons.school_rounded, size: 60, color: Color(0xFF2D5A40)),
            ),
            const SizedBox(height: 30),
            const Text(
              "Вітаємо в Uni Helper!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
            ),
            const SizedBox(height: 15),
            Text(
              "Введіть шифр вашої групи, щоб завантажити розклад.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            
            TextField(
              controller: _groupController,
              keyboardType: TextInputType.text, 
              decoration: InputDecoration(
                labelText: "Назва групи",       
                hintText: "Наприклад: ІПЗ-33", 
                helperText: "Введіть точну назву групи як на сайті (з пробілами)",
                // ...
              ),
            ),
            
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  _loginWithGroup(_groupController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Отримати розклад", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) setState(() => _calendarFormat = format);
        },
        eventLoader: _getEventsForDay,
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((_) { 
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 5, height: 5,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.orangeAccent),
                  );
                }).toList(),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(color: Color(0xFF2D5A40), shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: const Color(0xFF2D5A40).withOpacity(0.4), shape: BoxShape.circle),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.weekend_rounded, size: 60, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 10),
            Text("На цей день справ немає", style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final lesson = events[index];
        final int notifId = lesson.id.hashCode;
        final bool isReminderActive = _activeReminders.contains(notifId);

        return LessonCard(
          lesson: lesson,
          onTap: () => _showEventDetails(lesson),
          hasReminder: isReminderActive,
          
          onReminderToggle: () async {
            if (isReminderActive) {
              await NotificationService().cancelReminder(notifId);
              setState(() => _activeReminders.remove(notifId));
              _saveReminders();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Нагадування скасовано', style: TextStyle(color: Colors.white)), backgroundColor: Colors.black87, duration: Duration(seconds: 1))
              );
            } else {
              await _setReminderTime(lesson, notifId, 10);
            }
          },

          onReminderLongPress: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (sheetContext) {
                return Container(
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('За скільки часу нагадати?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
                      const SizedBox(height: 10),
                      ...[5, 10, 30, 60].map((minutes) => ListTile(
                        leading: const Icon(Icons.timer_outlined, color: Color(0xFF2D5A40)),
                        title: Text('$minutes ${minutes == 60 ? "хвилин (1 година)" : "хвилин"}', style: const TextStyle(fontSize: 16)),
                        onTap: () async {
                          Navigator.pop(sheetContext); 

                          if (isReminderActive) {
                             await NotificationService().cancelReminder(notifId);
                          }
                          await _setReminderTime(lesson, notifId, minutes);
                        },
                      )).toList(),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  void _showEventDetails(Lesson lesson) {
    // 1. Шукаємо посилання в описі за допомогою регулярного виразу
    final RegExp urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlRegExp.firstMatch(lesson.description);
    final String? extractedUrl = match?.group(0);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
                const SizedBox(height: 15),
                Row(children: [const Icon(Icons.access_time_rounded, color: Colors.orangeAccent), const SizedBox(width: 10), Text("${DateFormat('HH:mm').format(lesson.startTime)} - ${DateFormat('HH:mm').format(lesson.endTime)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))]),
                const SizedBox(height: 10),
                
                // 2. Змінено: Text -> SelectableText (тепер текст можна затиснути і виділити)
                if (lesson.description.isNotEmpty) 
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      const Icon(Icons.notes_rounded, color: Colors.grey), 
                      const SizedBox(width: 10), 
                      Expanded(
                        child: SelectableText(
                          lesson.description, 
                          style: const TextStyle(fontSize: 16, color: Colors.black87)
                        )
                      )
                    ]
                  ),
                
                // 3. Додано: Якщо є посилання, з'являється зручна кнопка
                if (extractedUrl != null) ...[
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: extractedUrl));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔗 Посилання скопійовано!'),
                              backgroundColor: Color(0xFF2D5A40),
                              duration: Duration(seconds: 2),
                            )
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: const Text("Скопіювати посилання", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        foregroundColor: Colors.blueAccent,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                ],

                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 10),
                
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton.icon(
                      onPressed: () { 
                        _deleteEvent(lesson); 
                        Navigator.pop(context); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Видалено'))); 
                      }, 
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                      label: const Text("Видалити", style: TextStyle(color: Colors.redAccent))
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () { 
                        Navigator.pop(context); 
                        _showAddEventDialog(eventToEdit: lesson); 
                      }, 
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A40), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                      icon: const Icon(Icons.edit_outlined, size: 18), 
                      label: const Text("Змінити")
                    ),
                ])
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog({Lesson? eventToEdit}) {
    final titleController = TextEditingController(text: eventToEdit?.title ?? "");
    final descController = TextEditingController(text: eventToEdit?.description ?? "");
    
    TimeOfDay selectedStartTime = eventToEdit != null ? TimeOfDay.fromDateTime(eventToEdit.startTime) : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay selectedEndTime = eventToEdit != null ? TimeOfDay.fromDateTime(eventToEdit.endTime) : const TimeOfDay(hour: 10, minute: 0);
    LessonType selectedType = eventToEdit?.type ?? LessonType.practice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 25, left: 20, right: 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(eventToEdit == null ? "Нова справа" : "Редагування", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
              const SizedBox(height: 20),
              TextField(controller: titleController, decoration: InputDecoration(labelText: "Що плануєте? *", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey[50])),
              const SizedBox(height: 15),
              TextField(
                controller: descController,
                maxLines: 5,        
                minLines: 3,        
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: "Нотатки", 
                  alignLabelWithHint: true, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), 
                  filled: true, 
                  fillColor: Colors.grey[50]
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async { 
                        final time = await showTimePicker(
                          context: context, 
                          initialTime: selectedStartTime,
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
                        ); 
                        if (time != null) setModalState(() => selectedStartTime = time); 
                      }, 
                      icon: const Icon(Icons.access_time), 
                      label: Text('${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}'),
                    )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async { 
                        final time = await showTimePicker(
                          context: context, 
                          initialTime: selectedEndTime,
                          builder: (BuildContext context, Widget? child) {
                            return MediaQuery(
                              data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                              child: child!,
                            );
                          },
                        ); 
                        if (time != null) setModalState(() => selectedEndTime = time); 
                      }, 
                      icon: const Icon(Icons.access_time_filled), 
                      label: Text('${selectedEndTime.hour.toString().padLeft(2, '0')}:${selectedEndTime.minute.toString().padLeft(2, '0')}'),
                    )
                  ),
                ]
              ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    if (eventToEdit != null) _deleteEvent(eventToEdit, save: false);
                    _addNewEvent(titleController.text, descController.text, selectedStartTime, selectedEndTime, selectedType);
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A40), minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: Text(eventToEdit == null ? "Додати" : "Зберегти", style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewEvent(String title, String desc, TimeOfDay start, TimeOfDay end, LessonType type) {
    if (_selectedDay == null) return;
    
    final normalizedDay = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    
    final newLesson = Lesson(
      id: DateTime.now().toString(),
      title: title,
      description: desc,
      startTime: DateTime(normalizedDay.year, normalizedDay.month, normalizedDay.day, start.hour, start.minute),
      endTime: DateTime(normalizedDay.year, normalizedDay.month, normalizedDay.day, end.hour, end.minute),
      type: type,
      isUserCreated: true, 
    );

    setState(() {
      if (_events[normalizedDay] != null) { 
        _events[normalizedDay]!.add(newLesson); 
      } else { 
        _events[normalizedDay] = [newLesson]; 
      }
      _events[normalizedDay]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    
    _saveEvents();
  }

  void _deleteEvent(Lesson lesson, {bool save = true}) {
    final dateKey = DateTime(lesson.startTime.year, lesson.startTime.month, lesson.startTime.day);
    
    final int notificationId = lesson.id.hashCode;
    if (_activeReminders.contains(notificationId)) {
      NotificationService().cancelReminder(notificationId);
      _activeReminders.remove(notificationId);
      _saveReminders();
    }

    setState(() {
      _events[dateKey]?.removeWhere((l) => l.id == lesson.id);
      if (save) _saveEvents();
    });
  }
}