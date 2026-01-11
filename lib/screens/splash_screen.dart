import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'wallet_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WalletScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a2842),
              Color(0xFF0f1729),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Wallet Icon
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF2a3550),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 80,
                color: AppColors.accentTeal,
              ),
            ),
            const SizedBox(height: 40),
            // App Name
            const Text(
              'SpendWise',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: AppColors.textWhite,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            // Tagline
            Text(
              'MASTER YOUR MONEY',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textGray.withOpacity(0.7),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
