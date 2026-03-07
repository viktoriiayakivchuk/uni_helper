import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/student_card.dart';

class StudentCardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _userId => _auth.currentUser!.uid;

  // Отримання студентського квитка поточного користувача
  Future<StudentCard?> getStudentCard() async {
    try {
      final doc = await _firestore
          .collection('student_cards')
          .where('userId', isEqualTo: _userId)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;

      return StudentCard.fromFirestore(
          doc.docs.first.data(), doc.docs.first.id);
    } catch (e) {
      print('Помилка отримання студентського квитка: $e');
      return null;
    }
  }

  // Завантаження фото студентського квитка
  Future<String> uploadStudentCardPhoto(File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'student_cards/$_userId/$timestamp.jpg';

      final ref = _storage.ref().child(filename);
      await ref.putFile(imageFile);

      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Помилка завантаження фото: $e');
      throw Exception('Не вдалося завантажити фото: $e');
    }
  }

  // Створення нового студентського квитка
  Future<StudentCard> createStudentCard({
    required String cardNumber,
    required String fullName,
    required String photoUrl,
  }) async {
    try {
      final doc = _firestore.collection('student_cards').doc();

      final studentCard = StudentCard(
        id: doc.id,
        userId: _userId,
        cardNumber: cardNumber,
        fullName: fullName,
        photoUrl: photoUrl,
        uploadedAt: DateTime.now(),
        isVerified: false,
      );

      await doc.set(studentCard.toFirestore());
      return studentCard;
    } catch (e) {
      print('Помилка створення студентського квитка: $e');
      throw Exception('Не вдалося зберегти студентський: $e');
    }
  }

  // Оновлення студентського квитка
  Future<void> updateStudentCard(StudentCard studentCard) async {
    try {
      await _firestore
          .collection('student_cards')
          .doc(studentCard.id)
          .update(studentCard.toFirestore());
    } catch (e) {
      print('Помилка оновлення студентського квитка: $e');
      throw Exception('Не вдалося оновити студентський: $e');
    }
  }

  // Видалення студентського квитка
  Future<void> deleteStudentCard(String cardId) async {
    try {
      await _firestore.collection('student_cards').doc(cardId).delete();
    } catch (e) {
      print('Помилка видалення студентського квитка: $e');
      throw Exception('Не вдалося видалити студентський: $e');
    }
  }

  // Stream для слідкування за студентським квитком в реальному часі
  Stream<StudentCard?> watchStudentCard() {
    return _firestore
        .collection('student_cards')
        .where('userId', isEqualTo: _userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return StudentCard.fromFirestore(
          snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }
}
