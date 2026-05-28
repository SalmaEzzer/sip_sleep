import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../auth/auth_service.dart';
import '../stats/history_service.dart';

const _boxName = 'sip_sleep_box';
const _waterKey = 'waterCount'; // verres aujourd'hui (ex: 0..objectif)
const _waterDayKey = 'waterCountDay'; // YYYY-MM-DD

final hydrationProvider =
    StateNotifierProvider<HydrationNotifier, int>((ref) {
  return HydrationNotifier();
});

class HydrationNotifier extends StateNotifier<int> {
  String? _sessionTag;

  HydrationNotifier() : super(0) {
    _load();
  }

  String _tagFromEmail(String? email) {
    final raw = (email ?? 'guest').trim().toLowerCase();
    return raw.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  String _waterKeyFor(String tag) => '$_waterKey::$tag';
  String _waterDayKeyFor(String tag) => '$_waterDayKey::$tag';

  Future<String> _currentTag() async {
    final email = await AuthService.sessionEmail();
    return _tagFromEmail(email);
  }

  Future<void> _loadProfile(Box box, String tag) async {
    final today = HistoryService.todayKey();
    final countKey = _waterKeyFor(tag);
    final dayKey = _waterDayKeyFor(tag);
    final savedDay = box.get(dayKey) as String?;
    if (savedDay != today) {
      state = 0;
      await box.put(countKey, 0);
      await box.put(dayKey, today);
      return;
    }
    state = (box.get(countKey, defaultValue: 0) as int);
  }

  Future<Box> _ensureProfile(Box box) async {
    final tag = await _currentTag();
    if (_sessionTag != tag) {
      _sessionTag = tag;
      await _loadProfile(box, tag);
    }
    return box;
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    await _ensureProfile(box);
  }

  Future<Box> _ensureToday(Box box) async {
    await _ensureProfile(box);
    final tag = _sessionTag ?? await _currentTag();
    final today = HistoryService.todayKey();
    final countKey = _waterKeyFor(tag);
    final dayKey = _waterDayKeyFor(tag);
    final savedDay = box.get(dayKey) as String?;
    if (savedDay != today) {
      state = 0;
      await box.put(countKey, 0);
      await box.put(dayKey, today);
    }
    return box;
  }

  Future<void> ensureToday() async {
    await _ensureToday(await Hive.openBox(_boxName));
  }

  Future<void> addGlass() async {
    final box = await _ensureToday(await Hive.openBox(_boxName));
    state = state + 1;
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_waterKeyFor(tag), state);
    await HistoryService.saveTodayWater(state);
  }

  Future<void> removeGlass() async {
    final box = await _ensureToday(await Hive.openBox(_boxName));
    if (state == 0) return;
    state = state - 1;
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_waterKeyFor(tag), state);
    await HistoryService.saveTodayWater(state);
  }

  Future<void> reset() async {
    final box = await _ensureToday(await Hive.openBox(_boxName));
    state = 0;
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_waterKeyFor(tag), state);
    await HistoryService.saveTodayWater(state);
  }
}
