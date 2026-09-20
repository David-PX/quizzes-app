import 'package:flutter/material.dart';

class AppTheme {
  static const purple = Color(0xFF673AB7);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: purple,
      brightness: Brightness.light,
    ).copyWith(primary: purple, onPrimary: Colors.white);

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8F4FC),
      appBarTheme: const AppBarTheme(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
