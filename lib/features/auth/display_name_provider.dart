import 'package:flutter_riverpod/flutter_riverpod.dart';

final displayNameProvider = StateProvider<String>((ref) {
  return 'Utilisateur';
});
