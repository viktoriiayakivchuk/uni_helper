import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/lesson_card.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Для ефекту скла під AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.2),
              elevation: 0,
              leading: const Icon(Icons.calendar_month, color: Color(0xFF2D5A40)),
              title: const Text('Розклад занять', 
                style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 100, 20, 20),
        child: Column(
          children: [
            // Тут будуть ваші віджети перемикача та календаря
            SizedBox(height: 20),
            LessonCard(
              title: "Процедурне програмування",
              time: "9:00 – 10:30",
              type: "Лекція",
              teacher: "Віктор Іванченко",
              themeColor: Color(0xFF2D5A40),
            ),
            // Додайте інші картки...
          ],
        ),
      ),
    );
  }
}