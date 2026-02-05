import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import '../models/alert.dart'; // NEW
import 'select_mother_screen.dart'; // For full mother details potentially
import 'package:front_end/l10n/app_localizations.dart';

class RiskManagementScreen extends StatefulWidget {
  @override
  _RiskManagementScreenState createState() => _RiskManagementScreenState();
}

class _RiskManagementScreenState extends State<RiskManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, int> _stats = {};
  List<dynamic> _filteredMothers = [];
  String _selectedFilter = 'high_risk'; // Default

  // NEW: Toggle State for Priority Actions
  int _selectedActionIndex = 0; // 0 = Defaulters, 1 = Forecast

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _apiService.getRiskStats();
      final mothers = await _apiService.getMothersByRisk(_selectedFilter);
      setState(() {
        _stats = stats;
        _filteredMothers = mothers;
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading risk data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onFilterChanged(String filter) async {
    setState(() {
      _selectedFilter = filter;
      _isLoading = true;
      _filteredMothers = [];
    });

    try {
      final mothers = await _apiService.getMothersByRisk(filter);
      setState(() {
        _filteredMothers = mothers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getTranslatedFilter(String key) {
    var loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'high_risk':
        return loc.allHighRisk;
      case 'diabetes':
        return loc.diabetes;
      case 'cardiac':
        return loc.riskHeart;
      case 'age':
        return loc.riskAge;
      case 'pph':
        return loc.riskHistoryPPH;
      case 'gravidity':
        return loc.risk5thPreg;
      case 'malaria':
        return loc.riskMalaria;
      case 'renal':
        return loc.riskRenal;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.riskManagement),
          backgroundColor: Colors.teal, // CHANGED: Softer/Standard Theme Color
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white, // Selected Text Color (High Contrast)
            unselectedLabelColor: Colors.white70, // Unselected Text Color
            tabs: [
              Tab(
                icon: Icon(Icons.priority_high),
                text: AppLocalizations.of(context)!.priorityActions, // RENAMED
              ),
              Tab(
                icon: Icon(Icons.people_alt),
                text: AppLocalizations.of(context)!.riskGroups,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildPriorityActionsTab(), _buildRiskGroupsTab()],
        ),
      ),
    );
  }

  // --- TAB 1: PRIORITY ACTIONS (Toggle View) ---
  Widget _buildPriorityActionsTab() {
    return Column(
      children: [
        // 1. Toggle Switch
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              _buildToggleButton(AppLocalizations.of(context)!.sensitive, 0),
              _buildToggleButton(AppLocalizations.of(context)!.forecast, 1),
            ],
          ),
        ),

        // 2. Content Area
        Expanded(
          child: _selectedActionIndex == 0
              ? _buildDefaultersList()
              : _buildForecastList(),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, int index) {
    bool isSelected = _selectedActionIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedActionIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            AppLocalizations.of(context)!.silentRiskDetector,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _apiService.getMidwifeDefaulters(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return _buildEmptyState(
                  AppLocalizations.of(context)!.noDefaulters,
                );

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final d = snapshot.data![index];
                  return Card(
                    color: Colors.red.shade50,
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade100),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        child: Icon(Icons.warning, color: Colors.red),
                      ),
                      title: Text(
                        d['name'] ?? AppLocalizations.of(context)!.unknown,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.overdueDays(
                          d['days_overdue'].toString(),
                          d['last_seen'].toString(),
                        ),
                      ),
                      trailing: IconButton(
                        icon: CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 18,
                          child: Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildForecastList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            AppLocalizations.of(context)!.upcomingDeliveries,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _apiService.getMidwifeForecast(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty)
                return _buildEmptyState(
                  AppLocalizations.of(context)!.noDeliveries,
                );

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final d = snapshot.data![index];
                  return Card(
                    color: Colors.blue.shade50,
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade100),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.calendar_month, color: Colors.blue),
                      ),
                      title: Text(
                        d['name'] ?? AppLocalizations.of(context)!.unknown,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(
                          context,
                        )!.eddHighRisk(d['edd'].toString().split(' ')[0]),
                      ), // Placeholder Risk
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(msg, style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  // --- TAB 2: RISK GROUPS (Existing Logic) ---
  Widget _buildRiskGroupsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryHeader(),
            SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.filterByRisk,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            _buildFilterChips(),
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildMotherList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.highRiskCases,
            "${_stats['total_high_risk'] ?? 0}",
            Colors.red,
            Icons.warning_amber_rounded,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            AppLocalizations.of(context)!.diabetesWatch,
            "${_stats['diabetes'] ?? 0}",
            Colors.orange,
            Icons.bloodtype,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = {
      'high_risk': 'All High Risk',
      'diabetes': 'Diabetes',
      'cardiac': 'Cardiac',
      'age': 'Age Risk',
      'pph': 'History PPH',
      'gravidity': 'Grand Multipara',
      'malaria': 'History of Malaria',
      'renal': 'Renal Disease',
    };

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: filters.entries.map((entry) {
        final isSelected = _selectedFilter == entry.key;
        return ChoiceChip(
          label: Text(_getTranslatedFilter(entry.key)),
          selected: isSelected,
          onSelected: (val) {
            if (val) _onFilterChanged(entry.key);
          },
          selectedColor: Colors.redAccent.shade100,
          labelStyle: TextStyle(
            color: isSelected ? Colors.red.shade900 : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMotherList() {
    if (_filteredMothers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(AppLocalizations.of(context)!.noMothersFound),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _filteredMothers.length,
      itemBuilder: (context, index) {
        final m = _filteredMothers[index];
        final risks =
            (m['active_risks'] as List?)?.cast<String>() ??
            []; // Get list or empty

        return CustomCard(
          onTap: () {
            // Optional: Navigate to full health file
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  child: Text(m['full_name'][0] ?? '?'),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['full_name'] ?? AppLocalizations.of(context)!.unknown,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${AppLocalizations.of(context)!.age}: ${m['age'] ?? 'N/A'} • ${AppLocalizations.of(context)!.poa}: ${m['poa'] ?? 'N/A'}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      SizedBox(height: 8),
                      // Display Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: risks.isNotEmpty
                            ? risks.map((r) => _buildRiskBadge(r)).toList()
                            : [_buildRiskBadge("High Risk")], // Fallback
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiskBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.red.shade900,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
