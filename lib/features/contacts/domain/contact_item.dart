import 'package:cloud_firestore/cloud_firestore.dart';

class ContactItem {
  final String id;
  final String title;    // Назва підрозділу (напр. "Деканат")
  final String? name;    // ПІБ (напр. "Іванов І.І.")
  final String phone;
  final String email;
  final String office;
  final String category; // Адміністрація, Кафедри, Студсенат

  ContactItem({
    required this.id,
    required this.title,
    this.name,
    required this.phone,
    required this.email,
    required this.office,
    required this.category,
  });

  factory ContactItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ContactItem(
      id: doc.id,
      title: data['title'] ?? '',
      name: data['name'],
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      office: data['office'] ?? '',
      category: data['category'] ?? 'Загальне',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'name': name,
      'phone': phone,
      'email': email,
      'office': office,
      'category': category,
    };
  }
}