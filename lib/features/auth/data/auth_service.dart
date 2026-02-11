import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../domain/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Оновлена ініціалізація GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // ВАЖЛИВО: Переконайтеся, що цей ID точно такий же, як у Google Cloud Console 
    // для типу "Web application". Помилка 401 зазвичай тут.
    clientId: kIsWeb 
        ? '147590815135-1bdt9fvlhtfpajro12kuhhtckbljl399.apps.googleusercontent.com' 
        : null,
    scopes: [
      'email',
      'profile',
    ],
  );

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      // Для Вебу спочатку пробуємо тихий вхід, щоб уникнути блокування поп-апу
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        googleUser = await _googleSignIn.signInSilently();
      }
      
      googleUser ??= await _googleSignIn.signIn();
      
      if (googleUser == null) return null;

      // ПЕРЕВІРКА ДОМЕНУ (згідно з п. 135 ТЗ)
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
        // Синхронізація профілю з Firestore (п. 150 ТЗ)
        final doc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!doc.exists) {
          UserModel newUser = UserModel(
            uid: user.uid,
            email: user.email!,
            fullName: user.displayName ?? "Студент ПНУ",
          );
          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        }
      }
      return user;
    } catch (e) {
      print("Auth Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("SignOut Error: $e");
    }
  }
}