import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/notifications/notifications_service.dart';
import '../auth/auth_service.dart';

const _boxName = 'sip_sleep_box';
const _customRemindersKey = 'customReminders';

class CustomReminder {
  final String id;
  final String title;
  final String description;
  final int hour;
  final int minute;
  final bool enabled;
  final String color;

  CustomReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.hour,
    required this.minute,
    required this.enabled,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
      'color': color,
    };
  }

  factory CustomReminder.fromMap(Map<String, dynamic> map) {
    return CustomReminder(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      enabled: map['enabled'] as bool,
      color: map['color'] as String,
    );
  }

  CustomReminder copyWith({
    String? id,
    String? title,
    String? description,
    int? hour,
    int? minute,
    bool? enabled,
    String? color,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
      color: color ?? this.color,
    );
  }
}

class CustomRemindersNotifier extends StateNotifier<List<CustomReminder>> {
  String? _sessionTag;

  CustomRemindersNotifier() : super([]) {
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

  String _customRemindersKeyFor(String tag) => '$_customRemindersKey::$tag';

  Future<Box> _ensureProfile(Box box) async {
    final tag = await _currentTag();
    if (_sessionTag != tag) {
      _sessionTag = tag;
      final data = box.get(_customRemindersKeyFor(tag), defaultValue: []) as List;
      state = data
          .map((item) => CustomReminder.fromMap(Map<String, dynamic>.from(item)))
          .toList();
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

  Future<void> _save() async {
    final box = await _ensureProfile(await Hive.openBox(_boxName));
    final tag = _sessionTag ?? await _currentTag();
    await box.put(_customRemindersKeyFor(tag), state.map((r) => r.toMap()).toList());
  }

  Future<void> addReminder(
    String title,
    String description,
    int hour,
    int minute,
    String color,
  ) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final reminder = CustomReminder(
      id: id,
      title: title,
      description: description,
      hour: hour,
      minute: minute,
      enabled: false,
      color: color,
    );
    state = [...state, reminder];
    await _save();
  }

  Future<void> removeReminder(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _save();
    // cancel notification if scheduled
    await NotificationsService.cancel(id.hashCode.abs());
  }

  Future<void> setEnabled(String id, bool enabled) async {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(enabled: enabled);
      }
      return r;
    }).toList();
    await _save();

    // find the reminder and schedule/cancel notification
    final reminder = state.firstWhere((r) => r.id == id);
    if (enabled) {
      await NotificationsService.scheduleDaily(
        id: id.hashCode.abs(),
        title: reminder.title,
        body: reminder.description,
        hour: reminder.hour,
        minute: reminder.minute,
      );
    } else {
      await NotificationsService.cancel(id.hashCode.abs());
    }
  }

  Future<void> setTime(String id, int hour, int minute) async {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(hour: hour, minute: minute);
      }
      return r;
    }).toList();
    await _save();

    // reschedule if enabled
    final reminder = state.firstWhere((r) => r.id == id);
    if (reminder.enabled) {
      await NotificationsService.scheduleDaily(
        id: id.hashCode.abs(),
        title: reminder.title,
        body: reminder.description,
        hour: hour,
        minute: minute,
      );
    }
  }
}

final customRemindersProvider =
    StateNotifierProvider<CustomRemindersNotifier, List<CustomReminder>>((ref) {
  return CustomRemindersNotifier();
});
