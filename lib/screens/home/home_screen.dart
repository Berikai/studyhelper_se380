import 'package:flutter/material.dart';

// Placeholder screen for home page
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: const Center(
        child: Text('Home Screen Placeholder'),
      ),
    );
  }
}
