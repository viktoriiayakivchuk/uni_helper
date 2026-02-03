import 'package:flutter/material.dart';

void main() => runApp(const UniHelperApp());

class UniHelperApp extends StatelessWidget {
  const UniHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF7F9F7),
      ),
      home: const ScheduleScreen(),
    );
  }
}

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.calendar_month, color: Color(0xFF2D5A40)),
        title: const Text('Розклад занять', 
          style: TextStyle(color: Color(0xFF2D5A40), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications, color: Color(0xFF2D5A40)))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // Перемикач Сьогодні/Тиждень
            Row(
              children: [
                _buildToggleBtn("Сьогодні", true),
                _buildToggleBtn("Тиждень", false),
                const Spacer(),
                _buildAddBtn(),
              ],
            ),
            const SizedBox(height: 20),
            // Вибір дати
            _buildDatePicker(),
            const SizedBox(height: 20),
            // Список пар
            _buildLessonCard("Процедурне програмування", "9:00 – 10:30", "Лекція", "Віктор Іванченко", "9:00", "18", const Color(0xFF2D5A40)),
            _buildLessonCard("Вища математика", "10:45 – 12:15", "Семінар", "Тетяна Новикова", "10:45", "22", const Color(0xFF4A8B66)),
            _buildLessonCard("Історія України", "12:30 – 14:00", "On-line", "Олена Гаврилюк", "12:30", "G", const Color(0xFF7CAF91)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF2D5A40),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Додати пару", style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Віджет кнопки перемикача
  Widget _buildToggleBtn(String text, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
      ),
      child: Text(text, style: TextStyle(color: isActive ? Colors.black87 : Colors.grey)),
    );
  }

  // Кнопка + Додати
  Widget _buildAddBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF2D5A40), borderRadius: BorderRadius.circular(12)),
      child: const Row(children: [Icon(Icons.add, color: Colors.white, size: 18), Text(" Додати", style: TextStyle(color: Colors.white))]),
    );
  }

  // Календарна стрічка
  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _dateItem("Пн", "17", false), _dateItem("Вт", "18", false),
        _dateItem("Ср", "19", false), _dateItem("Чт", "20", true),
        _dateItem("Пт", "21", false), _dateItem("Сб", "22", false), _dateItem("Нд", "23", false),
      ],
    );
  }

  Widget _dateItem(String day, String date, bool isSelected) {
    return Column(
      children: [
        Text(day, style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(date, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF2D5A40) : Colors.black87)),
        if (isSelected) Container(height: 2, width: 15, color: const Color(0xFF2D5A40)),
      ],
    );
  }

  // Картка пари
  Widget _buildLessonCard(String title, String time, String type, String teacher, String t1, String t2, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Row(
        children: [
          // Лівий кольоровий блок
          Container(
            width: 50, height: 100,
            decoration: BoxDecoration(color: themeColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(t1, style: const TextStyle(color: Colors.white, fontSize: 10)),
                Text(t2, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 15),
          // Інфо про пару
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text("$type • $teacher", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.notifications_active, color: Color(0xFF2D5A40), size: 20),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2D5A40),
      currentIndex: 1,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Головна'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: 'Розклад'),
        BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: 'Документи'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Меню'),
      ],
    );
  }
}