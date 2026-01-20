import 'package:flutter/material.dart';

import '../models/mother.dart';
import '../services/api_service.dart';

class MotherHealthFileScreen extends StatefulWidget {
  final Mother mother;

  MotherHealthFileScreen({required this.mother});

  @override
  _MotherHealthFileScreenState createState() => _MotherHealthFileScreenState();
}

class _MotherHealthFileScreenState extends State<MotherHealthFileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _pregnancyRecord;
  List<dynamic> _ancVisits = [];
  List<dynamic> _pncVisits = []; // NEW
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load both concurrently
      final record = await _apiService.getLatestPregnancyRecord(
        widget.mother.id,
      );
      final anc = await _apiService.getMotherANCVisits(widget.mother.id);
      final pnc = await _apiService.getMotherPNCVisits(
        widget.mother.id,
      ); // Fetch PNC

      if (mounted) {
        setState(() {
          // Unwrapping the nested 'record_data' if it exists (schema change)
          if (record != null && record.containsKey('record_data')) {
            _pregnancyRecord = record['record_data'];
            // We could also store record['past_history'] if we wanted to display it
          } else {
            _pregnancyRecord = record; // Fallback
          }
          _ancVisits = anc;
          _pncVisits = pnc; // Store PNC
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading health file: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Health File", style: TextStyle(fontSize: 16)),
            Text(
              widget.mother.fullName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        // backgroundColor: Colors.teal, // Handled by theme
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          // FIX: Use contrasting colors for Light Mode
          labelColor: isDark ? Colors.white : theme.primaryColor,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          tabs: [
            Tab(text: "Registration", icon: Icon(Icons.description)),
            Tab(text: "ANC Log", icon: Icon(Icons.table_chart)),
            Tab(text: "PNC Log", icon: Icon(Icons.child_care)),
            Tab(text: "Charts", icon: Icon(Icons.show_chart)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRegistrationTab(theme),
                _buildANCHistoryTab(theme),
                _buildPNCLogTab(theme), // NEW
                _buildChartsTab(),
              ],
            ),
    );
  }

  // --- TAB 1: Registration ---
  Widget _buildRegistrationTab(ThemeData theme) {
    if (_pregnancyRecord == null) {
      return Center(child: Text("No Pregnancy Registration Record Found"));
    }
    final r = _pregnancyRecord!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard("Personal Info", [
            "Age: ${r['mother_age']} years",
            "Education: ${r['mother_education'] ?? 'N/A'}",
            "Occupation: ${r['mother_occupation'] ?? 'N/A'}",
            "Husband: ${r['husband_name'] ?? 'N/A'} (${r['husband_age']}y)",
          ], theme),
          _buildInfoCard("Obstetric History", [
            "Gravidity (G): ${r['gravidity']}",
            "Parity (P): ${r['parity']}",
            "Living Children: ${r['num_living_children'] ?? 0}", // FIX: Handle null
            "Youngest Child: ${r['age_of_youngest_child'] ?? 'N/A'}",
          ], theme),
          _buildInfoCard("Current Pregnancy", [
            "LRMP: ${r['lrmp']}",
            "EDD: ${r['edd']}",
            "POA at Reg: ${r['poa_at_registration']}",
            "BMI: ${r['bmi']}",
            "Height: ${r['height_cm']} cm",
            "Weight: ${r['weight_kg']} kg",
            "Blood Group: ${r['blood_group'] ?? 'N/A'}",
          ], theme),
          _buildInfoCard(
            "Risk Factors",
            [
              if (r['risk_age_lt_20_gt_35'] == true) "• Age Risk (<20 or >35)",
              if (r['risk_5th_pregnancy'] == true) "• Grand Multipara (>5)",
              if (r['risk_birth_interval_lt_1yr'] == true)
                "• Birth Interval < 1 year",
              if (r['risk_diabetes'] == true) "• Diabetes",
              if (r['risk_malaria'] == true) "• History of Malaria",
              if (r['risk_cardiac'] == true) "• Heart Disease",
              if (r['risk_renal'] == true) "• Renal Disease",
              // Add more risks as needed
              if (r['other_risk_factors'] != null)
                "• Other: ${r['other_risk_factors']}",
            ],
            theme,
            isWarning: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    List<String> lines,
    ThemeData theme, {
    bool isWarning = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: isWarning
          ? (isDark ? Colors.red.withOpacity(0.1) : Colors.red.shade50)
          : theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isWarning
                    ? Colors.red
                    : (isDark
                          ? theme.colorScheme.secondary
                          : theme.primaryColor),
              ),
            ),
            Divider(color: theme.dividerColor),
            ...lines
                .map(
                  (l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      l,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                )
                .toList(),
            if (lines.isEmpty)
              Text(
                "None Recorded",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: theme.disabledColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: ANC Table ---
  Widget _buildANCHistoryTab(ThemeData theme) {
    if (_ancVisits.isEmpty) {
      return Center(child: Text("No ANC Visits Recorded Yet"));
    }

    // Sort reverse chronological
    final visits = List.from(_ancVisits.reversed);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // MOBILE VIEW: Cards
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final v = visits[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                color: theme.cardTheme.color,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Date: ${v['visit_date']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? theme.colorScheme.secondary
                                  : Colors.teal,
                            ),
                          ),
                          Text(
                            "POA: ${v['poa_weeks']}w",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Divider(color: theme.dividerColor),
                      _buildGridItem(
                        "Weight",
                        "${v['weight_kg'] ?? '-'} kg",
                        theme,
                      ),
                      _buildGridItem(
                        "BP",
                        "${v['bp_systolic']}/${v['bp_diastolic']}",
                        theme,
                      ),
                      _buildGridItem(
                        "Fundal H",
                        "${v['fundal_height_cm'] ?? '-'} cm",
                        theme,
                      ),
                      _buildGridItem("Lie", v['fetal_lie'] ?? '-', theme),
                      _buildGridItem(
                        "FHS",
                        v['fetal_heart_sound'] ?? '-',
                        theme,
                      ),
                      _buildGridItem(
                        "Urine",
                        "S:${v['urine_sugar']} A:${v['urine_albumin']}",
                        theme,
                      ),
                      _buildGridItem("Edema", v['oedema'] ?? '-', theme),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          // DESKTOP VIEW: Table
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  isDark
                      ? theme.primaryColor.withOpacity(0.1)
                      : Colors.teal.shade50,
                ),
                columns: [
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("POA")),
                  DataColumn(label: Text("Weight")),
                  DataColumn(label: Text("BP")),
                  DataColumn(label: Text("Fundal H")),
                  DataColumn(label: Text("Lie")),
                  DataColumn(label: Text("FHS")),
                  DataColumn(label: Text("Urine")),
                  DataColumn(label: Text("Edema")),
                ],
                rows: visits.map<DataRow>((v) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          v['visit_date'] ?? '',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['poa_weeks'] ?? '',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          "${v['weight_kg'] ?? '-'} kg",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          "${v['bp_systolic']}/${v['bp_diastolic']}",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          "${v['fundal_height_cm'] ?? '-'} cm",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['fetal_lie'] ?? '-',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['fetal_heart_sound'] ?? '-',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          "S:${v['urine_sugar']} A:${v['urine_albumin']}",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['oedema'] ?? '-',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildGridItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: PNC Table ---
  Widget _buildPNCLogTab(ThemeData theme) {
    if (_pncVisits.isEmpty) {
      return Center(child: Text("No PNC Visits Recorded Yet"));
    }

    final visits = List.from(_pncVisits.reversed);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // MOBILE VIEW
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final v = visits[index];
              String infection = "No";
              if (v['perineum_infection'] == true ||
                  v['fissure_infection'] == true) {
                infection = "Yes";
              }
              String ref = v['referred_to_hospital'] == true ? "YES" : "No";

              return Card(
                elevation: 2,
                color: theme.cardTheme.color,
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Date: ${v['visit_date']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.purpleAccent
                                  : Colors.purple,
                            ),
                          ),
                          Text("Temp: ${v['temperature'] ?? '-'} °C"),
                        ],
                      ),
                      Divider(color: theme.dividerColor),
                      _buildGridItem("Infection", infection, theme),
                      _buildGridItem(
                        "Lochia",
                        v['lochia_character'] ?? '-',
                        theme,
                      ),
                      _buildGridItem(
                        "Baby Color",
                        v['baby_color'] ?? '-',
                        theme,
                      ),
                      _buildGridItem("Cord", v['cord_status'] ?? '-', theme),
                      _buildGridItem(
                        "Feeding",
                        v['breastfeeding'] ?? '-',
                        theme,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Hospital Ref",
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                ref,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ref == "YES"
                                      ? Colors.red
                                      : theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          // DESKTOP VIEW
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  isDark
                      ? theme.primaryColor.withOpacity(0.1)
                      : Colors.purple.shade50,
                ),
                columns: [
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Temp")),
                  DataColumn(label: Text("Infection")), // Perineum/C-Sec
                  DataColumn(label: Text("Lochia")),
                  DataColumn(label: Text("Baby Color")),
                  DataColumn(label: Text("Cord")),
                  DataColumn(label: Text("Feeding")),
                  DataColumn(label: Text("Hospital Ref")),
                ],
                rows: visits.map<DataRow>((v) {
                  // Formatting Helpers
                  String infection = "No";
                  if (v['perineum_infection'] == true ||
                      v['fissure_infection'] == true) {
                    infection = "Yes";
                  }
                  String ref = v['referred_to_hospital'] == true ? "YES" : "No";

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          v['visit_date'] ?? '',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          "${v['temperature'] ?? '-'} °C",
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          infection,
                          style: TextStyle(
                            color: infection == "Yes"
                                ? Colors.red
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: infection == "Yes"
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['lochia_character'] ?? '-',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['baby_color'] ?? '-',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['cord_status'] ?? '-',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          v['breastfeeding'] ?? '-',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          ref,
                          style: TextStyle(
                            color: ref == "YES"
                                ? Colors.red
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: ref == "YES" ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }
      },
    );
  }

  // --- TAB 4: Charts ---
  Widget _buildChartsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("Weight Gain Chart Coming Soon"),
          // Placeholder: FlChart implementation would go here
        ],
      ),
    );
  }
}
