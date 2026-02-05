import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:front_end/l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'midwife_login_screen.dart';
import 'mother_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Spacer(),
                  // Logo Section
                  // Logo with Text
                  Image.asset(
                    'assets/images/logo_transparent.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.appSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textGrey,
                      height: 1.5,
                    ),
                  ),

                  Spacer(),

                  // Action Buttons
                  _buildRoleButton(
                    context,
                    label: AppLocalizations.of(context)!.midwifeLogin,
                    icon: Icons.medical_services_outlined,
                    color: AppTheme.primaryColor,
                    textColor: Colors.white,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MidwifeLoginScreen(),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildRoleButton(
                    context,
                    label: AppLocalizations.of(context)!.motherLogin,
                    icon: Icons.pregnant_woman,
                    color: AppTheme.background,
                    textColor: AppTheme.primaryDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MotherLoginScreen(),
                      ),
                    ),
                  ),
                  SizedBox(height: 48),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 24,
              child: _buildLanguageSwitcher(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              value: provider.currentLocale,
              icon: Icon(Icons.language, color: AppTheme.primaryColor),
              onChanged: (Locale? newValue) {
                if (newValue != null) {
                  provider.changeLanguage(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: Locale('si'),
                  child: Text('සිංහල', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: Locale('ta'),
                  child: Text('தமிழ்', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: color == Colors.white ? 0 : 2,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: color == AppTheme.background
                ? BorderSide(color: AppTheme.primaryColor.withOpacity(0.2))
                : BorderSide.none,
          ),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
