import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:sip_sleep/features/auth/auth_service.dart';
import 'package:sip_sleep/features/home/hydration_provider.dart';
import 'package:sip_sleep/features/home/sleep_log_provider.dart';
import 'package:sip_sleep/features/stats/history_service.dart';

String _tagFromEmail(String? email) {
  final raw = (email ?? 'guest').trim().toLowerCase();
  return raw.replaceAll(RegExp(r'[^a-z0-9]'), '_');
}

String _yyyyMmDd(DateTime d) {
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sip_sleep_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('signup puis login fonctionnent', () async {
    await AuthService.signup(name: 'Aya', email: 'aya@test.com', password: '123456');
    await AuthService.logout();
    await AuthService.login(email: 'aya@test.com', password: '123456');
    final user = await AuthService.currentUser();
    expect(user?['email'], 'aya@test.com');
  });

  test('les données sont isolées par utilisateur', () async {
    await AuthService.signup(name: 'User1', email: 'u1@test.com', password: '123456');
    final hydration1 = HydrationNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await hydration1.addGlass();
    await hydration1.addGlass();
    expect((await HistoryService.lastWater(1)).single, 2);

    await AuthService.signup(name: 'User2', email: 'u2@test.com', password: '123456');
    final hydration2 = HydrationNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await hydration2.ensureToday();
    expect(hydration2.state, 0);
    expect((await HistoryService.lastWater(1)).single, 0);

    await AuthService.login(email: 'u1@test.com', password: '123456');
    expect((await HistoryService.lastWater(1)).single, 2);
  });

  test('reset auto après changement de jour sans perdre historique', () async {
    await AuthService.signup(name: 'Aya', email: 'aya@test.com', password: '123456');
    final hydration = HydrationNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await hydration.addGlass();
    await hydration.addGlass();
    expect(hydration.state, 2);

    final box = await Hive.openBox('sip_sleep_box');
    final tag = _tagFromEmail(await AuthService.sessionEmail());
    final yesterday = _yyyyMmDd(DateTime.now().subtract(const Duration(days: 1)));
    await box.put('waterCountDay::$tag', yesterday);

    await hydration.ensureToday();
    expect(hydration.state, 0);
    expect((await HistoryService.lastWater(1)).single, 0);
  });

  test('sommeil enregistré est remis à false le jour suivant', () async {
    await AuthService.signup(name: 'Aya', email: 'aya@test.com', password: '123456');
    final log = SleepLogNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await log.logForTonight();
    expect(log.state, true);

    final box = await Hive.openBox('sip_sleep_box');
    final tag = _tagFromEmail(await AuthService.sessionEmail());
    final yesterday = _yyyyMmDd(DateTime.now().subtract(const Duration(days: 1)));
    await box.put('sleepLoggedDay::$tag', yesterday);

    await log.ensureToday();
    expect(log.state, false);
  });
}

