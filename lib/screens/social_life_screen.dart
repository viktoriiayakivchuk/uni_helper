import 'package:flutter/material.dart';
import 'dart:ui';

class SocialLifeScreen extends StatelessWidget {
  const SocialLifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Соціальне життя', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2D5A40),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Фільтрація (Твій метод тепер у дії)
              const Text(
                'Категорії',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
              ),
              const SizedBox(height: 10),
              _buildFilterChips(),
              
              const SizedBox(height: 25),

              // 2. Стрічка анонсів
              const Text(
                'Найближчі події',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
              ),
              const SizedBox(height: 15),
              _buildEventCard('Екскурсія університетом', '10 лют, 14:00', 'Студрада'),
              _buildEventCard('Гранти Erasmus+', '15 лют, 11:00', 'Міжнародний відділ'),
              _buildEventCard('Зустріч з куратором', '12 лют, 10:00', 'Кафедра'),

              const SizedBox(height: 25),

              // 3. Секції FAQ та Знайомства
              const Text(
                'Додатково',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D5A40)),
              ),
              const SizedBox(height: 15),
              _buildActionCard(
                'FAQ: Організації та клуби', 
                'Все про студентське дозвілля', 
                Icons.help_center_outlined
              ),
              _buildActionCard(
                'Познайомся з групою', 
                'Чат вашої групи та куратор', 
                Icons.people_outline
              ),
            ],
          ),
        ),
      ),
    );
  }

  // МЕТОД 1: Фільтри
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Всі', 'Оголошення', 'Erasmus+', 'Наука'].map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              onSelected: (val) {},
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF2D5A40).withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // МЕТОД 2: Картка події (Оновлено: додано кнопку "Нагадати")
  Widget _buildEventCard(String title, String date, String organizer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF2D5A40).withOpacity(0.05),
        border: Border.all(color: const Color(0xFF2D5A40).withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF2D5A40),
          child: Icon(Icons.event, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$date • $organizer'),
        trailing: IconButton(
          icon: const Icon(Icons.notification_add_outlined, color: Color(0xFF2D5A40)),
          onPressed: () {
            // Тут буде додавання в календар
          },
        ),
      ),
    );
  }

  // МЕТОД 3: Картка для FAQ та Знайомств
  Widget _buildActionCard(String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2D5A40), size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}