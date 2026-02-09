import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0f172a),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF10b981),
              ),
            ),
          );
        }

        if (snapshot.data != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
