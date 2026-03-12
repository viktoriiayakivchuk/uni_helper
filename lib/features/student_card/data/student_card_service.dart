import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/student_card.dart';

class StudentCardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Отримуємо UID поточного користувача
  String get _userId => _auth.currentUser!.uid;

  // Отримання студентського з Firestore
  Future<StudentCard?> getStudentCard() async {
    try {
      final query = await _firestore
          .collection('student_cards')
          .where('uid', isEqualTo: _userId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      return StudentCard.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      print('Помилка отримання даних: $e');
      return null;
    }
  }

  // Створення запису (photoUrl тепер містить локальний шлях)
  Future<StudentCard> createStudentCard({
    required String cardNumber,
    required String fullName,
    required String photoUrl, // Тут буде локальний шлях
  }) async {
    try {
      final docRef = _firestore.collection('student_cards').doc();

      final studentCard = StudentCard(
        id: docRef.id,
        uid: _userId,
        cardNumber: cardNumber,
        fullName: fullName,
        photoUrl: photoUrl,
        uploadedAt: DateTime.now(),
        isVerified: false,
      );

      await docRef.set(studentCard.toFirestore());
      return studentCard;
    } catch (e) {
      throw Exception('Не вдалося зберегти дані в Firestore: $e');
    }
  }

  Stream<StudentCard?> watchStudentCard() {
    return _firestore
        .collection('student_cards')
        .where('uid', isEqualTo: _userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return StudentCard.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  Future<void> deleteStudentCard(String cardId) async {
    await _firestore.collection('student_cards').doc(cardId).delete();
  }
}