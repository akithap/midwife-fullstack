import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'dart:async'; // For Timer

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/midwife.dart';
// Removed unused import

import 'appointment_screen.dart';
import 'change_password_screen.dart';

import 'leave_request_screen.dart';
import 'select_mother_screen.dart';
import 'risk_management_screen.dart';
import '../services/sync_service.dart';
import 'sync_status_screen.dart';
import 'chat_screen.dart';
import '../enums/user_role.dart';

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

  // Notification State
  // Removed unused notifications field
  Timer? _notificationTimer;
  int _unreadCount = 0;
  List<Map<String, dynamic>> _unreadSenders = [];

  @override
  void initState() {
    super.initState();
    _reloadStats();
    _initNotifications();
    _startPolling();

    _fetchNotifications();
    _startNotificationPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _initNotifications() {
    _notificationService.init((payload) async {
      if (payload == 'daily_visits') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AppointmentScreen()),
        );
      } else if (payload == 'chat_screen') {
        // Just open the notification dialog or go to a chat list if existed
        // For MVP, we'll just show the dialog if they are on home screen
        _showNotificationDialog();
      }
    });
  }

  void _startNotificationPolling() {
    _notificationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _fetchNotifications(isBackground: true);
    });
  }

  Future<void> _fetchNotifications({bool isBackground = false}) async {
    try {
      final unreadCount = await _apiService.getUnreadMessageCount();
      final senders = await _apiService.getUnreadSenders();

      if (mounted) {
        setState(() {
          _unreadCount = unreadCount;
          _unreadSenders = senders;
        });
      }

      // Trigger Local Notification if new message found in background poll
      // For MVP, if unreadCount > 0 and it's a background poll
      if (isBackground && unreadCount > 0) {
        NotificationService().showNotification(
          id: 999,
          title: "New Message",
          body: "You have $unreadCount unread messages.",
          payload: "chat_screen",
        );
      }
    } catch (e) {
      if (!mounted) return;
    }
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
                ..._unreadSenders.map((sender) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      child: Text(sender['name'][0].toUpperCase()),
                    ),
                    title: Text(sender['name']),
                    subtitle: Text("New message"),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: sender['id'],
                            otherUserName: sender['name'],
                            myRole: UserRole.midwife,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
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

  void _showProfileDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: CircularProgressIndicator()),
    );

    Midwife? profile = await _apiService.getMidwifeProfile();
    Navigator.pop(context); // Close loading

    if (profile != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : "M",
                ),
              ),
              SizedBox(width: 10),
              Expanded(child: Text("Midwife Profile")),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileRow("Name", profile.fullName),
                _buildProfileRow("SLMC Reg No", profile.slmcRegNo),
                _buildProfileRow("Service Grade", profile.serviceGrade),
                Divider(),
                _buildProfileRow("Assigned Area", profile.assignedMohArea),
                _buildProfileRow("Phone", profile.phoneNumber),
                _buildProfileRow("Email", profile.email),
                SizedBox(height: 10),
                Text(
                  "System ID: ${profile.username}",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load profile details")));
    }
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _showProfileDialog,
            child: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: theme.primaryColor),
            ),
          ),
        ),
        title: Text('Dashboard'),
        elevation: 0,
        actions: [
          // THEME TOGGLE
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () {
              themeProvider.toggleTheme(!isDark);
            },
          ),
          // SYNC ICON
          Consumer<SyncService>(
            builder: (context, syncService, child) {
              IconData icon;
              Color color;

              if (!syncService.isOnline) {
                icon = Icons.cloud_off;
                color = Colors.grey;
              } else if (syncService.isSyncing) {
                icon = Icons.cloud_upload;
                color = Colors.blue;
              } else {
                icon = Icons.cloud_done;
                color = Colors.green;
              }

              return IconButton(
                icon: Icon(icon, color: color),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SyncStatusScreen()),
                  );
                },
                tooltip: syncService.isOnline ? "Sync Status" : "Offline Mode",
              );
            },
          ),
          // NOTIFICATIONS ICON with BADGE
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
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
          // Change Password Icon
          IconButton(
            icon: Icon(Icons.vpn_key),
            tooltip: 'Change Password',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: IconButton(
                icon: Icon(Icons.logout, size: 20, color: theme.primaryColor),
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
        child: Stack(
          children: [
            // BACKGROUND DECORATION (Hero Header)
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(
                  0.15,
                ), // Soft Sage Background
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(40),
                ),
              ),
            ),

            // MAIN CONTENT
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section (Hero)
                  Container(
                    margin: EdgeInsets.only(bottom: 20, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Midwife Staff',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),

                  // 1. TODAY'S PROGRESS CARD
                  FutureBuilder<Map<String, int>>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      final visits = snapshot.data?['todays_visits'] ?? 0;

                      return Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Progress",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: 24),
                            Row(
                              children: [
                                SizedBox(
                                  height: 90,
                                  width: 90,
                                  child: Stack(
                                    children: [
                                      CircularProgressIndicator(
                                        value: 0.0,
                                        strokeWidth: 10,
                                        backgroundColor: theme.primaryColor
                                            .withOpacity(0.1),
                                        color: theme.primaryColor,
                                        strokeCap: StrokeCap.round,
                                      ),
                                      Center(
                                        child: Text(
                                          "$visits",
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "$visits Visits Done",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "Keep it up!",
                                      style: TextStyle(
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 32),
                  Text(
                    "Up Next",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 2. UP NEXT CARD
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time_rounded,
                            color: theme.primaryColor,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Next Visit",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Check Schedule",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: theme.primaryColor,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),
                  Text(
                    "Quick Actions",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 3. ADMIN TOOLS LIST (Horizontal)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        _buildAdminTool(
                          context,
                          "Risk Levels",
                          Icons.medical_services_outlined,
                          Color(0xFFE57373),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RiskManagementScreen(),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        _buildAdminTool(
                          context,
                          "Records",
                          Icons.folder_open_rounded,
                          Color(0xFFBA68C8),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SelectMotherScreen(formType: 'health_file'),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        _buildAdminTool(
                          context,
                          "Leaves",
                          Icons.beach_access_rounded,
                          Color(0xFFFFB74D),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeaveRequestScreen(),
                            ),
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
      ),
    );
  }

  Widget _buildAdminTool(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
