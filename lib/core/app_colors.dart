import 'package:flutter/material.dart';

/// Brand palette sampled from the reference screenshots
/// (light: white + deep navy, dark: near-black navy + indigo).
/// To re-skin the app (e.g. black + red) change only the two constants below.
class AppColors {
  const AppColors({
    required this.isDark,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.searchFill,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.pin,
    required this.outline,
    required this.chip,
    required this.halo,
    required this.navActive,
    required this.buttonColors,
    required this.shadow,
  });

  final bool isDark;
  final Color bg, surface, surfaceAlt, searchFill, text, textMuted;
  final Color accent, onAccent, pin, outline, chip, halo, navActive;
  final List<Color> buttonColors;
  final List<BoxShadow> shadow;

  static const light = AppColors(
    isDark: false,
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F2F8),
    searchFill: Color(0xFFECEDF4),
    text: Color(0xFF0B1630),
    textMuted: Color(0xFF626A7E),
    accent: Color(0xFF0B1630),
    onAccent: Colors.white,
    pin: Color(0xFF0B1630),
    outline: Color(0xFFE7E9F1),
    chip: Colors.white,
    halo: Color(0xFF4F8BFF),
    navActive: Color(0xFF0B1630),
    buttonColors: [Color(0xFF0B1630), Color(0xFF0B1630)],
    shadow: [BoxShadow(color: Color(0x1A101A3A), blurRadius: 24, offset: Offset(0, 8))],
  );

  static const dark = AppColors(
    isDark: true,
    bg: Color(0xFF0A0B17),
    surface: Color(0xFF181925),
    surfaceAlt: Color(0xFF22232F),
    searchFill: Color(0xFF1B1C28),
    text: Colors.white,
    textMuted: Color(0xFFA3A6BA),
    accent: Color(0xFF5B4BF0),
    onAccent: Colors.white,
    pin: Color(0xFF6D4AFF),
    outline: Color(0xFF2A2B3A),
    chip: Color(0xFF22232F),
    halo: Color(0xFF4F46E5),
    navActive: Color(0xFF7A5CFF),
    buttonColors: [Color(0xFF3B30D6), Color(0xFF5B4BF0)],
    shadow: [],
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
