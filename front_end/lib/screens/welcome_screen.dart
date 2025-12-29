import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'midwife_login_screen.dart';
import 'mother_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              // Logo Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 32),

              // App Title
              Text(
                'Rakawaranaya',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Professional Midwifery Care\nat Your Fingertips',
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
                label: 'Midwife Login',
                icon: Icons.medical_services_outlined,
                color: AppTheme.primaryColor,
                textColor: Colors.white,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MidwifeLoginScreen()),
                ),
              ),
              SizedBox(height: 16),
              _buildRoleButton(
                context,
                label: 'Mother Login',
                icon: Icons.pregnant_woman,
                color: AppTheme.background,
                textColor: AppTheme.primaryDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MotherLoginScreen()),
                ),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
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
