import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();

    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }

    return _auth.signInWithProvider(provider);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
