import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static String _normalizeIdentifierToEmail(String usernameOrEmail) {
    final normalized = usernameOrEmail.trim().toLowerCase();
    if (normalized.contains('@')) {
      return normalized;
    }
    return '$normalized@spendwise.local';
  }

  static Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();

    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }

    return _auth.signInWithProvider(provider);
  }

  static Future<UserCredential> signInWithUsernamePassword({
    required String usernameOrEmail,
    required String password,
  }) async {
    final email = _normalizeIdentifierToEmail(usernameOrEmail);
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<UserCredential> createAccountWithUsernamePassword({
    required String usernameOrEmail,
    required String password,
    String? displayName,
  }) async {
    final email = _normalizeIdentifierToEmail(usernameOrEmail);
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final cleanName = displayName?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      await credential.user?.updateDisplayName(cleanName);
      await credential.user?.reload();
    }

    return credential;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
