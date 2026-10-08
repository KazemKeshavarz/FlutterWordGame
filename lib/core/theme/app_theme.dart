import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF286F93);
  static const dark = Color(0xFF102A35);
  static const background = Color(0xFFF5F7F8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: dark,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      );
}
