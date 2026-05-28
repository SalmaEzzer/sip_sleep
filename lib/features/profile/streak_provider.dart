import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../stats/history_service.dart';

const _boxName = 'sip_sleep_box';
const _lastCompletedDayKey = 'lastCompletedDay';
const _streakKey = 'streak';

final streakProvider = StateNotifierProvider<StreakNotifier, int>((ref) {
  return StreakNotifier();
});

class StreakNotifier extends StateNotifier<int> {
  StreakNotifier() : super(0) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    state = (box.get(_streakKey, defaultValue: 0) as int);
  }

  /// Appeler quand l'utilisateur atteint un objectif (eau ou sommeil).
  Future<void> markCompletedToday() async {
    final box = await Hive.openBox(_boxName);

    final today = HistoryService.todayKey();
    final last = box.get(_lastCompletedDayKey) as String?;

    if (last == today) {
      // déjà compté aujourd'hui
      return;
    }

    if (last == null) {
      state = 1;
    } else {
      // comparer date
      final lastDate = DateTime.parse(last);
      final todayDate = DateTime.parse(today);
      final diff = todayDate.difference(lastDate).inDays;

      if (diff == 1) {
        state = state + 1; // streak continue
      } else {
        state = 1; // streak reset
      }
    }

    await box.put(_lastCompletedDayKey, today);
    await box.put(_streakKey, state);
  }
}