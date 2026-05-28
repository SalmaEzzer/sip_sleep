import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_palette.dart';
import '../auth/auth_provider.dart';
import 'goals_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  int _waterGoal = 8;
  int _sleepGoal = 8;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final goals = ref.watch(goalsProvider);

    final name = (user?['name']?.toString().trim().isNotEmpty ?? false)
        ? user!['name'].toString().trim()
        : 'Utilisateur';
    final email = user?['email']?.toString() ?? 'admin@gmail.com';

    if (!_initialized) {
      _displayNameCtrl.text = name;
      _waterGoal = goals.waterGoal;
      _sleepGoal = goals.sleepGoal;
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
          children: [
            _header(),
            const SizedBox(height: 18),
            _avatar(_initials(_displayNameCtrl.text.isEmpty ? name : _displayNameCtrl.text), email),
            const SizedBox(height: 16),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nom d\'affichage',
                    style: TextStyle(fontSize: 15, color: AppPalette.textMuted),
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _displayNameCtrl,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFEFF3F8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Objectifs quotidiens',
                    style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(LucideIcons.droplets, color: AppPalette.water, size: 17),
                      SizedBox(width: 8),
                      Text('Verres d\'eau par jour', style: TextStyle(fontSize: 15, color: AppPalette.textMuted)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppPalette.water,
                            inactiveTrackColor: Colors.black.withOpacity(0.7),
                            thumbColor: AppPalette.water,
                          ),
                          child: Slider(
                            value: _waterGoal.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            onChanged: (v) => setState(() => _waterGoal = v.round()),
                          ),
                        ),
                      ),
                      Text(
                        '$_waterGoal',
                        style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w700, color: AppPalette.water),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(LucideIcons.moon, color: AppPalette.sleep, size: 17),
                      SizedBox(width: 8),
                      Text('Heures de sommeil par nuit', style: TextStyle(fontSize: 15, color: AppPalette.textMuted)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppPalette.sleep,
                            inactiveTrackColor: Colors.black.withOpacity(0.7),
                            thumbColor: AppPalette.sleep,
                          ),
                          child: Slider(
                            value: _sleepGoal.toDouble(),
                            min: 4,
                            max: 12,
                            divisions: 16,
                            onChanged: (v) => setState(() => _sleepGoal = v.round()),
                          ),
                        ),
                      ),
                      Text(
                        '${_sleepGoal}h',
                        style: const TextStyle(fontSize: 35, fontWeight: FontWeight.w700, color: AppPalette.sleep),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.award, color: AppPalette.success),
                      SizedBox(width: 8),
                      Text(
                        'Badges',
                        style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _badge('Hydraté', LucideIcons.droplets, AppPalette.water),
                      const SizedBox(width: 8),
                      _badge('Dormeur', LucideIcons.moon, AppPalette.sleep),
                      const SizedBox(width: 8),
                      _badge('Régulier', LucideIcons.award, AppPalette.success),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await ref.read(authProvider.notifier).updateDisplayName(_displayNameCtrl.text);
                          await ref.read(goalsProvider.notifier).setWaterGoal(_waterGoal);
                          await ref.read(goalsProvider.notifier).setSleepGoal(_sleepGoal);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profil mis à jour ✅')),
                          );
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.save, color: Colors.white),
                label: Text(
                  _saving ? 'Sauvegarde...' : 'Sauvegarder',
                  style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(LucideIcons.logOut, color: AppPalette.danger),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(fontSize: 29, fontWeight: FontWeight.w700, color: AppPalette.danger),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8EBEA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppPalette.headerGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFC2DCF0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.user, color: AppPalette.water),
          ),
          const SizedBox(width: 12),
          const Text(
            'Profil',
            style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String initials, String email) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3F95D7), Color(0xFF41B4C5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Text(email, style: const TextStyle(fontSize: 16, color: AppPalette.textMuted)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: SoftShadow.card(Colors.grey),
      ),
      child: child,
    );
  }

  Widget _badge(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final txt = name.trim();
    if (txt.isEmpty) return '?';
    final parts = txt.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
