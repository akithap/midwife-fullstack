import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/appointment.dart';

class UpcomingMeetingsScreen extends StatefulWidget {
  @override
  _UpcomingMeetingsScreenState createState() => _UpcomingMeetingsScreenState();
}

class _UpcomingMeetingsScreenState extends State<UpcomingMeetingsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Appointment>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _appointmentsFuture = _apiService.getMyAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Upcoming Meetings'),
        // backgroundColor: Colors.blueAccent, // Handled by Theme
        elevation: 0,
      ),
      body: FutureBuilder<List<Appointment>>(
        future: _appointmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading meetings'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No upcoming meetings scheduled.',
                    style: TextStyle(fontSize: 16, color: theme.disabledColor),
                  ),
                ],
              ),
            );
          }

          // Filter for Scheduled/Pending and Sort by Date
          final meetings =
              snapshot.data!.where((a) => a.status == 'Scheduled').toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

          if (meetings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No scheduled meetings found.',
                    style: TextStyle(fontSize: 16, color: theme.disabledColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return Card(
                elevation: 2,
                color: theme.cardTheme.color,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              (isDark ? Colors.blueAccent : Colors.blueAccent)
                                  .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('MMM').format(meeting.dateTime),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.blueAccent.shade100
                                    : Colors.blueAccent,
                              ),
                            ),
                            Text(
                              DateFormat('dd').format(meeting.dateTime),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meeting.visitType,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              DateFormat('hh:mm a').format(meeting.dateTime),
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                            ),
                            if (meeting.notes != null &&
                                meeting.notes!.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                meeting.notes!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.dividerColor,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
