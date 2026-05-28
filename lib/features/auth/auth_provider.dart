import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

typedef UserMap = Map<String, dynamic>;

final authProvider =
    AsyncNotifierProvider<AuthController, UserMap?>(AuthController.new);

class AuthController extends AsyncNotifier<UserMap?> {
  @override
  Future<UserMap?> build() async {
    return AuthService.currentUser();
  }

  Future<void> signup(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AuthService.signup(name: name, email: email, password: password);
      return AuthService.currentUser();
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AuthService.login(email: email, password: password);
      return AuthService.currentUser();
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AuthService.logout();
      return null;
    });
  }

  Future<void> updateDisplayName(String displayName) async {
    await AuthService.updateDisplayName(displayName);
    final refreshed = await AuthService.currentUser();
    state = AsyncData(refreshed);
  }

  Future<void> continueWithoutAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await AuthService.loginAnonymously();
      return AuthService.currentUser();
    });
  }
}
