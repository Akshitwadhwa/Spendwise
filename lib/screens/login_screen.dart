import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Google sign-in failed. Please try again.';
      });
    } catch (_) {
      setState(() {
        _error = 'Google sign-in failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Color(0xFF10b981),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'SpendWise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to sync your profile and expenses',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF94a3b8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    label: Text(
                      _isLoading ? 'Signing in...' : 'Continue with Google',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
