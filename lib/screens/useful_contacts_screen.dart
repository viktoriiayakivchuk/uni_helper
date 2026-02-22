import 'package:flutter/material.dart';

// 1. Модель даних для контакту
class Contact {
  final String title;
  final String phone;
  final String email;
  final String room;
  final String category;

  Contact({
    required this.title, 
    required this.phone, 
    required this.email, 
    required this.room, 
    required this.category
  });
}

class UsefulContactsScreen extends StatelessWidget {
  const UsefulContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Твій список контактів (Data)
    final List<Contact> contacts = [
      Contact(title: "Деканат", phone: "+380441234567", email: "dean@uni.edu", room: "каб. 302", category: "Адміністрація"),
      Contact(title: "Студсенат", phone: "+380447654321", email: "senat@uni.edu", room: "каб. 105", category: "Студсамоврядування"),
      Contact(title: "Бібліотека", phone: "+380441112233", email: "lib@uni.edu", room: "2 поверх", category: "Кафедри"),
      Contact(title: "Медпункт", phone: "+380440000000", email: "med@uni.edu", room: "каб. 10", category: "Адміністрація"),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Корисні контакти', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2D5A40),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Контакти університету',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF2D5A40)
                ),
              ),
              const SizedBox(height: 15),
              
              // 3. Рендеримо список через метод
              ...contacts.map((contact) => _buildContactCard(contact)),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Оновлений метод побудови картки в стилі Soft UI
  Widget _buildContactCard(Contact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20), // Суворо за ТЗ
        boxShadow: [
          const BoxShadow(
            color: Colors.white, 
            offset: Offset(-5, -5), 
            blurRadius: 10
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            offset: const Offset(5, 5), 
            blurRadius: 10
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D5A40).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: Color(0xFF2D5A40)),
        ),
        title: Text(
          contact.title, 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5A40))
        ),
        subtitle: Text(
          "${contact.room} • ${contact.category}\n${contact.phone}",
          style: const TextStyle(fontSize: 13),
        ),
        isThreeLine: true,
        // Дві іконки дій праворуч
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionIconButton(Icons.phone, () {
              // Тут буде tel:${contact.phone} через url_launcher
            }),
            const SizedBox(width: 8),
            _actionIconButton(Icons.alternate_email, () {
              // Тут буде mailto:${contact.email} через url_launcher
            }),
          ],
        ),
      ),
    );
  }

  // Допоміжний метод для кнопок дій
  Widget _actionIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF2D5A40), size: 20),
        onPressed: onTap,
        constraints: const BoxConstraints(), // Зменшуємо відступи іконки
        padding: const EdgeInsets.all(8),
      ),
    );
  }
}