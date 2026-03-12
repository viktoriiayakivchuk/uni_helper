import 'package:cloud_firestore/cloud_firestore.dart';

class StudentCard {
  final String id;
  final String uid;
  final String cardNumber;
  final String fullName;
  final String university; // НОВЕ
  final String faculty;    // НОВЕ
  final String issueDate;  // НОВЕ
  final String expiryDate; // НОВЕ
  final String photoUrl;
  final DateTime uploadedAt;
  final bool isVerified;

  StudentCard({
    required this.id,
    required this.uid,
    required this.cardNumber,
    required this.fullName,
    required this.university,
    required this.faculty,
    required this.issueDate,
    required this.expiryDate,
    required this.photoUrl,
    required this.uploadedAt,
    this.isVerified = false,
  });

  factory StudentCard.fromFirestore(Map<String, dynamic> data, String docId) {
    return StudentCard(
      id: docId,
      uid: data['uid'] ?? '',
      cardNumber: data['cardNumber'] ?? '',
      fullName: data['fullName'] ?? '',
      university: data['university'] ?? '', // НОВЕ
      faculty: data['faculty'] ?? '',       // НОВЕ
      issueDate: data['issueDate'] ?? '',   // НОВЕ
      expiryDate: data['expiryDate'] ?? '', // НОВЕ
      photoUrl: data['photoUrl'] ?? '',
      uploadedAt: data['uploadedAt'] is Timestamp 
          ? (data['uploadedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'cardNumber': cardNumber,
      'fullName': fullName,
      'university': university, // НОВЕ
      'faculty': faculty,       // НОВЕ
      'issueDate': issueDate,   // НОВЕ
      'expiryDate': expiryDate, // НОВЕ
      'photoUrl': photoUrl,
      'uploadedAt': uploadedAt,
      'isVerified': isVerified,
    };
  }
}