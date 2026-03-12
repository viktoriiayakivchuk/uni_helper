import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCard {
  final String id;
  final String uid;
  final String cardNumber;
  final String fullName;
  final String photoUrl; // Тепер тут зберігається ЛОКАЛЬНИЙ шлях до файлу
  final DateTime uploadedAt;
  final bool isVerified;

  StudentCard({
    required this.id,
    required this.uid,
    required this.cardNumber,
    required this.fullName,
    required this.photoUrl,
    required this.uploadedAt,
    this.isVerified = false,
  });

  // Конвертація з Firestore
  factory StudentCard.fromFirestore(Map<String, dynamic> data, String docId) {
    return StudentCard(
      id: docId,
      uid: data['uid'] ?? '',
      cardNumber: data['cardNumber'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      // ВИПРАВЛЕНО: Firestore повертає Timestamp, тому конвертуємо через .toDate()
      uploadedAt: data['uploadedAt'] is Timestamp 
          ? (data['uploadedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  // Конвертація в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'cardNumber': cardNumber,
      'fullName': fullName,
      'photoUrl': photoUrl,
      // Firestore автоматично перетворить DateTime на Timestamp
      'uploadedAt': uploadedAt, 
      'isVerified': isVerified,
    };
  }
}