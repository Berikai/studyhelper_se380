import 'package:flutter/material.dart';

// Placeholder screen for create page
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lecture'),
      ),
      body: const Center(
        child: Text('Create Screen Placeholder'),
      ),
    );
  }
}
