import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User 1', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('user1@mail.com'),
            SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remaining Quota', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('10 / 10 lessons remaining'),
                ],
              ),
            ),

            SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text('Your Lessons'), 
                    onTap: () {}),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Add Account'), 
                    onTap: () {}),
                  Divider(height: 1),
                  ListTile(
                    title: Text('Settings'), 
                    onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
