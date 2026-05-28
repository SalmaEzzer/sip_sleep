import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/notifications/notifications_service.dart';

const _boxName = 'sip_sleep_box';

class ReminderState {
  final bool enabled;
  final int hour;
  final int minute;

  ReminderState({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  ReminderState copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderState(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final int id;
  final String title;
  final String body;

  final String _enabledKey;
  final String _hourKey;
  final String _minuteKey;

  ReminderNotifier({
    required this.id,
    required this.title,
    required this.body,
    required bool defaultEnabled,
    required int defaultHour,
    required int defaultMinute,
    required String enabledKey,
    required String hourKey,
    required String minuteKey,
  })  : _enabledKey = enabledKey,
        _hourKey = hourKey,
        _minuteKey = minuteKey,
        super(ReminderState(
          enabled: defaultEnabled,
          hour: defaultHour,
          minute: defaultMinute,
        )) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    final e = box.get(_enabledKey, defaultValue: state.enabled) as bool;
    final h = box.get(_hourKey, defaultValue: state.hour) as int;
    final m = box.get(_minuteKey, defaultValue: state.minute) as int;
    state = state.copyWith(enabled: e, hour: h, minute: m);

    if (state.enabled) {
      await _schedule();
    }
  }

  Future<void> _save() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_enabledKey, state.enabled);
    await box.put(_hourKey, state.hour);
    await box.put(_minuteKey, state.minute);
  }

  Future<void> setEnabled(bool v) async {
    state = state.copyWith(enabled: v);
    await _save();
    if (v) {
      await _schedule();
    } else {
      await NotificationsService.cancel(id);
    }
  }

  Future<void> setTime(int h, int m) async {
    state = state.copyWith(hour: h, minute: m);
    await _save();
    if (state.enabled) {
      await _schedule();
    }
  }

  Future<void> _schedule() async {
    await NotificationsService.scheduleDaily(
      id: id,
      title: title,
      body: body,
      hour: state.hour,
      minute: state.minute,
    );
  }
}

final waterReminderProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier(
    id: 101,
    title: '💧 Sip & Sleep - Hydratation',
    body: 'N\'oublie pas de boire un verre d\'eau !',
    defaultEnabled: false,
    defaultHour: 10,
    defaultMinute: 0,
    enabledKey: 'waterReminderEnabled',
    hourKey: 'waterReminderHour',
    minuteKey: 'waterReminderMinute',
  );
});

final sleepReminderProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier(
    id: 202,
    title: '🌙 Sip & Sleep - Sommeil',
    body: 'Prépare-toi à dormir pour bien récupérer 😴',
    defaultEnabled: false,
    defaultHour: 22,
    defaultMinute: 30,
    enabledKey: 'sleepReminderEnabled',
    hourKey: 'sleepReminderHour',
    minuteKey: 'sleepReminderMinute',
  );
});
