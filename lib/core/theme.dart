import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness).copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      surface: c.surface,
      onSurface: c.text,
      outline: c.outline,
    ),
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(bodyColor: c.text, displayColor: c.text),
    dividerColor: c.outline,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceAlt,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: TextStyle(color: c.textMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(shape: const StadiumBorder(), side: BorderSide(color: c.outline)),
  );
}
