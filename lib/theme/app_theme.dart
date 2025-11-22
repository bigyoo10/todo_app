// NOTE: 현재 메인 테마에서는 사용되지 않는 보조 테마 정의입니다.
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4B7BE5);
  static const Color accentColor = Color(0xFFFFAD60);
  static const Color backgroundColor = Color(0xFFF6F8FA);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: accentColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      iconTheme: IconThemeData(color: Colors.black54),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
  );
}
