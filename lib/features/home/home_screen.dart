import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_palette.dart';
import '../auth/auth_provider.dart';
import '../profile/goals_provider.dart';
import '../stats/stats_provider.dart';
import 'hydration_provider.dart';
import 'sleep_log_provider.dart';
import 'sleep_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final water = ref.watch(hydrationProvider);
    final sleep = ref.watch(sleepProvider);
    final goals = ref.watch(goalsProvider);
    final stats = ref.watch(statsProvider);
    final auth = ref.watch(authProvider).value;
    final sleepLogged = ref.watch(sleepLoggedProvider);

    final waterGoal = goals.waterGoal;
    final sleepGoal = goals.sleepGoal;
    final name = (auth?['name']?.toString().trim().isNotEmpty ?? false)
        ? auth!['name'].toString().trim()
        : 'Aya';

    final todayFr = _todayFrenchLabel();
    final greeting = _greeting();
    final sleepStatus = _sleepStatus(sleep, sleepGoal);
    Future.microtask(() async {
      await ref.read(goalsProvider.notifier).ensureProfile();
      await ref.read(hydrationProvider.notifier).ensureToday();
      await ref.read(sleepProvider.notifier).ensureToday();
      await ref.read(sleepLoggedProvider.notifier).ensureToday();
    });

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
          children: [
            _HeaderCard(
              icon: LucideIcons.house,
              title: '${greeting.text}, $name ${greeting.emoji}',
              subtitle: todayFr,
            ),
            const SizedBox(height: 16),
            _TrackerCard(
              color: AppPalette.water,
              icon: LucideIcons.droplets,
              title: 'Hydratation',
              subtitle: 'Objectif : $waterGoal verres',
              valueText: '$water',
              unitText: '/ $waterGoal verres',
              progress: (waterGoal == 0) ? 0 : (water / waterGoal).clamp(0, 1),
              cheerText: _hydrationCheer(water, waterGoal),
              trail: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: List.generate(
                  waterGoal <= 0 ? 0 : waterGoal,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      LucideIcons.droplets,
                      size: 15,
                      color: i < water ? AppPalette.water : AppPalette.water.withOpacity(0.25),
                    ),
                  ),
                ),
              ),
              onMinus: () => ref.read(hydrationProvider.notifier).removeGlass(),
              onPlus: () => ref.read(hydrationProvider.notifier).addGlass(),
            ),
            const SizedBox(height: 16),
            _TrackerCard(
              color: AppPalette.sleep,
              icon: LucideIcons.moon,
              title: 'Sommeil',
              subtitle: 'Objectif : ${sleepGoal}h par nuit',
              valueText: '${sleep}h',
              unitText: sleepStatus.label,
              unitColor: sleepStatus.color,
              progress: (sleepGoal == 0) ? 0 : (sleep / sleepGoal).clamp(0, 1),
              cheerText: '',
              trail: sleepLogged
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 18, color: AppPalette.success),
                          SizedBox(width: 8),
                          Text(
                            'Enregistré pour cette nuit',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8A73DE), Color(0xFF5A72DA)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: SoftShadow.card(AppPalette.sleep),
                        ),
                        child: ElevatedButton(
                          onPressed: () => ref.read(sleepLoggedProvider.notifier).logForTonight(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Enregistrer le sommeil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
              actionValueText: '${sleep}h',
              actionsBeforeTrail: true,
              onMinus: () {
                ref.read(sleepProvider.notifier).removeHour();
                ref.read(sleepLoggedProvider.notifier).unlogForTonight();
              },
              onPlus: () {
                ref.read(sleepProvider.notifier).addHour();
                ref.read(sleepLoggedProvider.notifier).unlogForTonight();
              },
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppPalette.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: SoftShadow.card(Colors.grey),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cette semaine',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MiniBarChart(
                    title: 'Eau (verres/jour)',
                    values: stats.value?.water ?? const [0, 0, 0, 0, 0, 0, 0],
                    labels: _homeWeekLabels(stats.value?.labels),
                    color: AppPalette.water,
                    max: math.max(4, goals.waterGoal.toDouble()),
                  ),
                  const SizedBox(height: 16),
                  _MiniBarChart(
                    title: 'Sommeil (heures/nuit)',
                    values: stats.value?.sleep ?? const [0, 0, 0, 0, 0, 0, 0],
                    labels: _homeWeekLabels(stats.value?.labels),
                    color: AppPalette.sleep,
                    max: math.max(8, goals.sleepGoal.toDouble()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

({String text, String emoji}) _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return (text: 'Bonjour', emoji: '☀️');
  if (h < 18) return (text: 'Bon après-midi', emoji: '🌤️');
  return (text: 'Bonsoir', emoji: '🌙');
}

String _todayFrenchLabel() {
  const weekdays = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  final now = DateTime.now();
  return '${weekdays[now.weekday - 1]} ${now.day} ${months[now.month - 1]}';
}

String _hydrationCheer(int water, int goal) {
  if (goal <= 0) return 'C\'est parti ! 🌞';
  if (water <= 0) return 'C\'est parti ! 🌞';
  if (water >= goal) return 'Objectif atteint ! 🎉';

  final ratio = water / goal;
  if (ratio >= 0.75) return 'Presque là ! 💪';
  if (ratio >= 0.5) return 'Continue comme ça 💧';
  return 'Bon début ! 🌊';
}

({String label, Color color}) _sleepStatus(int sleep, int goal) {
  if (sleep <= 0) return (label: 'Insuffisant', color: const Color(0xFFFF6A60));
  if (goal <= 0) return (label: 'Correct', color: AppPalette.water);
  final ratio = sleep / goal;
  if (ratio >= 0.75) return (label: 'Excellent', color: AppPalette.success);
  return (label: 'Correct', color: AppPalette.water);
}

List<String> _homeWeekLabels(List<String>? source) {
  if (source == null || source.isEmpty) {
    return const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  }
  return source.map((raw) {
    final token = raw.split(' ').first.replaceAll('.', '').toLowerCase();
    if (token.length < 3) return raw;
    final short = token.substring(0, 3);
    return '${short[0].toUpperCase()}${short.substring(1)}';
  }).toList();
}

class _HeaderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Icon(icon, color: AppPalette.water),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String valueText;
  final String unitText;
  final Color unitColor;
  final double progress;
  final String cheerText;
  final Widget trail;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String? actionValueText;
  final bool actionsBeforeTrail;

  const _TrackerCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.unitText,
    this.unitColor = AppPalette.textMuted,
    required this.progress,
    required this.cheerText,
    required this.trail,
    required this.onMinus,
    required this.onPlus,
    this.actionValueText,
    this.actionsBeforeTrail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: SoftShadow.card(color),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 17, color: AppPalette.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RingProgress(
            color: color,
            progress: progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  valueText,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  unitText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: unitColor,
                  ),
                ),
              ],
            ),
          ),
          if (cheerText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cheerText,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 12),
          if (actionsBeforeTrail) _actionsRow(),
          if (actionsBeforeTrail) const SizedBox(height: 14),
          trail,
          if (!actionsBeforeTrail) const SizedBox(height: 14),
          if (!actionsBeforeTrail) _actionsRow(),
        ],
      ),
    );
  }

  Widget _actionsRow() {
    return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionBtn(icon: Icons.remove, active: false, onTap: onMinus),
              if (actionValueText != null) ...[
                const SizedBox(width: 20),
                Text(
                  actionValueText!,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textPrimary,
                  ),
                ),
                const SizedBox(width: 20),
              ] else
                const SizedBox(width: 14),
              _ActionBtn(icon: Icons.add, active: true, color: color, onTap: onPlus),
            ],
          );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    this.color = AppPalette.water,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? color : const Color(0xFFE7ECF2),
          foregroundColor: active ? Colors.white : AppPalette.textMuted,
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Icon(icon, size: 30),
      ),
    );
  }
}

class _RingProgress extends StatelessWidget {
  final Color color;
  final double progress;
  final Widget center;

  const _RingProgress({
    required this.color,
    required this.progress,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: CustomPaint(
        painter: _ArcPainter(color: color, progress: progress),
        child: Center(child: center),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double progress;

  _ArcPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    final base = Paint()
      ..color = const Color(0xFFE6EAF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    final active = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _MiniBarChart extends StatelessWidget {
  final String title;
  final List<int> values;
  final List<String> labels;
  final Color color;
  final double max;

  const _MiniBarChart({
    required this.title,
    required this.values,
    required this.labels,
    required this.color,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final days = labels.length == values.length
        ? labels
        : const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              title.contains('Sommeil') ? LucideIcons.moon : LucideIcons.droplets,
              color: color,
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: AppPalette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: const Color(0xFFD8DDE5),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (i) {
              final v = i < values.length ? values[i].toDouble() : 0;
              final h = ((v / max).clamp(0.04, 1.0)) * 52;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        color: i == 6 ? color : color.withOpacity(0.22),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: days
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(d, style: const TextStyle(fontSize: 13, color: AppPalette.textMuted)),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
