import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';

import 'upcoming_meetings_screen.dart';

import 'change_password_screen.dart';
import '../services/api_service.dart';
import '../models/appointment.dart';
import 'mother_health_file_screen.dart';

import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MotherHomeScreen extends StatefulWidget {
  @override
  _MotherHomeScreenState createState() => _MotherHomeScreenState();
}

class _MotherHomeScreenState extends State<MotherHomeScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _checkUpcomingAppointments();
  }

  void _initNotifications() {
    _notificationService.init((payload) async {
      // If clicked, we are already on Home Screen or can navigate
      // The requirement says "directed to mother home screen", which is here.
      // We could perhaps scroll to the ticket or just bring app to foreground.
    });
  }

  Future<void> _checkUpcomingAppointments() async {
    try {
      final appointments = await _apiService.getMyAppointments();
      final now = DateTime.now();
      final fiveDaysFromNow = now.add(Duration(days: 5));

      final upcoming = appointments.where((a) {
        return a.status == 'Scheduled' &&
            a.dateTime.isAfter(now) &&
            a.dateTime.isBefore(fiveDaysFromNow);
      }).toList();

      if (upcoming.isNotEmpty) {
        // Sort to find the nearest one
        upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        final nextAppt = upcoming.first;

        // Check if we already notified today to avoid spamming
        final prefs = await SharedPreferences.getInstance();
        final lastNotifiedDate = prefs.getString('last_appt_notification_date');
        final todayStr = DateFormat('yyyy-MM-dd').format(now);

        if (lastNotifiedDate != todayStr) {
          final dateStr = DateFormat('MMM dd, yyyy').format(nextAppt.dateTime);

          await _notificationService.showNotification(
            id: 2, // Different ID from Midwife
            title: 'Upcoming Appointment',
            body: 'You have your next appointment on $dateStr',
            payload: 'mother_appointment',
          );

          await prefs.setString('last_appt_notification_date', todayStr);
        }
      }
    } catch (e) {
      print("Error checking appointments: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('My Health'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key),
            tooltip: 'Change Password',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.logout),
              onPressed: () =>
                  Provider.of<AuthProvider>(context, listen: false).logout(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                      child: Icon(
                        Icons.pregnant_woman,
                        size: 36,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome, Mother!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track your pregnancy journey.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Upcoming Appointment Ticket
              FutureBuilder<List<Appointment>>(
                future: _apiService.getMyAppointments(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty)
                    return SizedBox.shrink();

                  final upcoming = snapshot.data!
                      .where((a) => a.status == 'Scheduled')
                      .toList();
                  if (upcoming.isEmpty) return SizedBox.shrink();

                  upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                  final next = upcoming.first;

                  return _buildTicketCard(context, next);
                },
              ),

              SizedBox(height: 10),
              Text(
                'My Records',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 16),

              _buildMenuCard(
                context,
                icon: Icons.folder_shared_outlined,
                title: 'My Health File',
                subtitle: 'View complete medical history',
                color: Colors.teal,
                onTap: () async {
                  try {
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (c) =>
                          Center(child: CircularProgressIndicator()),
                    );

                    // Fetch profile
                    final mother = await _apiService.getMotherProfile();

                    // Hide loading
                    Navigator.pop(context);

                    // Navigate
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MotherHealthFileScreen(mother: mother),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context); // Hide loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to load profile')),
                    );
                  }
                },
              ),

              _buildMenuCard(
                context,
                icon: Icons.calendar_today,
                title: 'Upcoming Meetings',
                subtitle: 'View scheduled appointments',
                color: Colors.blueAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UpcomingMeetingsScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Appointment apt) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Upcoming Appointment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'CONFIRMED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMM dd').format(apt.dateTime),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy').format(apt.dateTime),
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey.shade300,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt.visitType,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(apt.dateTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (apt.notes != null)
                        Text(
                          apt.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}
