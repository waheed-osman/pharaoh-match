import 'package:flutter/material.dart';

/// ألوان مستوحاة من مصر القديمة: الذهب، اللازورد، الفيروز، العقيق، والرمال.
class Pal {
  static const night = Color(0xFF0B1D3A);
  static const night2 = Color(0xFF14305C);
  static const gold = Color(0xFFD4AF37);
  static const goldLight = Color(0xFFF3D77A);
  static const sand = Color(0xFFE8D5A3);
  static const turquoise = Color(0xFF1FA89A);
  static const carnelian = Color(0xFFB5412B);
  static const lapis = Color(0xFF26509E);
  static const ink = Color(0xFF2A1A05);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Pal.gold,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Pal.night,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Pal.gold,
        foregroundColor: Pal.ink,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pal.goldLight,
        side: const BorderSide(color: Pal.gold, width: 1.5),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
    ),
  );
}
