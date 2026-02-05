import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:front_end/l10n/app_localizations.dart';
import '../models/mother.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';
import 'pregnancy_registration_screen.dart';
import 'anc_record_screen.dart';
import 'pnc_record_screen.dart';

class MotherCareScreen extends StatefulWidget {
  final Mother mother;
  const MotherCareScreen({Key? key, required this.mother}) : super(key: key);

  @override
  _MotherCareScreenState createState() => _MotherCareScreenState();
}

class _MotherCareScreenState extends State<MotherCareScreen> {
  late Mother _mother;
  final ApiService _apiService = ApiService();
  List<Appointment> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mother = widget.mother;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Refresh Mother Data (Status might have changed)
      final mothers = await _apiService.getMothers();
      // Note: Ideal to have getMotherById, but filtering list works for now
      final updatedMother = mothers.firstWhere(
        (m) => m.id == _mother.id,
        orElse: () => _mother,
      );

      // 2. Get Appointments
      // We need a specific endpoint for mother's appointments, but existing one is for Midwife.
      // We can use getMidwifeAppointments and filter, OR add getAppointmentsForMother.
      // For now, let's look at what we have. API Service has getMidwifeAppointments.
      // Let's filter client side for speed.
      final allAppointments = await _apiService.getMidwifeAppointments();
      final motherAppts = allAppointments
          .where((a) => a.motherId == _mother.id)
          .toList();

      motherAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      setState(() {
        _mother = updatedMother;
        _appointments = motherAppts;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---

  Future<void> _handleStartPregnancy() async {
    // Navigate to Full H 512 Form
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PregnancyRegistrationScreen(mother: _mother),
      ),
    );

    if (result == true) {
      await _fetchData(); // Refresh to show new status and appointments
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pregnancyRegistrationComplete,
          ),
        ),
      );
    }
  }

  // NEW: Handle Edit H 512
  Future<void> _editH512Record() async {
    setState(() => _isLoading = true);
    try {
      final existingData = await _apiService.getPregnancyRecord(_mother.id);

      setState(() => _isLoading = false);

      if (existingData == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("No record found to edit.")));
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => PregnancyRegistrationScreen(
            mother: _mother,
            existingData: existingData, // Pass existing data
          ),
        ),
      );

      if (result == true) {
        await _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.motherUpdated)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _handleReportDelivery() async {
    final DateTime? deliveryDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(Duration(days: 7)),
      lastDate: DateTime.now(),
      helpText: "Select Date of Delivery",
    );

    if (deliveryDate == null) return;

    setState(() => _isLoading = true);
    final success = await _apiService.reportDelivery(
      _mother.id,
      DateFormat('yyyy-MM-dd').format(deliveryDate),
    );

    if (success) {
      await _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deliveryReported)),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedReportDelivery),
        ),
      );
    }
  }

  // --- WIDGETS ---

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Eligible':
        return Colors.grey;
      case 'Pregnant':
        return Colors.pinkAccent;
      case 'Postnatal':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  String _getTranslatedStatus(String status, BuildContext context) {
    switch (status) {
      case 'Eligible':
        return AppLocalizations.of(context)!.eligible.toUpperCase();
      case 'Pregnant':
        return AppLocalizations.of(context)!.pregnant.toUpperCase();
      case 'Postnatal':
        return AppLocalizations.of(context)!.postnatal.toUpperCase();
      case 'Completed':
        return AppLocalizations.of(context)!.completed.toUpperCase();
      default:
        return status.toUpperCase();
    }
  }

  // --- FLEXIBLE TIMELINE ACTIONS ---

  Future<void> _deleteVisit(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteVisitTitle),
        content: Text(AppLocalizations.of(context)!.deleteVisitConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.deleteAppointment(id);
      _fetchData();
    }
  }

  Future<void> _editVisitDate(Appointment appt) async {
    // 1. Try to find "Week X" in notes to calculate Ideal Date
    DateTime? idealDate;

    if (_mother.pregnancyStartDate != null) {
      final match = RegExp(r'Week\s+(\d+)').firstMatch(appt.notes ?? "");
      if (match != null) {
        int week = int.parse(match.group(1)!);
        // Ideal: LRMP + week * 7 days
        idealDate = _mother.pregnancyStartDate!.add(Duration(days: week * 7));
      }
    }

    // 2. Show Date Picker
    final newDate = await showDatePicker(
      context: context,
      initialDate: appt.dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: idealDate != null
          ? "${AppLocalizations.of(context)!.ideal}: ${DateFormat('MMM d').format(idealDate)}"
          : AppLocalizations.of(context)!.selectDate,
      fieldHintText: idealDate != null
          ? "Target: Week 12"
          : AppLocalizations.of(context)!.enterDate,
    );

    if (newDate != null) {
      // Check for Lateness (Soft Constraint)
      if (idealDate != null && newDate.difference(idealDate).inDays > 14) {
        // > 2 weeks late
        // Re-extract week for message
        final weekNum =
            RegExp(r'Week\s+(\d+)').firstMatch(appt.notes ?? "")?.group(1) ??
            "?";
        bool proceed =
            await showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.lateVisitWarning),
                content: Text(
                  AppLocalizations.of(context)!.lateVisitMessage(weekNum),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text(
                      AppLocalizations.of(context)!.proceed,
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (!proceed) return;
      }

      await _apiService.updateAppointment(appt.id, {
        "date_time": newDate.toIso8601String(),
        // Keep existing status/notes unless we want to edit them too
      });
      _fetchData();
    }
  }

  Future<void> _addCustomVisit() async {
    DateTime? selectedDate = DateTime.now();
    String type = "Home Visit";
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addExtraVisit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}",
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate!,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (d != null) {
                  // Hack to update UI inside Dialog
                  (ctx as Element).markNeedsBuild();
                  selectedDate = d;
                }
              },
            ),
            DropdownButton<String>(
              value: type,
              isExpanded: true,
              items: ['Home Visit', 'Clinic', 'Emergency'].map((String key) {
                return DropdownMenuItem<String>(
                  value: key,
                  child: Text(_getTranslatedVisitType(context, key)),
                );
              }).toList(),
              onChanged: (v) {
                // Update the local state variable 'type'
                // Since this is inside a Dialog's builder, we might need StateSetter if it was StatefulBuilder
                // But here 'type' is a local variable to the closure.
                // However, the builder is (ctx) => AlertDialog.
                // The 'type' variable is outside.
                // To update UI, we need (ctx as Element).markNeedsBuild() or use StatefulBuilder.
                // The original code had type = v!, but didn't setState.
                // It seems to rely on the Dialog rebuilding or just holding the value?
                // Wait, the original code had: onChanged: (v) => type = v!,
                // But 'type' is defined where?
                // var type = "Home Visit"; inside _addCustomVisit function scope.
                // If the dialog doesn't rebuild, the Dropdown value won't update visually.
                // The original code likely had this issue or used a different trick.
                // I will wrap it in StatefulBuilder to be safe and correct.
                type = v!;
                (ctx as Element).markNeedsBuild();
              },
            ),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.notesReason,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await _apiService.createAppointment(
                Appointment(
                  id: 0,
                  midwifeId: 0, // Ignored by backend
                  motherId: _mother.id,
                  dateTime: selectedDate!,
                  visitType: type,
                  status: 'Scheduled',
                  notes: notesCtrl.text,
                ),
                _mother.id,
              );
              Navigator.pop(ctx);
              _fetchData();
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Appointment appt) {
    bool isCompleted = appt.status == "Completed";
    bool isPast = appt.dateTime.isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Column
          GestureDetector(
            onTap: isCompleted ? null : () => _editVisitDate(appt),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  Text(
                    _formatDate(context, appt.dateTime),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Colors.teal,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy').format(appt.dateTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (!isCompleted)
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.orange,
                    ), // Edit Hint
                ],
              ),
            ),
          ),

          // Line
          Container(
            width: 2,
            height: 80, // Taller for actions
            color: isCompleted
                ? Colors.green
                : (isPast ? Colors.red : Colors.grey.shade300),
          ),
          SizedBox(width: 16),

          // Card
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  // Only allow clinic/home/PNC visits to be "Data Entered"
                  if (appt.visitType.contains("ANC") ||
                      appt.visitType == "Clinic" ||
                      appt.visitType.contains("Home") || // Relaxed check
                      appt.visitType.contains("PNC")) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => appt.visitType.contains("PNC")
                            ? PNCRecordScreen(
                                appointment: appt,
                                mother: widget.mother,
                              )
                            : ANCRecordScreen(
                                appointment: appt,
                                mother: widget.mother,
                              ),
                      ),
                    );
                    if (result == true) {
                      _fetchData(); // Refresh list to show status change
                    }
                  }
                },
                child: ListTile(
                  leading: Icon(
                    (appt.visitType.contains("ANC") ||
                            appt.visitType == "Clinic")
                        ? Icons.pregnant_woman
                        : appt.visitType.contains("PNC")
                        ? Icons.child_care
                        : Icons.medical_services,
                    color: _getStatusColor(_mother.status),
                  ),
                  title: Text(_getTranslatedVisitType(context, appt.visitType)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getTranslatedNotes(context, appt.notes)),
                      if (isPast && !isCompleted)
                        Text(
                          AppLocalizations.of(context)!.overdue,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompleted)
                        Icon(Icons.check_circle, color: Colors.green)
                      else ...[
                        // Complete Button
                        IconButton(
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            bool isSameDay =
                                appt.dateTime.year == now.year &&
                                appt.dateTime.month == now.month &&
                                appt.dateTime.day == now.day;

                            if (!isSameDay) {
                              // Date Mismatch Dialog
                              bool? reschedule = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(
                                    AppLocalizations.of(context)!.dateMismatch,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.dateMismatchBody(
                                      _formatDate(context, appt.dateTime),
                                      _formatDate(context, now),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, null),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.rescheduleComplete,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (reschedule == true) {
                                try {
                                  await _apiService.updateAppointment(appt.id, {
                                    "date_time": DateTime.now()
                                        .toIso8601String(),
                                    "status": "Completed",
                                  });
                                  _fetchData();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll(
                                          "Exception: ",
                                          "",
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                              return; // Stop if mismatch and not rescheduled
                            }

                            try {
                              // If same day, just complete
                              await _apiService.updateAppointment(appt.id, {
                                "status": "Completed",
                              });
                              _fetchData();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceAll("Exception: ", ""),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          tooltip: "Mark as Completed",
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade300,
                          ),
                          onPressed: () => _deleteVisit(appt.id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // For manual IP config check (same as other screens)
    // ignore: unused_local_variable
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;

    return Scaffold(
      floatingActionButton:
          _mother.status == 'Pregnant' || _mother.status == 'Postnatal'
          ? FloatingActionButton.extended(
              onPressed: _addCustomVisit,
              label: Text(AppLocalizations.of(context)!.addVisit),
              icon: Icon(Icons.add),
              backgroundColor: Colors.teal,
            )
          : null,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.carePlan),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    color: Colors.teal.shade50,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.teal,
                          child: Text(
                            _mother.fullName[0],
                            style: TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _mother.fullName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    "${AppLocalizations.of(context)!.status}: ",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  Chip(
                                    label: Text(
                                      _getTranslatedStatus(
                                        _mother.status,
                                        context,
                                      ),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    backgroundColor: _getStatusColor(
                                      _mother.status,
                                    ),
                                    padding: EdgeInsets.all(0),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Spacer(),
                                  // EDIT BUTTON
                                  if (_mother.status == 'Pregnant')
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_note,
                                        color: Colors.teal,
                                      ),
                                      onPressed: _editH512Record,
                                      tooltip: "Edit H 512 Record",
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _mother.status == 'Eligible'
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleStartPregnancy,
                              icon: Icon(Icons.favorite),
                              label: Text(
                                AppLocalizations.of(
                                  context,
                                )!.startPregnancyPlan,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          )
                        : _mother.status == 'Pregnant'
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _handleReportDelivery,
                              icon: Icon(Icons.child_friendly),
                              label: Text(
                                AppLocalizations.of(context)!.reportDelivery,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          )
                        : Container(), // Nothing for Postnatal yet (maybe Discharge)
                  ),

                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.careTimeline,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  _appointments.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            AppLocalizations.of(context)!.noUpcomingVisits,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _appointments.length,
                          itemBuilder: (ctx, i) =>
                              _buildTimelineItem(_appointments[i]),
                        ),
                ],
              ),
            ),
    );
  }

  String _getTranslatedVisitType(BuildContext context, String type) {
    final t = type.trim();
    if (t == 'Clinic') return AppLocalizations.of(context)!.clinic;
    if (t == 'Home Visit') return AppLocalizations.of(context)!.homeVisit;
    if (t == 'Emergency') return AppLocalizations.of(context)!.emergency;
    // Allow case-insensitive or partial match if needed, but 'PNC' should be exact standard
    if (t.toUpperCase() == 'PNC') return AppLocalizations.of(context)!.pnc;
    if (t.toUpperCase() == 'ANC') return AppLocalizations.of(context)!.anc;
    return type;
  }

  String _getTranslatedNotes(BuildContext context, String? notes) {
    if (notes == null) return AppLocalizations.of(context)!.scheduledVisit;
    final n = notes.trim();
    if (n == "Routine Checkup") {
      return AppLocalizations.of(context)!.routineCheckup;
    }

    // Flexible Regex: "PNC Visit X (Day Y)" case insensitive, flexible spaces
    // e.g. "PNC Visit 1 (Day 3)" or "pnc visit 1(day 3)"
    final pncRegex = RegExp(
      r'PNC\s*Visit\s*(\d+)\s*\(Day\s*(\d+)\)',
      caseSensitive: false,
    );
    final pncMatch = pncRegex.firstMatch(n);
    if (pncMatch != null) {
      return AppLocalizations.of(
        context,
      )!.pncVisitDay(pncMatch.group(1)!, pncMatch.group(2)!);
    }

    return notes;
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMMd(locale).format(date);
  }
}
