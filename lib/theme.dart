import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final darkColor = const Color(0xFF6C3FFE);
  static final ButtonStyle emptyButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    foregroundColor:  darkColor,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
  );

  static final ButtonStyle filledButtonStyle  = ElevatedButton.styleFrom(
    backgroundColor: darkColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );

  static final ButtonStyle redButtonStyle  = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFBF3030),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );




  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFB39DDB),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
    ),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFFB39DDB),
      secondary: const Color(0xFFB39DDB),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      (const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      )),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFFB39DDB),
      unselectedItemColor: Colors.grey,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: filledButtonStyle
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkColor,
    secondaryHeaderColor: const Color(0xFF9575CD),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      surfaceContainerHighest: const Color(0xFF1F1F1F),
      primary: darkColor,
      secondary: const Color(0xFF9575CD),
    ),

    textTheme: GoogleFonts.poppinsTextTheme(
      (const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      )),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1F1F1F),
      selectedItemColor: Color(0xFFB39DDB),
      unselectedItemColor: Colors.grey,
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFF1F1F1F),
      filled: true,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: filledButtonStyle,
    ),
  );
}
