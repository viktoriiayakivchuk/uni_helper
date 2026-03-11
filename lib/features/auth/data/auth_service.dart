import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../domain/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      // ВИПРАВЛЕНО: Прибрали scopes, оскільки вони тепер запитуються окремо
      await _googleSignIn.initialize(
        clientId: kIsWeb 
            ? '147590815135-1bdt9fvlhtfpajro12kuhhtckbljl399.apps.googleusercontent.com' 
            : null,
      );
      _isGoogleSignInInitialized = true;
    }
  }

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        final dynamic result = _googleSignIn.attemptLightweightAuthentication();
        if (result is Future) {
          googleUser = await result;
        } else {
          googleUser = result;
        }
      }
      
      // Якщо користувач скасує вхід, authenticate() викине помилку (її зловить catch), 
      // тому після цього рядка googleUser гарантовано НЕ null.
      googleUser ??= await _googleSignIn.authenticate();

      // ПЕРЕВІРКА ДОМЕНУ (згідно з п. 135 ТЗ)
      if (!googleUser.email.endsWith('@pnu.edu.ua')) {
        await _googleSignIn.signOut();
        throw Exception("Дозволено вхід тільки з пошти @pnu.edu.ua");
      }

      final String? idToken = googleUser.authentication.idToken;
      
      final authClient = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);
      
      // ВИПРАВЛЕНО: authClient тепер точно не null, тому прибрали знак '?'
      final String accessToken = authClient.accessToken;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
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
      debugPrint("Auth Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("SignOut Error: $e");
    }
  }
}