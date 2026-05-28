import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../auth/auth_service.dart';

const _boxName = 'sip_sleep_box';
const _waterGoalKey = 'waterGoal'; // ex: 8
const _sleepGoalKey = 'sleepGoal'; // ex: 8

class GoalsState {
  final int waterGoal;
  final int sleepGoal;

  const GoalsState({required this.waterGoal, required this.sleepGoal});

  GoalsState copyWith({int? waterGoal, int? sleepGoal}) {
    return GoalsState(
      waterGoal: waterGoal ?? this.waterGoal,
      sleepGoal: sleepGoal ?? this.sleepGoal,
    );
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  return GoalsNotifier();
});

class GoalsNotifier extends StateNotifier<GoalsState> {
  String? _sessionTag;

  GoalsNotifier() : super(const GoalsState(waterGoal: 8, sleepGoal: 8)) {
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

  String _waterGoalKeyFor(String tag) => '$_waterGoalKey::$tag';
  String _sleepGoalKeyFor(String tag) => '$_sleepGoalKey::$tag';

  Future<Box> _ensureProfile(Box box) async {
    final tag = await _currentTag();
    if (_sessionTag != tag) {
      _sessionTag = tag;
      final wg = (box.get(_waterGoalKeyFor(tag), defaultValue: 8) as int);
      final sg = (box.get(_sleepGoalKeyFor(tag), defaultValue: 8) as int);
      state = GoalsState(waterGoal: wg, sleepGoal: sg);
    }
    return box;
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    await _ensureProfile(box);
  }

  Future<void> ensureProfile() async {
    await _ensureProfile(await Hive.openBox(_boxName));
  }

  Future<void> setWaterGoal(int value) async {
    final box = await _ensureProfile(await Hive.openBox(_boxName));
    state = state.copyWith(waterGoal: value);
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_waterGoalKeyFor(tag), value);
  }

  Future<void> setSleepGoal(int value) async {
    final box = await _ensureProfile(await Hive.openBox(_boxName));
    state = state.copyWith(sleepGoal: value);
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_sleepGoalKeyFor(tag), value);
  }
}
