import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../auth/auth_service.dart';
import '../stats/history_service.dart';

const _boxName = 'sip_sleep_box';
const _sleepLoggedDayKey = 'sleepLoggedDay';

final sleepLoggedProvider = StateNotifierProvider<SleepLogNotifier, bool>((ref) {
  return SleepLogNotifier();
});

class SleepLogNotifier extends StateNotifier<bool> {
  String? _sessionTag;

  SleepLogNotifier() : super(false) {
    _load();
  }

  String _tagFromEmail(String? email) {
    final raw = (email ?? 'guest').trim().toLowerCase();
    return raw.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  Future<String> _currentTag() async {
    final email = await AuthService.sessionEmail();
    return _tagFromEmail(email);
  }

  String _loggedDayKeyFor(String tag) => '$_sleepLoggedDayKey::$tag';

  Future<Box> _ensureProfile(Box box) async {
    final tag = await _currentTag();
    if (_sessionTag != tag) {
      _sessionTag = tag;
      final loggedDay = box.get(_loggedDayKeyFor(tag)) as String?;
      state = loggedDay == HistoryService.todayKey();
    }
    return box;
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    await _ensureProfile(box);
  }

  Future<void> logForTonight() async {
    final box = await Hive.openBox(_boxName);
    await _ensureProfile(box);
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_loggedDayKeyFor(tag), HistoryService.todayKey());
    state = true;
  }

  Future<void> unlogForTonight() async {
    final box = await Hive.openBox(_boxName);
    await _ensureProfile(box);
    final tag = _sessionTag ?? await _currentTag();
    await box.delete(_loggedDayKeyFor(tag));
    state = false;
  }

  Future<void> ensureToday() async {
    final box = await Hive.openBox(_boxName);
    await _ensureProfile(box);
    final tag = _sessionTag ?? await _currentTag();
    final loggedDay = box.get(_loggedDayKeyFor(tag)) as String?;
    final today = HistoryService.todayKey();
    if (loggedDay != null && loggedDay != today) {
      await box.delete(_loggedDayKeyFor(tag));
      state = false;
      return;
    }
    state = loggedDay == today;
  }
}
