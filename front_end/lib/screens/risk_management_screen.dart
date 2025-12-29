import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_card.dart';
import 'select_mother_screen.dart'; // For full mother details potentially

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("Risk Management"),
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
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
                "Filter by Risk Factor",
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
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "High Risk Cases",
            "${_stats['total_high_risk'] ?? 0}",
            Colors.red,
            Icons.warning_amber_rounded,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Diabetes Watch",
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
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
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
          label: Text(entry.value),
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
          child: Text("No mothers found for this risk category."),
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
                        m['full_name'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "Age: ${m['age'] ?? 'N/A'} • POA: ${m['poa'] ?? 'N/A'}",
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
