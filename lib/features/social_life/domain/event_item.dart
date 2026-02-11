import 'package:cloud_firestore/cloud_firestore.dart';

class EventItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String category;

  EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.category,
  });

  factory EventItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? 'Загальне',
    );
  }
}