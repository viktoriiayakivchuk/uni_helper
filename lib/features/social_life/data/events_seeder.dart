import 'package:cloud_firestore/cloud_firestore.dart';

class EventsSeeder {
  static Future<void> seedEvents() async {
    final CollectionReference events =
        FirebaseFirestore.instance.collection('events');

    final List<Map<String, dynamic>> initialEvents = [
      {
        "id": "event_1",
        "title": "Студентський квест",
        "description": "Пригодницька гра по всій території університету.",
        "location": "Головний корпус",
        "date": DateTime(2026, 05, 20, 14, 00),
        "category": "Дозвілля",
      },
      {
        "id": "event_2",
        "title": "Благодійний ярмарок",
        "description": "Збір коштів на підтримку ЗСУ: смаколики та хендмейд.",
        "location": "Внутрішній двір",
        "date": DateTime(2026, 05, 25, 11, 00),
        "category": "Волонтерство",
      },
      {
        "id": "event_3",
        "title": "День спорту",
        "description": "Змагання з футболу та волейболу між факультетами.",
        "location": "Спорткомплекс",
        "date": DateTime(2026, 06, 01, 10, 00),
        "category": "Спорт",
      },
    ];

    for (var event in initialEvents) {
      // Використовуємо кастомний ID, щоб не було дублів при перезапуску
      await events.doc(event['id']).set({
        'title': event['title'],
        'description': event['description'],
        'location': event['location'],
        'date': Timestamp.fromDate(event['date']),
        'category': event['category'],
      });
    }
    print("Events seeded successfully!");
  }
}