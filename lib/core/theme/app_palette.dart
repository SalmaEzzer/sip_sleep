import 'package:flutter/material.dart';

class AppPalette {
  static const background = Color(0xFFF2F5FA);
  static const card = Color(0xFFF8FAFD);
  static const textPrimary = Color(0xFF0A1733);
  static const textMuted = Color(0xFF74819A);
  static const water = Color(0xFF3E9FDE);
  static const sleep = Color(0xFF8667D8);
  static const success = Color(0xFF34A293);
  static const danger = Color(0xFFE76A54);

  static const headerGradient = LinearGradient(
    colors: [Color(0xFFD2E7F5), Color(0xFFDFE4F9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SoftShadow {
  static List<BoxShadow> card(Color tint) => [
        BoxShadow(
          color: tint.withOpacity(0.14),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}
