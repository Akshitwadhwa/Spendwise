import 'package:flutter/material.dart';
import 'dart:ui';

enum TabType { home, recent, stats, carpool }

class BottomNavbar extends StatelessWidget {
  final TabType activeTab;
  final Function(TabType) onTabChange;

  const BottomNavbar({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _TabItem(id: TabType.home, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      const _TabItem(id: TabType.recent, icon: Icons.history, activeIcon: Icons.history, label: 'Recent'),
      const _TabItem(id: TabType.stats, icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Stats'),
      const _TabItem(
        id: TabType.carpool,
        icon: Icons.directions_car_outlined,
        activeIcon: Icons.directions_car,
        label: 'Carpool',
      ),
    ];

    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: tabs.map((tab) {
                final isActive = activeTab == tab.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChange(tab.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.white.withValues(alpha: 0.1) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: isActive ? 1.1 : 1.0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  isActive ? tab.activeIcon : tab.icon,
                                  size: 24,
                                  color: isActive 
                                      ? const Color(0xFF34d399) 
                                      : const Color(0xFF94a3b8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isActive 
                                      ? Colors.white 
                                      : const Color(0xFF64748b),
                                ),
                                child: Text(tab.label),
                              ),
                            ],
                          ),
                          // Active indicator dot
                          if (isActive)
                            Positioned(
                              bottom: 2,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34d399),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF34d399).withValues(alpha: 0.8),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final TabType id;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem({
    required this.id,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
