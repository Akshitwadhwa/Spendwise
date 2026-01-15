import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import 'wallet_screen.dart';
import 'recent_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TabType _activeTab = TabType.home;

  void _onTabChange(TabType tab) {
    setState(() {
      _activeTab = tab;
    });
  }

  Widget _getScreen() {
    switch (_activeTab) {
      case TabType.home:
        return const WalletScreen();
      case TabType.recent:
        return const RecentScreen();
      case TabType.stats:
        return const StatsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          // Current screen
          _getScreen(),
          // Bottom navbar
          BottomNavbar(
            activeTab: _activeTab,
            onTabChange: _onTabChange,
          ),
        ],
      ),
    );
  }
}
