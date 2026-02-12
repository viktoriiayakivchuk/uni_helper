import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../domain/lesson_model.dart';
import '../widgets/lesson_card.dart';

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
            // Логіка додавання власної події
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
}