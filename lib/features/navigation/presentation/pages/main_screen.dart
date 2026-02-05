import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../schedule/presentation/pages/pages/schedule_page.dart';
import '../../../glossary/presentation/pages/glossary_page.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Список сторінок згідно з вимогами 1, 2, 3...
  static const List<Widget> _pages = [
    SchedulePage(), // Вимога №2
    Center(child: Text('Карта (Заглушка)')), // Вимога №1
    GlossaryPage(), // Вимога №3
    Center(child: Text('Профіль')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Важливо для прозорості BottomNavigationBar
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25), // Soft UI: BorderRadius 20+
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white.withOpacity(0.7), // Glassmorphism
              selectedItemColor: const Color(0xFF2D5A40), // Наш бренд-колір
              unselectedItemColor: Colors.grey,
              showSelectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Розклад'),
                BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Карта'),
                BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'Словник'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профіль'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}