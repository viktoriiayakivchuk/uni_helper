import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      // Примусовий вибір акаунта (допомагає, якщо ви видалили юзера з бази)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // ПЕРЕВІРКА ДОМЕНУ (п. 147 ТЗ)
      if (!googleUser.email.endsWith('@pnu.edu.ua')) {
        await _googleSignIn.signOut();
        throw Exception("Дозволено вхід тільки з пошти @pnu.edu.ua");
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email!,
            fullName: user.displayName ?? "Студент КНУВС",
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        }
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Метод для повного виходу, щоб змінити користувача
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Обов'язково для скидання Google-сесії
    await _auth.signOut();
  }
}