import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/midwife_main_screen.dart';
import 'screens/mother_home_screen.dart';
import 'enums/user_role.dart';

import 'services/sync_service.dart';

import 'providers/theme_provider.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:front_end/l10n/app_localizations.dart';
import 'providers/language_provider.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // Initialize for all locales
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'Midwife App',
            theme: AppTheme.getLight(languageProvider.currentLocale),
            darkTheme: AppTheme.getDark(languageProvider.currentLocale),
            themeMode: themeProvider.themeMode,
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('si'), // Sinhala
              Locale('ta'), // Tamil
            ],
            home: AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
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
        return MidwifeMainScreen(); // Go to Midwife dashboard (Shell)
      case UserRole.mother:
        return MotherHomeScreen(); // Go to Mother dashboard
      case UserRole.none:
        //default:
        return WelcomeScreen(); // Go to the new Welcome/Login screen
    }
  }
}
