import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../auth/auth_service.dart';
import '../stats/history_service.dart';

const _boxName = 'sip_sleep_box';
const _sleepKey = 'sleepHours'; // heures (ex: 0..12)
const _sleepDayKey = 'sleepHoursDay'; // YYYY-MM-DD

final sleepProvider = StateNotifierProvider<SleepNotifier, int>((ref) {
  return SleepNotifier();
});

class SleepNotifier extends StateNotifier<int> {
  String? _sessionTag;

  SleepNotifier() : super(0) {
    _load();
  }

  String _tagFromEmail(String? email) {
    final raw = (email ?? 'guest').trim().toLowerCase();
    return raw.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  String _sleepKeyFor(String tag) => '$_sleepKey::$tag';
  String _sleepDayKeyFor(String tag) => '$_sleepDayKey::$tag';

  Future<String> _currentTag() async {
    final email = await AuthService.sessionEmail();
    return _tagFromEmail(email);
  }

  Future<void> _loadProfile(Box box, String tag) async {
    final today = HistoryService.todayKey();
    final countKey = _sleepKeyFor(tag);
    final dayKey = _sleepDayKeyFor(tag);
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
    final countKey = _sleepKeyFor(tag);
    final dayKey = _sleepDayKeyFor(tag);
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

  Future<void> addHour() async {
    final box = await _ensureToday(await Hive.openBox(_boxName));
    state = state + 1;
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_sleepKeyFor(tag), state);
    await HistoryService.saveTodaySleep(state);
  }

  Future<void> removeHour() async {
    final box = await _ensureToday(await Hive.openBox(_boxName));
    if (state == 0) return;
    state = state - 1;
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_sleepKeyFor(tag), state);
    await HistoryService.saveTodaySleep(state);
  }

  Future<void> setHours(int hours) async {
    final box = await _ensureToday(await Hive.openBox(_boxName));
    state = hours;
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_sleepKeyFor(tag), state);
    await HistoryService.saveTodaySleep(state);
  }

  Future<void> reset() async {
    final box = await _ensureToday(await Hive.openBox(_boxName));
    state = 0;
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_sleepKeyFor(tag), state);
    await HistoryService.saveTodaySleep(state);
  }
}
