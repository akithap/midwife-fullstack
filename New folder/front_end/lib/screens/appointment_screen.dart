import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For calls
import '../models/appointment.dart';
import '../models/mother.dart';
import '../services/api_service.dart';
import 'anc_record_screen.dart';

class AppointmentScreen extends StatefulWidget {
  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final ApiService _apiService = ApiService();
  List<Appointment> _appointments = [];
  List<Mother> _mothers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Get Today's Date
      final now = DateTime.now();

      // 2. Fetch Appointments for TODAY
      // Using getMidwifeAppointments with date filter
      final appointments = await _apiService.getMidwifeAppointments(date: now);

      // 3. Fetch Mothers (to map names/address)
      // Optimization: Could fetch only relevant mothers, but getMothers() is cached/fast enough for now
      final mothers = await _apiService.getMothers();

      setState(() {
        _appointments = appointments;
        _mothers = mothers;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markCompleted(Appointment appt) async {
    try {
      await _apiService.updateAppointment(appt.id, {"status": "Completed"});
      _loadData(); // Refresh list
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Visit Marked as Completed!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Helper to make phone calls
  Future<void> _makeCall(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Fallback
      print("Could not launch $launchUri");
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('MMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Visits', style: TextStyle(fontSize: 18)),
            Text(
              todayStr,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No visits scheduled for today!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appt = _appointments[index];
                final mother = _mothers.firstWhere(
                  (m) => m.id == appt.motherId,
                  orElse: () => Mother(
                    id: -1,
                    nic: 'N/A',
                    fullName: 'Unknown',
                    address: 'N/A',
                    contactNumber: 'N/A',
                    midwifeId: -1,
                  ),
                );

                bool isCompleted = appt.status == "Completed";

                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isCompleted ? Colors.teal.shade50 : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Time & Type
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(
                                appt.visitType,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: Colors.teal,
                              visualDensity: VisualDensity.compact,
                            ),
                            Text(
                              DateFormat('h:mm a').format(appt.dateTime),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Mother Details
                        Text(
                          mother.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Address
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                mother.address,
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),

                        // Phone
                        InkWell(
                          onTap: () => _makeCall(mother.contactNumber),
                          child: Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.teal),
                              SizedBox(width: 4),
                              Text(
                                mother.contactNumber,
                                style: TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Divider(height: 24),

                        // Notes
                        if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                          Text(
                            "Notes:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            appt.notes!,
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                          SizedBox(height: 16),
                        ],

                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: isCompleted
                              ? OutlinedButton.icon(
                                  onPressed: null, // Disabled
                                  icon: Icon(Icons.check, color: Colors.green),
                                  label: Text(
                                    "COMPLETED",
                                    style: TextStyle(color: Colors.green),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _markCompleted(appt),
                                  icon: Icon(Icons.check_circle_outline),
                                  label: Text("MARK AS COMPLETED"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
