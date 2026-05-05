import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/api_service.dart';

import 'package:provider/provider.dart';
import 'state/app_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set up provider for state management
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Study Helper',
        theme: AppTheme.darkTheme,
        // Check if token exists to determine initial route
        // If token exists, go to MainScreen, otherwise go to LoginScreen
        home: FutureBuilder<String?>(
          future: ApiService.getToken(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const MainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
