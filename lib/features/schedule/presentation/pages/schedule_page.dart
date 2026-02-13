import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/lesson_model.dart';
import '../widgets/lesson_card.dart';
import '../../data/schedule_repository.dart'; 

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // Налаштування календаря
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Lesson>> _events = {};

  // Змінні для роботи з групою
  String? _userGroup; 
  bool _isLoading = false;
  final TextEditingController _groupController = TextEditingController();
  final ScheduleRepository _scheduleRepository = ScheduleRepository();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _checkUserGroup(); // Перевіряємо при старті, чи є група
  }

  // --- ЛОГІКА АВТОРИЗАЦІЇ ---
  Future<void> _checkUserGroup() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userGroup = prefs.getString('saved_group');
    });

    if (_userGroup != null) {
      _loadEvents(); // Група є -> вантажимо події
    }
  }

Future<void> _loginWithGroup(String groupId) async {
    if (groupId.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      // 1. Отримуємо НОВИЙ розклад з сервера
      final serverLessons = await _scheduleRepository.fetchSchedule(groupId);
      
      if (serverLessons.isEmpty) {
        throw Exception("Пар не знайдено. Перевірте ID групи (напр. -4636)");
      }

      final prefs = await SharedPreferences.getInstance();

      // 2. Зчитуємо СТАРІ збережені дані з пам'яті телефону
      // Це потрібно, бо змінна _events зараз порожня (ми ж вийшли з акаунту)
      List<Lesson> myUserEvents = [];
      final String? savedData = prefs.getString('user_schedule_data');
      
      if (savedData != null) {
        final Map<String, dynamic> decodedData = json.decode(savedData);
        decodedData.forEach((dateStr, lessonsList) {
          final list = (lessonsList as List).map((l) => Lesson.fromMap(l)).toList();
          // Витягуємо тільки ті події, які створив користувач (isUserCreated == true)
          myUserEvents.addAll(list.where((l) => l.isUserCreated));
        });
      }

      // 3. Зберігаємо нову групу
      await prefs.setString('saved_group', groupId);

      // 4. Об'єднуємо: Пари університету + Ваші події
      Map<DateTime, List<Lesson>> newEvents = {};
      
      void addToMap(Lesson lesson) {
        // Нормалізація дати (прибираємо час)
        final dateKey = DateTime(lesson.startTime.year, lesson.startTime.month, lesson.startTime.day);
        if (newEvents[dateKey] == null) newEvents[dateKey] = [];
        newEvents[dateKey]!.add(lesson);
      }

      // Спочатку додаємо пари
      for (var lesson in serverLessons) {
        addToMap(lesson);
      }

      // Тепер додаємо ваші збережені події
      for (var lesson in myUserEvents) {
        addToMap(lesson);
      }

      // Сортуємо події в кожному дні за часом
      newEvents.forEach((key, list) {
        list.sort((a, b) => a.startTime.compareTo(b.startTime));
      });

      setState(() {
        _userGroup = groupId;
        _events = newEvents;
      });
      
      // 5. Перезаписуємо файл збереження з об'єднаними даними
      await _saveEvents(); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Розклад оновлено! Ваші події (${myUserEvents.length}) збережено.')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
Future<void> _logoutGroup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_group');
    // await prefs.remove('user_schedule_data'); // <--- ВАЖЛИВО: Закоментуйте цей рядок!
    
    setState(() {
      _userGroup = null;
      _events = {}; 
      _groupController.clear();
    });
  }

  // --- ЛОГІКА ЗБЕРЕЖЕННЯ ---
  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> exportData = {};
    _events.forEach((date, lessons) {
      exportData[date.toIso8601String()] = lessons.map((l) => l.toMap()).toList();
    });
    await prefs.setString('user_schedule_data', json.encode(exportData));
  }

  Future<void> _loadEvents() async {
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
  }

  List<Lesson> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    // ЯКЩО ГРУПИ НЕМАЄ -> ЕКРАН ВХОДУ
    if (_userGroup == null) {
      return _buildLoginScreen();
    }

    // ЯКЩО Є -> КАЛЕНДАР
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text("Мій розклад", style: TextStyle(color: Colors.black87, fontSize: 14)),
            Text("ID: $_userGroup", style: const TextStyle(color: Color(0xFF2D5A40), fontSize: 18, fontWeight: FontWeight.bold)),
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
            
            // Знайдіть TextField контролер _groupController
            TextField(
              controller: _groupController,
              keyboardType: TextInputType.text, // Можна прибрати обмеження, якщо було number
              decoration: InputDecoration(
                labelText: "Назва групи",       // БУЛО: "ID групи"
                hintText: "Наприклад: ІПЗ-33",  // БУЛО: "-4636"
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

  // --- ТУТ ЗАЛИШАЮТЬСЯ ВАШІ МЕТОДИ UI (_buildCalendar, _buildEventList, _showEventDetails, _showAddEventDialog) ---
  // Ті, що ви вже закомітили в попередньому кроці.
  // Просто переконайтеся, що вони тут є.
  
  Widget _buildCalendar() {
     // ... Код календаря з попереднього кроку ...
     // (Я не дублюю його, щоб не забивати відповідь, але він тут має бути)
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
        return LessonCard(
          lesson: events[index],
          onTap: () => _showEventDetails(events[index]),
        );
      },
    );
  }

  void _showEventDetails(Lesson lesson) {
     // ... Код вікна деталей ...
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
                if (lesson.description.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.notes_rounded, color: Colors.grey), const SizedBox(width: 10), Expanded(child: Text(lesson.description, style: const TextStyle(fontSize: 16, color: Colors.black87)))]),
                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton.icon(onPressed: () { _deleteEvent(lesson); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Видалено'))); }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent), label: const Text("Видалити", style: TextStyle(color: Colors.redAccent))),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(onPressed: () { Navigator.pop(context); _showAddEventDialog(eventToEdit: lesson); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5A40), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text("Змінити")),
                ])
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog({Lesson? eventToEdit}) {
     // ... Код вікна редагування ...
     // (Використайте той самий код, що й раніше)
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
              // ... Тут ваш код полів вводу ...
               Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(eventToEdit == null ? "Нова справа" : "Редагування", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
              const SizedBox(height: 20),
              TextField(controller: titleController, decoration: InputDecoration(labelText: "Що плануєте? *", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey[50])),
              const SizedBox(height: 15),
              TextField(controller: descController, decoration: InputDecoration(labelText: "Нотатки", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Colors.grey[50])),
              const SizedBox(height: 20),
              Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () async { final time = await showTimePicker(context: context, initialTime: selectedStartTime); if (time != null) setModalState(() => selectedStartTime = time); }, icon: const Icon(Icons.access_time), label: Text(selectedStartTime.format(context)))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: () async { final time = await showTimePicker(context: context, initialTime: selectedEndTime); if (time != null) setModalState(() => selectedEndTime = time); }, icon: const Icon(Icons.access_time_filled), label: Text(selectedEndTime.format(context)))),
              ]),
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
      isUserCreated: true, // <-- ВАЖЛИВО: Це подія користувача
    );

    setState(() {
      if (_events[normalizedDay] != null) { 
        _events[normalizedDay]!.add(newLesson); 
      } else { 
        _events[normalizedDay] = [newLesson]; 
      }
      // Сортуємо за часом
      _events[normalizedDay]!.sort((a, b) => a.startTime.compareTo(b.startTime));
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