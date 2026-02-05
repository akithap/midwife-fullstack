import 'package:flutter/material.dart';
import 'package:front_end/l10n/app_localizations.dart';

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
            Text(
              AppLocalizations.of(context)!.healthFile,
              style: TextStyle(fontSize: 16),
            ),
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
            Tab(
              text: AppLocalizations.of(context)!.registration,
              icon: Icon(Icons.description),
            ),
            Tab(
              text: AppLocalizations.of(context)!.ancLog,
              icon: Icon(Icons.table_chart),
            ),
            Tab(
              text: AppLocalizations.of(context)!.pncLog,
              icon: Icon(Icons.child_care),
            ),
            Tab(
              text: AppLocalizations.of(context)!.charts,
              icon: Icon(Icons.show_chart),
            ),
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
      return Center(
        child: Text(AppLocalizations.of(context)!.noRegistrationRecord),
      );
    }
    final r = _pregnancyRecord!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(AppLocalizations.of(context)!.personalInfo, [
            "${AppLocalizations.of(context)!.age}: ${r['mother_age']} ${AppLocalizations.of(context)!.years}",
            "${AppLocalizations.of(context)!.education}: ${r['mother_education'] ?? 'N/A'}",
            "${AppLocalizations.of(context)!.occupation}: ${r['mother_occupation'] ?? 'N/A'}",
            "${AppLocalizations.of(context)!.husband}: ${r['husband_name'] ?? 'N/A'} (${r['husband_age']}${AppLocalizations.of(context)!.years})",
          ], theme),
          _buildInfoCard(AppLocalizations.of(context)!.obstetricHistory, [
            "${AppLocalizations.of(context)!.gravidity}: ${r['gravidity']}",
            "${AppLocalizations.of(context)!.parity}: ${r['parity']}",
            "${AppLocalizations.of(context)!.livingChildren}: ${r['num_living_children'] ?? 0}", // FIX: Handle null
            "${AppLocalizations.of(context)!.youngestChild}: ${r['age_of_youngest_child'] ?? 'N/A'}",
          ], theme),
          _buildInfoCard(AppLocalizations.of(context)!.currentPregnancy, [
            "${AppLocalizations.of(context)!.lrmp}: ${r['lrmp']}",
            "${AppLocalizations.of(context)!.edd}: ${r['edd']}",
            "${AppLocalizations.of(context)!.poaAtReg}: ${r['poa_at_registration']}",
            "${AppLocalizations.of(context)!.bmi}: ${r['bmi']}",
            "${AppLocalizations.of(context)!.height}: ${r['height_cm']} cm",
            "${AppLocalizations.of(context)!.weight}: ${r['weight_kg']} kg",
            "${AppLocalizations.of(context)!.bloodGroup}: ${r['blood_group'] ?? 'N/A'}",
          ], theme),
          _buildInfoCard(
            AppLocalizations.of(context)!.riskFactors,
            [
              if (r['risk_age_lt_20_gt_35'] == true)
                AppLocalizations.of(context)!.riskAge,
              if (r['risk_5th_pregnancy'] == true)
                AppLocalizations.of(context)!.riskGrandMultipara,
              if (r['risk_birth_interval_lt_1yr'] == true)
                AppLocalizations.of(context)!.riskBirthInterval,
              if (r['risk_diabetes'] == true)
                AppLocalizations.of(context)!.riskDiabetes,
              if (r['risk_malaria'] == true)
                AppLocalizations.of(context)!.riskMalaria,
              if (r['risk_cardiac'] == true)
                AppLocalizations.of(context)!.riskHeart,
              if (r['risk_renal'] == true)
                AppLocalizations.of(context)!.riskRenal,
              // Add more risks as needed
              if (r['other_risk_factors'] != null)
                "${AppLocalizations.of(context)!.riskOther}: ${r['other_risk_factors']}",
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
                AppLocalizations.of(context)!.noneRecorded,
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
      return Center(child: Text(AppLocalizations.of(context)!.noAncVisits));
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
                            "${AppLocalizations.of(context)!.date}: ${v['visit_date']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? theme.colorScheme.secondary
                                  : Colors.teal,
                            ),
                          ),
                          Text(
                            "${AppLocalizations.of(context)!.poa}: ${v['poa_weeks']}w",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Divider(color: theme.dividerColor),
                      _buildGridItem(
                        AppLocalizations.of(context)!.weight,
                        "${v['weight_kg'] ?? '-'} kg",
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.bp,
                        "${v['bp_systolic']}/${v['bp_diastolic']}",
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.fundalHeight,
                        "${v['fundal_height_cm'] ?? '-'} cm",
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.lie,
                        v['fetal_lie'] ?? '-',
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.fhs,
                        v['fetal_heart_sound'] ?? '-',
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.urine,
                        "S:${v['urine_sugar']} A:${v['urine_albumin']}",
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.edema,
                        v['oedema'] ?? '-',
                        theme,
                      ),
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
                  DataColumn(label: Text(AppLocalizations.of(context)!.date)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.poa)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.weight)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.bp)),
                  DataColumn(
                    label: Text(AppLocalizations.of(context)!.fundalHeight),
                  ),
                  DataColumn(label: Text(AppLocalizations.of(context)!.lie)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.fhs)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.urine)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.edema)),
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
      return Center(child: Text(AppLocalizations.of(context)!.noPncVisits));
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
              String infection = AppLocalizations.of(context)!.no;
              if (v['perineum_infection'] == true ||
                  v['fissure_infection'] == true) {
                infection = AppLocalizations.of(context)!.yes;
              }
              String ref = v['referred_to_hospital'] == true
                  ? AppLocalizations.of(context)!.yes.toUpperCase()
                  : AppLocalizations.of(context)!.no;

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
                            "${AppLocalizations.of(context)!.date}: ${v['visit_date']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.purpleAccent
                                  : Colors.purple,
                            ),
                          ),
                          Text(
                            "${AppLocalizations.of(context)!.temp}: ${v['temperature'] ?? '-'} °C",
                          ),
                        ],
                      ),
                      Divider(color: theme.dividerColor),
                      _buildGridItem(
                        AppLocalizations.of(context)!.infection,
                        infection,
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.lochia,
                        v['lochia_character'] ?? '-',
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.babyColor,
                        v['baby_color'] ?? '-',
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.cord,
                        v['cord_status'] ?? '-',
                        theme,
                      ),
                      _buildGridItem(
                        AppLocalizations.of(context)!.feeding,
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
                                AppLocalizations.of(context)!.hospitalRef,
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
                                  color:
                                      ref ==
                                          AppLocalizations.of(
                                            context,
                                          )!.yes.toUpperCase()
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
                  DataColumn(label: Text(AppLocalizations.of(context)!.date)),
                  DataColumn(label: Text(AppLocalizations.of(context)!.temp)),
                  DataColumn(
                    label: Text(AppLocalizations.of(context)!.infection),
                  ), // Perineum/C-Sec
                  DataColumn(label: Text(AppLocalizations.of(context)!.lochia)),
                  DataColumn(
                    label: Text(AppLocalizations.of(context)!.babyColor),
                  ),
                  DataColumn(label: Text(AppLocalizations.of(context)!.cord)),
                  DataColumn(
                    label: Text(AppLocalizations.of(context)!.feeding),
                  ),
                  DataColumn(
                    label: Text(AppLocalizations.of(context)!.hospitalRef),
                  ),
                ],
                rows: visits.map<DataRow>((v) {
                  // Formatting Helpers
                  String infection = AppLocalizations.of(context)!.no;
                  if (v['perineum_infection'] == true ||
                      v['fissure_infection'] == true) {
                    infection = AppLocalizations.of(context)!.yes;
                  }
                  String ref = v['referred_to_hospital'] == true
                      ? AppLocalizations.of(context)!.yes.toUpperCase()
                      : AppLocalizations.of(context)!.no;

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
                            color:
                                infection == AppLocalizations.of(context)!.yes
                                ? Colors.red
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight:
                                infection == AppLocalizations.of(context)!.yes
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
                            color:
                                ref ==
                                    AppLocalizations.of(
                                      context,
                                    )!.yes.toUpperCase()
                                ? Colors.red
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight:
                                ref ==
                                    AppLocalizations.of(
                                      context,
                                    )!.yes.toUpperCase()
                                ? FontWeight.bold
                                : null,
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
          Text(AppLocalizations.of(context)!.weightGainChartComingSoon),
          // Placeholder: FlChart implementation would go here
        ],
      ),
    );
  }
}
