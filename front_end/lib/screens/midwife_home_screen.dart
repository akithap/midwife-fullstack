import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'dart:async'; // For Timer
import '../widgets/custom_card.dart';
import '../widgets/dashboard_stat.dart';
import '../services/api_service.dart'; // Import ApiService
import '../services/notification_service.dart'; // Import NotificationService

import 'mother_list_screen.dart';

import 'appointment_screen.dart';
import 'change_password_screen.dart';

import 'leave_request_screen.dart';
import 'select_mother_screen.dart';
import 'risk_management_screen.dart';

class MidwifeHomeScreen extends StatefulWidget {
  @override
  _MidwifeHomeScreenState createState() => _MidwifeHomeScreenState();
}

class _MidwifeHomeScreenState extends State<MidwifeHomeScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  late Future<Map<String, int>> _statsFuture;

  // Polling & Notification State
  Timer? _pollingTimer;
  int? _lastKnownVisits;

  @override
  void initState() {
    super.initState();
    _reloadStats();
    _initNotifications();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _initNotifications() {
    _notificationService.init((payload) async {
      if (payload == 'daily_visits') {
        // Navigate to AppointmentScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppointmentScreen()),
        );
      }
    });
  }

  void _startPolling() {
    // Poll every 30 seconds to check for updates
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _checkStatsForNotification();
    });
  }

  Future<void> _checkStatsForNotification() async {
    try {
      final stats = await _apiService.getDashboardStats();
      final currentVisits = stats['todays_visits'] ?? 0;

      // Initialize baseline on first run
      if (_lastKnownVisits == null) {
        _lastKnownVisits = currentVisits;
        return;
      }

      // If visits count CHANGED, trigger notification
      if (currentVisits != _lastKnownVisits) {
        _lastKnownVisits = currentVisits;

        await _notificationService.showNotification(
          id: 1,
          title: 'Daily Tasks Updated',
          body: 'Your daily visits have been updated. Check now.',
          payload: 'daily_visits',
        );

        // Also refresh UI
        _reloadStats();
      }
    } catch (e) {
      print("Error polling stats: $e");
    }
  }

  void _reloadStats() {
    setState(() {
      _statsFuture = _apiService.getDashboardStats();
    });
  }

  void _showNotifications(BuildContext context) async {
    try {
      final notifications = await _apiService.getNotifications();
      if (!mounted) return; // Check mounted before using context

      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                if (notifications.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No new notifications today.'),
                  )
                else
                  ...notifications.map(
                    (note) => Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              note,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load notifications')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
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
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: IconButton(
                icon: Icon(Icons.logout, size: 20, color: Colors.white),
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                },
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _reloadStats(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              Text(
                'Good Morning,',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textGrey),
              ),
              Text(
                'Midwife Staff',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 24),

              // Quick Stats Row
              FutureBuilder<Map<String, int>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint(
                      'Stats Error: ${snapshot.error}',
                    ); // Log to console
                    return Center(child: Text('Error loading stats'));
                  }
                  final assigned = snapshot.data?['assigned_mothers'] ?? 0;
                  final visits = snapshot.data?['todays_visits'] ?? 0;
                  // If loading, we just show 0 or a spinner inside?
                  // Let's settle for 0 or existing data with no spinner for cleaner UI

                  return Row(
                    children: [
                      DashboardStat(
                        label: 'Assigned',
                        value: '$assigned',
                        icon: Icons.pregnant_woman,
                        color: Colors.pink,
                      ),
                      SizedBox(width: 16),
                      DashboardStat(
                        label: 'Today\'s Visits',
                        value: '$visits',
                        icon: Icons.calendar_today,
                        color: Colors.orange,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 32),

              // Main Menu Grid
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildActionCard(
                    context,
                    title: 'My Mothers',
                    icon: Icons.people_outline,
                    color: Colors.teal,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MotherListScreen()),
                      );
                      _reloadStats();
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Daily Visits',
                    icon: Icons.today,
                    color: Colors.blue,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AppointmentScreen()),
                      );
                      _reloadStats();
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Patient Records',
                    icon: Icons.folder_shared,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SelectMotherScreen(formType: 'health_file'),
                        ),
                      );
                    },
                  ),

                  _buildActionCard(
                    context,
                    title: 'Risk Mgmt',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiskManagementScreen(),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    title: 'Leave Request',
                    icon: Icons.work_history_outlined,
                    color: Colors.orange,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LeaveRequestScreen()),
                      );
                      // Leave requests don't affect stats immediately but good practice
                      _reloadStats();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
