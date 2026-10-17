import 'package:flutter/material.dart';

// Palet warna HydroMate (lihat PROJECT_CONTEXT.md)
class AppColors {
  static const primary = Color(0xFF1E6FE0);
  static const secondary = Color(0xFF35C9D6);
  static const background = Color(0xFFF5F9FF);
  static const teks = Color(0xFF12263F);
}

// Tema Material 3 untuk seluruh aplikasi
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.background,
    onSurface: AppColors.teks,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.teks,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.secondary.withValues(alpha: 0.3),
    ),
  );
}
