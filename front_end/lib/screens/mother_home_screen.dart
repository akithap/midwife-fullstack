import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_card.dart';

import 'upcoming_meetings_screen.dart';

import 'change_password_screen.dart';
import '../services/api_service.dart';
import '../models/appointment.dart';
import 'mother_health_file_screen.dart';

import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_screen.dart';
import '../enums/user_role.dart';

class MotherHomeScreen extends StatefulWidget {
  @override
  _MotherHomeScreenState createState() => _MotherHomeScreenState();
}

class _MotherHomeScreenState extends State<MotherHomeScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();

  // Notification State
  Timer? _pollingTimer;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _checkUpcomingAppointments();
    _checkDailyTipNotification();
    _fetchNotifications();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _initNotifications() {
    _notificationService.init((payload) async {
      if (payload == 'mother_appointment') {
        // Handle appointment navigation
      } else if (payload == 'mother_chat_screen') {
        _showNotificationDialog();
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchNotifications(isBackground: true);
    });
  }

  Future<void> _fetchNotifications({bool isBackground = false}) async {
    try {
      final count = await _apiService.getUnreadMessageCountMother();

      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }

      if (isBackground && count > 0) {
        // Simple notification for now
        NotificationService().showNotification(
          id: 888,
          title: "New Message from Midwife",
          body: "You have $count unread messages.",
          payload: "mother_chat_screen",
        );
      }
    } catch (e) {
      print("Polling error: $e");
    }
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Notifications"),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_unreadCount > 0)
                ListTile(
                  leading: Icon(Icons.chat, color: Colors.blue),
                  title: Text("$_unreadCount New Messages"),
                  subtitle: Text("From Midwife"),
                  onTap: () {
                    Navigator.pop(ctx);
                    // We know there's only one midwife usually, so we can route cleaner in future
                    // For now just close, as Chat FAB is main entry
                  },
                ),
              if (_unreadCount == 0)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("No new messages"),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Close")),
        ],
      ),
    );
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

  Future<void> _checkDailyTipNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      final lastTipDate = prefs.getString('last_tip_notification_date');

      // Only notify once per day
      if (lastTipDate != todayStr) {
        final tip = await _apiService.getHealthTip();

        // Clean up tip for notification (remove "Hey Name," prefix if it's too long or keep it?)
        // Let's keep it personalized but maybe shorten title.

        await _notificationService.showNotification(
          id: 3, // Unique ID for Tips
          title: 'Daily Wisdom 💡',
          body: tip,
          payload: 'daily_tip',
        );

        await prefs.setString('last_tip_notification_date', todayStr);
      }
    } catch (e) {
      print("Error showing daily tip notification: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Health'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme(
                themeProvider.themeMode != ThemeMode.dark,
              );
            },
          ),
          // BELL ICON
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: _showNotificationDialog,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                    child: Text(
                      '$_unreadCount',
                      style: TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
                      backgroundColor: theme.colorScheme.secondary.withOpacity(
                        0.1,
                      ),
                      child: Icon(
                        Icons.pregnant_woman,
                        size: 36,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome, Mother!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track your pregnancy journey.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // New Health Tip Card
              _buildHealthTipCard(theme), // Added this line

              SizedBox(height: 8),

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

                  return _buildTicketCard(context, next, theme);
                },
              ),

              SizedBox(height: 10),
              Text(
                'My Records',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => Center(child: CircularProgressIndicator()),
            );

            // Fetch profile to get Midwife ID
            final mother = await _apiService.getMotherProfile();

            // Hide loading
            Navigator.pop(context);

            // Navigate to Chat
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  otherUserId: mother.midwifeId,
                  otherUserName: "My Midwife",
                  myRole: UserRole.mother,
                ),
              ),
            );
          } catch (e) {
            Navigator.pop(context); // Hide loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to connect to Midwife')),
            );
          }
        },
        label: Text('Contact Midwife'),
        icon: Icon(Icons.chat),
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    Appointment apt,
    ThemeData theme,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
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
              color: theme.primaryColor,
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
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy').format(apt.dateTime),
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: theme.dividerColor,
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
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(apt.dateTime),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (apt.notes != null)
                        Text(
                          apt.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
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
    final theme = Theme.of(context);
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.all(20),
      // CustomCard needs to respect theme or we can wrap its child
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
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: theme.dividerColor),
        ],
      ),
    );
  }

  Widget _buildHealthTipCard(ThemeData theme) {
    return FutureBuilder<String>(
      future: _apiService.getHealthTip(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(bottom: 24),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor.withOpacity(0.9), theme.primaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: Colors.yellowAccent,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Daily Wisdom",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                snapshot.data!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
