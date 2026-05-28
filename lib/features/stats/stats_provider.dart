import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/hydration_provider.dart';
import '../home/sleep_provider.dart';
import 'history_service.dart';

class StatsPoint {
  final String day;
  final int value;

  const StatsPoint({required this.day, required this.value});
}

class StatsState {
  final List<int> water;
  final List<int> sleep;
  final List<String> labels;
  final List<StatsPoint> waterData;
  final List<StatsPoint> sleepData;

  const StatsState({
    required this.water,
    required this.sleep,
    required this.labels,
    required this.waterData,
    required this.sleepData,
  });

  double get avgWater =>
      waterData.isEmpty ? 0 : waterData.map((e) => e.value).reduce((a, b) => a + b) / waterData.length;

  double get avgSleep =>
      sleepData.isEmpty ? 0 : sleepData.map((e) => e.value).reduce((a, b) => a + b) / sleepData.length;
}

final statsByDaysProvider = FutureProvider.family<StatsState, int>((ref, days) async {
  ref.watch(hydrationProvider);
  ref.watch(sleepProvider);

  final keys = HistoryService.lastKeys(days);
  final water = await HistoryService.lastWater(days);
  final sleep = await HistoryService.lastSleep(days);
  final labels = keys.map(_shortFrDay).toList();
  final waterData = <StatsPoint>[];
  final sleepData = <StatsPoint>[];

  for (var i = 0; i < keys.length; i++) {
    final label = _shortFrDay(keys[i]);
    final w = water[i];
    final s = sleep[i];
    if (w > 0) {
      waterData.add(StatsPoint(day: label, value: w));
    }
    if (s > 0) {
      sleepData.add(StatsPoint(day: label, value: s));
    }
  }

  return StatsState(
    water: water,
    sleep: sleep,
    labels: labels,
    waterData: waterData,
    sleepData: sleepData,
  );
});

final statsProvider = FutureProvider<StatsState>((ref) async {
  return ref.watch(statsByDaysProvider(7).future);
});

String _shortFrDay(String key) {
  const wd = ['lun', 'mar', 'mer', 'jeu', 'ven', 'sam', 'dim'];
  final d = DateTime.parse(key);
  return '${wd[d.weekday - 1]}. ${d.day}';
}
