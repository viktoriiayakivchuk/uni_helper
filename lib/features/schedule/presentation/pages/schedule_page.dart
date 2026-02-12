import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/lesson_model.dart';
import '../widgets/lesson_card.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  // 1. ЗМІНА: Ставимо тижневий формат за замовчуванням
  CalendarFormat _calendarFormat = CalendarFormat.week; 
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Lesson>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = _getMockEvents();
    _loadEvents();
  }

  // --- ЛОГІКА LOCAL STORAGE ---
  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
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
        
        // 2. ЗМІНА: Кастомний білдер для маркерів (обмежуємо до 3-х)
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((_) { // <-- Беремо максимум 3 події
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 5, // Зробив трохи меншими та акуратнішими
                    height: 5,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orangeAccent,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),

        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF2D5A40),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF2D5A40).withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          // markerDecoration ми прибрали, бо тепер працює markerBuilder
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
              "На цей день справ немає",
              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
            ),
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

  Map<DateTime, List<Lesson>> _getMockEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return {
      today: [
        Lesson(
          id: '1',
          title: 'Мобільна розробка',
          description: 'ауд. 305 / лекція',
          startTime: DateTime(now.year, now.month, now.day, 10, 10),
          endTime: DateTime(now.year, now.month, now.day, 11, 30),
          type: LessonType.lecture,
        ),
        Lesson(
          id: '2',
          title: 'Основи UI/UX',
          description: 'Zoom конференція',
          startTime: DateTime(now.year, now.month, now.day, 11, 50),
          endTime: DateTime(now.year, now.month, now.day, 13, 10),
          type: LessonType.practice,
        ),
      ],
    };
  }

  void _showAddEventDialog({Lesson? eventToEdit}) {
    final titleController = TextEditingController(text: eventToEdit?.title ?? "");
    final descController = TextEditingController(text: eventToEdit?.description ?? "");
    
    TimeOfDay selectedStartTime = eventToEdit != null 
        ? TimeOfDay.fromDateTime(eventToEdit.startTime) 
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay selectedEndTime = eventToEdit != null 
        ? TimeOfDay.fromDateTime(eventToEdit.endTime) 
        : const TimeOfDay(hour: 10, minute: 0);
        
    LessonType selectedType = eventToEdit?.type ?? LessonType.practice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 25, left: 20, right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Text(
                eventToEdit == null ? "Нова справа" : "Редагування", 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: "Що плануєте? *",
                  hintText: "Напр. Спортзал",
                  prefixIcon: const Icon(Icons.task_alt_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 15),
              
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: "Нотатки (необов'язково)",
                  hintText: "Напр. Взяти форму",
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: selectedStartTime);
                        if (time != null) setModalState(() => selectedStartTime = time);
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(selectedStartTime.format(context)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text("-", style: TextStyle(fontSize: 20, color: Colors.grey)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: selectedEndTime);
                        if (time != null) setModalState(() => selectedEndTime = time);
                      },
                      icon: const Icon(Icons.access_time_filled),
                      label: Text(selectedEndTime.format(context)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isEmpty) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введіть назву справи!')));
                     return;
                  }

                  if (eventToEdit != null) {
                      final oldDate = DateTime(eventToEdit.startTime.year, eventToEdit.startTime.month, eventToEdit.startTime.day);
                      setState(() {
                        _events[oldDate]?.removeWhere((l) => l.id == eventToEdit.id);
                      });
                  }

                  _addNewEvent(
                    titleController.text,
                    descController.text,
                    selectedStartTime,
                    selectedEndTime,
                    selectedType,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5A40),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: Text(
                  eventToEdit == null ? "Додати в розклад" : "Зберегти зміни", 
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
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

  void _deleteEvent(Lesson lesson) {
    final dateKey = DateTime(lesson.startTime.year, lesson.startTime.month, lesson.startTime.day);
    setState(() {
      _events[dateKey]?.removeWhere((l) => l.id == lesson.id);
      _saveEvents();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Справу видалено')));
  }

  void _showEventDetails(Lesson lesson) {
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
                Text(
                  lesson.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.orangeAccent),
                    const SizedBox(width: 10),
                    Text(
                      "${DateFormat('HH:mm').format(lesson.startTime)} - ${DateFormat('HH:mm').format(lesson.endTime)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (lesson.description.isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, color: Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lesson.description,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 25),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        _deleteEvent(lesson);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      label: const Text("Видалити", style: TextStyle(color: Colors.redAccent)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEventDialog(eventToEdit: lesson);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5A40),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Змінити"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}