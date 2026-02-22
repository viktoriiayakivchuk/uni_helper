import 'package:cloud_firestore/cloud_firestore.dart';

class ContactsSeeder {
  static final List<Map<String, dynamic>> _initialContacts = [
    {
      'title': 'Деканат IT-факультету',
      'name': 'Петренко Петро Петрович',
      'phone': '+380441234567',
      'email': 'it_dean@univ.edu.ua',
      'office': '301',
      'category': 'Адміністрація'
    },
    {
      'title': 'Студентський Сенат',
      'phone': '+380931112233',
      'email': 'senat@univ.edu.ua',
      'office': '102',
      'category': 'Студсенат'
    },
    {
      'title': 'Кафедра ПЗАС',
      'name': 'Сидоренко С.С.',
      'phone': '+380449876543',
      'email': 'pzas@univ.edu.ua',
      'office': '405',
      'category': 'Кафедри'
    },
    {
    'title': 'Бібліотека',
    'phone': '+380445556677',
    'email': 'lib@univ.edu.ua',
    'office': 'Центральний корпус',
    'category': 'Адміністрація'
  },
  ];

  static Future<void> seed() async {
    final collection = FirebaseFirestore.instance.collection('contacts');
    for (var data in _initialContacts) {
      await collection.add(data);
    }
    print("✅ Contacts Seeded!");
  }
}