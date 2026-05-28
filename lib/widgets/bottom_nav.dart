import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme/app_palette.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/stats/stats_screen.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    StatsScreen(),
    RemindersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Stack(
        children: [
          IndexedStack(index: index, children: pages),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _item(0, LucideIcons.house, 'Accueil'),
                    _item(1, LucideIcons.chartColumn, 'Stats'),
                    _item(2, LucideIcons.bell, 'Rappels'),
                    _item(3, LucideIcons.user, 'Profil'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final active = index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => index = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE8F1FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? AppPalette.water : AppPalette.textMuted,
                size: 21,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppPalette.water : AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
