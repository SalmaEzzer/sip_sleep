import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  static const _box = 'sip_sleep_auth';
  static const _usersKey = 'users'; // Map<String email, Map user>
  static const _sessionKey = 'session_email';

  static Future<Box> _open() => Hive.openBox(_box);

  static Future<Map<String, dynamic>> _users(Box box) async {
    final raw = box.get(_usersKey, defaultValue: <String, dynamic>{});
    return Map<String, dynamic>.from(raw);
  }

  static Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final box = await _open();
    final users = await _users(box);

    final e = email.trim().toLowerCase();
    if (users.containsKey(e)) {
      throw Exception('Ce compte existe déjà');
    }

    users[e] = {
      'name': name.trim(),
      'email': e,
      'password': password, // local demo
      'createdAt': DateTime.now().toIso8601String(),
    };

    await box.put(_usersKey, users);
    await box.put(_sessionKey, e); // auto-login après inscription
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final box = await _open();
    final users = await _users(box);

    final e = email.trim().toLowerCase();
    if (!users.containsKey(e)) {
      throw Exception('Email introuvable');
    }

    final user = Map<String, dynamic>.from(users[e]);
    if (user['password'] != password) {
      throw Exception('Mot de passe incorrect');
    }

    await box.put(_sessionKey, e);
  }

  static Future<void> logout() async {
    final box = await _open();
    await box.delete(_sessionKey);
  }

  static Future<void> loginAnonymously() async {
    final box = await _open();
    final users = await _users(box);
    final key = 'guest_${DateTime.now().millisecondsSinceEpoch}@guest.local';
    users[key] = {
      'name': 'Invité',
      'email': key,
      'password': '',
      'anonymous': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await box.put(_usersKey, users);
    await box.put(_sessionKey, key);
  }

  static Future<Map<String, dynamic>?> currentUser() async {
    final box = await _open();
    final sessionEmail = box.get(_sessionKey);
    if (sessionEmail == null) return null;

    final users = await _users(box);
    if (!users.containsKey(sessionEmail)) return null;

    return Map<String, dynamic>.from(users[sessionEmail]);
  }

  static Future<String?> sessionEmail() async {
    final box = await _open();
    return box.get(_sessionKey);
  }

  static Future<void> updateDisplayName(String displayName) async {
    final box = await _open();
    final sessionEmail = box.get(_sessionKey);
    if (sessionEmail == null) return;

    final users = await _users(box);
    if (!users.containsKey(sessionEmail)) return;

    final user = Map<String, dynamic>.from(users[sessionEmail]);
    user['name'] = displayName.trim();
    users[sessionEmail] = user;
    await box.put(_usersKey, users);
  }
}
