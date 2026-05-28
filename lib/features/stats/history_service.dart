import 'package:hive_flutter/hive_flutter.dart';
import '../auth/auth_service.dart';

class HistoryService {
  static const String boxName = 'sip_sleep_box';
  static const String waterMapKey = 'waterByDay'; // Map<String, int>
  static const String sleepMapKey = 'sleepByDay'; // Map<String, int>

  static String _dayKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  static String todayKey() => _dayKey(DateTime.now());

  static List<String> lastKeys(int days) {
    final now = DateTime.now();
    return List.generate(days, (i) {
      final d = now.subtract(Duration(days: days - 1 - i));
      return _dayKey(d);
    });
  }

  static List<String> last7Keys() => lastKeys(7);

  static Future<Map<String, int>> _getMap(String key) async {
    final box = await Hive.openBox(boxName);
    final raw = box.get(key);
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return <String, int>{};
  }

  static String _userBucket(String? email) {
    final raw = (email ?? 'guest').trim().toLowerCase();
    return raw.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  static Future<String> _scopedKey(String base) async {
    final email = await AuthService.sessionEmail();
    return '$base::${_userBucket(email)}';
  }

  static Future<void> _putMap(String key, Map<String, int> map) async {
    final box = await Hive.openBox(boxName);
    await box.put(key, map);
  }

  static Future<void> saveTodayWater(int value) async {
    final map = await _getMap(await _scopedKey(waterMapKey));
    map[todayKey()] = value;
    await _putMap(await _scopedKey(waterMapKey), map);
  }

  static Future<void> saveTodaySleep(int value) async {
    final map = await _getMap(await _scopedKey(sleepMapKey));
    map[todayKey()] = value;
    await _putMap(await _scopedKey(sleepMapKey), map);
  }

  static Future<List<int>> lastWater(int days) async {
    final map = await _getMap(await _scopedKey(waterMapKey));
    final keys = lastKeys(days);
    return keys.map((k) => map[k] ?? 0).toList();
  }

  static Future<List<int>> lastSleep(int days) async {
    final map = await _getMap(await _scopedKey(sleepMapKey));
    final keys = lastKeys(days);
    return keys.map((k) => map[k] ?? 0).toList();
  }

  static Future<List<int>> last7Water() => lastWater(7);

  static Future<List<int>> last7Sleep() => lastSleep(7);
}
