import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFF3F4F6);
  static const orange = Color(0xFFE07A3D);
  static const orangeDeep = Color(0xFFC65E22);
  static const cream = Color(0xFFF6E6CC);
  static const ink = Color(0xFF1C1C1E);
  static const muted = Color(0xFF8E8E93);
  static const line = Color(0xFFE7E7EB);
  static const danger = Color(0xFFE23D3D);
  static const track = Color(0xFFECEDEF);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      surface: Colors.white,
    ),
  );
  final font = GoogleFonts.plusJakartaSans().fontFamily;
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: font,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
    ),
  );
}
