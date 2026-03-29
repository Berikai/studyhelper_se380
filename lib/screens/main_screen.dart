import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'create/create_screen.dart';
import 'library/library_screen.dart';
import 'profile/profile_screen.dart';

// Main screen that manages the bottom navigation bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// State of the main screen
class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Default to Create

  final List<Widget> _pages = const [
    HomeScreen(),
    CreateScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  // Function to handle tab tap, takes the tapped button index as an argument
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            // Highlight the Create button
            icon: Icon(Icons.add_circle, color: Colors.blueAccent, size: 30), // create button is always blue and big
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
