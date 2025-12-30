import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/midwife_home_screen.dart';
import 'screens/mother_home_screen.dart';
import 'enums/user_role.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This provides the AuthProvider to all widgets below it
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'Midwife App',
        theme: AppTheme.lightTheme,
        home: AuthWrapper(), // The home page is now this wrapper
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// This widget is the new "gatekeeper"
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Listen to changes in AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    // 1. If checking login status, show loading spinner
    if (authProvider.isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Check the user's role and show the correct screen
    switch (authProvider.role) {
      case UserRole.midwife:
        return MidwifeHomeScreen(); // Go to Midwife dashboard
      case UserRole.mother:
        return MotherHomeScreen(); // Go to Mother dashboard
      case UserRole.none:
        //default:
        return WelcomeScreen(); // Go to the new Welcome/Login screen
    }
  }
}
