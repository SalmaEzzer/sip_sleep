import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_palette.dart';
import 'custom_reminders_provider.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool showForm = false;
  bool waterType = true;
  TimeOfDay selected = const TimeOfDay(hour: 9, minute: 0);
  final labelCtrl = TextEditingController();

  @override
  void dispose() {
    labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future.microtask(() => ref.read(customRemindersProvider.notifier).ensureProfile());
    final reminders = ref.watch(customRemindersProvider);

    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 118),
          children: [
            _header(),
            const SizedBox(height: 16),
            if (showForm) _form(),
            if (showForm) const SizedBox(height: 14),
            if (reminders.isEmpty)
              const _EmptyState()
            else
              ...reminders.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReminderTile(
                      reminder: r,
                      onToggle: (v) => ref.read(customRemindersProvider.notifier).setEnabled(r.id, v),
                      onDelete: () => ref.read(customRemindersProvider.notifier).removeReminder(r.id),
                    ),
                  )),
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
            child: const Icon(LucideIcons.bell, color: AppPalette.water),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Rappels',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => showForm = !showForm),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppPalette.water,
                shape: BoxShape.circle,
              ),
              child: Icon(showForm ? Icons.close : Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: SoftShadow.card(AppPalette.water),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nouveau rappel',
            style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _typeChip(
                label: 'Eau',
                icon: LucideIcons.droplets,
                active: waterType,
                color: AppPalette.water,
                onTap: () => setState(() => waterType = true),
              ),
              const SizedBox(width: 8),
              _typeChip(
                label: 'Sommeil',
                icon: LucideIcons.moon,
                active: !waterType,
                color: AppPalette.sleep,
                onTap: () => setState(() => waterType = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: selected);
              if (t != null) setState(() => selected = t);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3F8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD7DFEA)),
              ),
              child: Row(
                children: [
                  Text(
                    _fmt(selected),
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600, color: AppPalette.textPrimary),
                  ),
                  const Spacer(),
                  const Icon(Icons.schedule, color: AppPalette.textPrimary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: labelCtrl,
            decoration: InputDecoration(
              hintText: 'Label (optionnel)',
              filled: true,
              fillColor: const Color(0xFFEFF3F8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                final isWater = waterType;
                await ref.read(customRemindersProvider.notifier).addReminder(
                      isWater ? 'Eau' : 'Sommeil',
                      labelCtrl.text.trim(),
                      selected.hour,
                      selected.minute,
                      isWater ? '0xFF3E9FDE' : '0xFF8667D8',
                    );
                if (!mounted) return;
                labelCtrl.clear();
                setState(() => showForm = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rappel ajouté ✅'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Ajouter le rappel',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color : const Color(0xFFE7ECF2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : AppPalette.textMuted),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ReminderTile extends StatelessWidget {
  final CustomReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(reminder.color));
    final h = reminder.hour.toString().padLeft(2, '0');
    final m = reminder.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SoftShadow.card(color),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Icon(
              reminder.title == 'Sommeil' ? LucideIcons.moon : LucideIcons.droplets,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.schedule, size: 18, color: AppPalette.textMuted),
          const SizedBox(width: 8),
          Text(
            '$h:$m',
            style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
          ),
          const Spacer(),
          Switch(
            value: reminder.enabled,
            onChanged: onToggle,
            activeThumbColor: color,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppPalette.textMuted),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFDDEBEA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.eco_outlined, color: AppPalette.success, size: 42),
          ),
          const SizedBox(height: 16),
          const Text(
            'Restez régulier 🌿',
            style: TextStyle(fontSize: 37, fontWeight: FontWeight.w700, color: AppPalette.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajoutez des rappels pour ne rien oublier',
            style: TextStyle(fontSize: 16, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }
}
