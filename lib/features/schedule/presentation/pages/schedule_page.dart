import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/lesson_model.dart';
import '../widgets/lesson_card.dart';
import 'dart:convert'; // Для 'json'
import 'package:shared_preferences/shared_preferences.dart'; // Для 'SharedPreferences'

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Lesson>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = _getMockEvents(); // Завантаження тестових даних
    _loadEvents(); // Завантажуємо дані при старті
  }

  // --- ЛОГІКА LOCAL STORAGE ---

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    // Перетворюємо Map<DateTime, List<Lesson>> у формат, який розуміє JSON
    Map<String, dynamic> exportData = {};
    _events.forEach((date, lessons) {
      exportData[date.toIso8601String()] = lessons.map((l) => l.toMap()).toList();
    });
    
    await prefs.setString('user_schedule', json.encode(exportData));
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('user_schedule');

    if (savedData != null) {
      final Map<String, dynamic> decodedData = json.decode(savedData);
      Map<DateTime, List<Lesson>> loadedEvents = {};

      decodedData.forEach((dateStr, lessonsList) {
        final date = DateTime.parse(dateStr);
        final lessons = (lessonsList as List).map((l) => Lesson.fromMap(l)).toList();
        loadedEvents[date] = lessons;
      });

      setState(() {
        _events = loadedEvents;
      });
    }
  }

  List<Lesson> _getEventsForDay(DateTime day) {
    // Нормалізація дати для порівняння лише днів (без часу)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 10),
          Expanded(child: _buildEventList()),
        ],
      ),
      // Піднімаємо кнопку, щоб вона не ховалася за нижнім меню
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 105.0),
        child: FloatingActionButton(
          onPressed: () {
            _showAddEventDialog();
          },
          backgroundColor: const Color(0xFF2D5A40),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5A40).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
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
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        eventLoader: _getEventsForDay,
        
        // Стилізація календаря під Soft UI
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF2D5A40),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF2D5A40).withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.orangeAccent,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF2D5A40),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
            Text(
              "На цей день пар немає",
              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      // Додаємо великий відступ знизу (bottom: 120), щоб остання картка була над меню
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return LessonCard(lesson: events[index]);
      },
    );
  }

  // Тестові дані з обов'язковим параметром id
  Map<DateTime, List<Lesson>> _getMockEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return {
      today: [
        Lesson(
          id: '1', // Обов'язковий ID
          title: 'Мобільна розробка',
          description: 'ауд. 305 / лекція',
          startTime: DateTime(now.year, now.month, now.day, 10, 10),
          endTime: DateTime(now.year, now.month, now.day, 11, 30),
          type: LessonType.lecture,
        ),
        Lesson(
          id: '2', // Обов'язковий ID
          title: 'Основи UI/UX',
          description: 'Zoom конференція',
          startTime: DateTime(now.year, now.month, now.day, 11, 50),
          endTime: DateTime(now.year, now.month, now.day, 13, 10),
          type: LessonType.practice,
        ),
      ],
    };
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay selectedStartTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay selectedEndTime = const TimeOfDay(hour: 9, minute: 20);
    LessonType selectedType = LessonType.lecture;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Для Soft UI ефекту
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20, left: 20, right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Додати свою подію", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Назва (напр. Підготовка до заліку)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: "Опис або місце",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 15),
              
              // Вибір типу
              DropdownButtonFormField<LessonType>(
                value: selectedType,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                items: LessonType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                )).toList(),
                onChanged: (val) => setModalState(() => selectedType = val!),
              ),
              
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: selectedStartTime);
                      if (time != null) setModalState(() => selectedStartTime = time);
                    },
                    child: Text("Початок: ${selectedStartTime.format(context)}"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(context: context, initialTime: selectedEndTime);
                      if (time != null) setModalState(() => selectedEndTime = time);
                    },
                    child: Text("Кінець: ${selectedEndTime.format(context)}"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    _addNewEvent(
                      titleController.text,
                      descController.text,
                      selectedStartTime,
                      selectedEndTime,
                      selectedType,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A40),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Зберегти", style: TextStyle(color: Colors.white)),
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
      id: DateTime.now().toString(), // Генеруємо унікальний ID
      title: title,
      description: desc,
      startTime: DateTime(normalizedDay.year, normalizedDay.month, normalizedDay.day, start.hour, start.minute),
      endTime: DateTime(normalizedDay.year, normalizedDay.month, normalizedDay.day, end.hour, end.minute),
      type: type,
    );

    setState(() {
      if (_events[normalizedDay] != null) {
        _events[normalizedDay]!.add(newLesson);
      } else {
        _events[normalizedDay] = [newLesson];
      }
      // Сортуємо за часом для краси
      _events[normalizedDay]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    _saveEvents(); // Зберігаємо після кожного додавання
  }
}