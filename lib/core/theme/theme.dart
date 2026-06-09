import 'package:flutter/material.dart';

class AppTheme {
  // Light palette
  static const Color _lightPrimary = Color(0xFF2E5BFF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightBackground = Color(0xFFF5F7FA);
  static const Color _lightOnSurface = Color(0xFF0F1E36);
  static const Color _lightOnSurfaceVariant = Color(0xFF6B7280);
  static const Color _lightOutline = Color(0xFFE5E7EB);
  static const Color _lightOutlineVariant = Color(0xFFF0F2F5);

  // Dark palette
  static const Color _darkPrimary = Color(0xFF6B8EFF);
  static const Color _darkSurface = Color(0xFF1A1A1A);
  static const Color _darkBackground = Color(0xFF000000);
  static const Color _darkOnSurface = Color(0xFFEDEDED);
  static const Color _darkOnSurfaceVariant = Color(0xFF888888);
  static const Color _darkOutline = Color(0xFF333333);
  static const Color _darkOutlineVariant = Color(0xFF242424);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        secondary: Color(0xFFFFA000),
        surface: _lightSurface,
        onSurface: _lightOnSurface,
        onSurfaceVariant: _lightOnSurfaceVariant,
        outline: _lightOutline,
        outlineVariant: _lightOutlineVariant,
        error: Color(0xFFD32F2F),
        primaryContainer: Color(0xFFE8EEFF),
        onPrimaryContainer: Color(0xFF0A2580),
        surfaceContainerLowest: _lightBackground,
        surfaceContainerLow: Color(0xFFF8F9FA),
        surfaceContainer: Color(0xFFF0F2F5),
      ),
      scaffoldBackgroundColor: _lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: _lightOnSurface),
      ),
      cardTheme: const CardThemeData(
        color: _lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _lightPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: _lightOnSurfaceVariant, fontSize: 14),
        labelStyle: const TextStyle(color: _lightOnSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightOnSurface,
          side: const BorderSide(color: _lightOutline),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _lightPrimary,
        unselectedItemColor: _lightOnSurfaceVariant,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: _lightOutline,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _lightOnSurface,
        titleTextStyle: TextStyle(
          color: _lightOnSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        secondary: Color(0xFFFFA000),
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        onSurfaceVariant: _darkOnSurfaceVariant,
        outline: _darkOutline,
        outlineVariant: _darkOutlineVariant,
        error: Color(0xFFCF6679),
        primaryContainer: Color(0xFF1A2C6B),
        onPrimaryContainer: Color(0xFFB8C8FF),
        surfaceContainerLowest: _darkBackground,
        surfaceContainerLow: Color(0xFF0D0D0D),
        surfaceContainer: Color(0xFF1A1A1A),
      ),
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkOnSurface,
          fontWeight: FontWeight.w800,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: _darkOnSurface),
      ),
      cardTheme: const CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _darkPrimary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: _darkOnSurfaceVariant, fontSize: 14),
        labelStyle: const TextStyle(color: _darkOnSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkOnSurface,
          side: const BorderSide(color: _darkOutline),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: _darkPrimary,
        unselectedItemColor: _darkOnSurfaceVariant,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: _darkOutline,
        thickness: 0.5,
        space: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _darkOnSurface,
        titleTextStyle: TextStyle(
          color: _darkOnSurface,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
    );
  }
}
