import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import 'study_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final info = await ApiService.getUserInfo();
    if (mounted) {
      setState(() {
        _userInfo = info;
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userInfo != null ? 'Student User' : 'Guest',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userInfo?['email'] ?? 'Offline Mode',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quota Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.withOpacity(0.8), Colors.blueAccent.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.diamond, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Credits Remaining', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_userInfo?['credits'] ?? 0} Credits',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Used for generating AI questions & plans',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),

                  // Options List
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff222536),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildListTile(Icons.history, 'Study History', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyHistoryScreen()));
                        }),
                        /*const Divider(height: 1, color: Colors.black26),
                        _buildListTile(Icons.settings, 'Preferences', () {
                          showDialog(context: context, builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xff222536),
                            title: const Text('Preferences', style: TextStyle(color: Colors.white)),
                            content: const Text('Dark Mode is permanently enabled for focus. More settings coming soon.', style: TextStyle(color: Colors.white70)),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it', style: TextStyle(color: Colors.blueAccent)))],
                          ));
                        }),
                        const Divider(height: 1, color: Colors.black26),
                        _buildListTile(Icons.help_outline, 'Help & Support', () {
                          showDialog(context: context, builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xff222536),
                            title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
                            content: const Text('Need help? Contact our support team at support@studyhelper.ai', style: TextStyle(color: Colors.white70)),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.blueAccent)))],
                          ));
                        }),*/
                        const Divider(height: 1, color: Colors.black26),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
