import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MyApp());
}

// We kept the main.dart file simple, and try to divide the code into different files as much as possible for cleaner project structure.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Helper', // Title
      theme: AppTheme.darkTheme, // Theme properties
      home: const MainScreen(), // Home screen of our app
    );
  }
}
