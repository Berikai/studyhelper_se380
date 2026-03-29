import 'package:flutter/material.dart';

// Theme properties of our app
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      // General theme properties
      brightness: Brightness.dark, // Dark mode
      scaffoldBackgroundColor: const Color(0xff12141D), // Background color of screens
      primaryColor: Colors.blueAccent, // Primary (accent) color

      // Properties of app bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // makes the app bar transparent
        elevation: 0, // means no shadow
        centerTitle: true, // centers the app bar title
      ),

      // Properties of bottom nav bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xff1A1C29), // Background color for nav bar
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
