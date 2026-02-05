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

  static const List<Widget> _pages = [
    SchedulePage(),
    Center(child: Text('Карта (Заглушка)')),
    GlossaryPage(),
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
      // extendBody залишаємо для ефекту прозорості під баром
      extendBody: true, 
      // Використовуємо IndexedStack, щоб зберігати стан сторінок при перемиканні
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        // Додаємо відступи, щоб створити ефект "плаваючої" панелі Soft UI
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          // ПРИБРАНО жорстку висоту height: 70, яка викликала overflow
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
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
                backgroundColor: Colors.white.withOpacity(0.7),
                selectedItemColor: const Color(0xFF2D5A40),
                unselectedItemColor: Colors.grey,
                showSelectedLabels: true,
                type: BottomNavigationBarType.fixed,
                // Додаємо невеликий внутрішній відступ для іконок
                selectedFontSize: 12,
                unselectedFontSize: 12,
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
      ),
    );
  }
}