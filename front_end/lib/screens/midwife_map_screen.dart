import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/mother.dart';
import 'mother_health_file_screen.dart'; // To open profile

class MidwifeMapScreen extends StatefulWidget {
  @override
  _MidwifeMapScreenState createState() => _MidwifeMapScreenState();
}

class _MidwifeMapScreenState extends State<MidwifeMapScreen> {
  final ApiService _apiService = ApiService();
  List<Mother> _mothers = [];
  bool _isLoading = true;
  LatLng _initialCenter = LatLng(6.9271, 79.8612); // Default: Colombo

  // Search & Filter State
  String _searchQuery = "";
  final Set<String> _selectedFilters = {
    'Eligible',
    'Low Risk',
    'High Risk',
    'Postnatal',
  };
  List<Mother> _filteredMothers = [];
  final TextEditingController _searchController = TextEditingController();
  Set<int> _todaysMotherIds = {}; // Store IDs of mothers to visit today

  @override
  void initState() {
    super.initState();
    _loadData();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _initialCenter = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Keep default
    }
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch Mothers
      final mothers = await _apiService.getMothers();

      // 2. Fetch Today's Appointments
      final now = DateTime.now();
      final appointments = await _apiService.getMidwifeAppointments(date: now);
      final appointmentMotherIds = appointments.map((a) => a.motherId).toSet();

      setState(() {
        _mothers = mothers;
        _todaysMotherIds = appointmentMotherIds;
        _updateFilteredMothers();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading map data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Midwife Field Map"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData(); // Reload everything
            },
            tooltip: "Refresh Map Data",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _initialCenter,
                    initialZoom: 13.0,
                    interactionOptions: InteractionOptions(
                      flags:
                          InteractiveFlag.all &
                          ~InteractiveFlag.rotate, // Disable rotation
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.midwife.app',
                    ),
                    MarkerLayer(
                      markers: _filteredMothers.where((m) => m.hasLocation).map(
                        (mother) {
                          return Marker(
                            point: LatLng(mother.latitude!, mother.longitude!),
                            width: 80,
                            height: 80,
                            child: GestureDetector(
                              onTap: () {
                                _showMotherInfo(context, mother);
                              },
                              child: _buildMarkerIcon(mother),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ],
                ),
                // SEARCH & FILTERS (Replaces user's old Legend)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Column(
                    children: [
                      // Search Bar
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search mother by name...",
                            prefixIcon: Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = "";
                                        _updateFilteredMothers();
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _updateFilteredMothers();
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 8),
                      // Filter Chips
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.zero,
                        child: Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildFilterChip(
                              "Today's Visits",
                              Colors.orange,
                              Icons.calendar_today,
                            ),
                            _buildFilterChip(
                              "High Risk",
                              Colors.red,
                              Icons.warning_rounded,
                            ),
                            _buildFilterChip(
                              "Low Risk",
                              Colors.green,
                              Icons.location_on,
                            ),
                            _buildFilterChip(
                              "Eligible",
                              Colors.blue,
                              Icons.person_pin_circle,
                            ),
                            _buildFilterChip(
                              "Postnatal",
                              Colors.purple,
                              Icons.child_care,
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

  void _updateFilteredMothers() {
    setState(() {
      _filteredMothers = _mothers.where((m) {
        // 1. Text Search
        final matchesName = m.fullName.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );

        // 2. "Today's Visits" Filter (Special Case)
        // If selected, mother MUST be in the today list.
        bool matchesToday = true;
        if (_selectedFilters.contains("Today's Visits")) {
          matchesToday = _todaysMotherIds.contains(m.id);
        }
        if (!matchesToday) return false;

        // 3. Category Filter
        // Calculate active categories excluding "Today's Visits"
        final categoryFilters = _selectedFilters
            .where((f) => f != "Today's Visits")
            .toSet();

        // If no category filters are active (only search or today), show all valid matches for those.
        // But if user HAS selected categories, we must match at least one.
        bool matchesCategory = true;
        if (categoryFilters.isNotEmpty) {
          final category = _getMotherCategory(m);
          matchesCategory = categoryFilters.contains(category);
        }

        return matchesName && matchesToday && matchesCategory;
      }).toList();
    });
  }

  String _getMotherCategory(Mother m) {
    if (m.status == 'Eligible') return 'Eligible';
    if (m.status == 'Postnatal') return 'Postnatal';
    // Pregnant
    if (m.riskLevel == 'High') return 'High Risk';
    return 'Low Risk';
  }

  Widget _buildFilterChip(String label, Color color, IconData icon) {
    final isSelected = _selectedFilters.contains(label);
    return FilterChip(
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedFilters.add(label);
          } else {
            _selectedFilters.remove(label);
          }
          _updateFilteredMothers();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color.withOpacity(1.0),
      side: BorderSide(
        color: isSelected ? Colors.transparent : color.withOpacity(0.5),
        width: 1,
      ),
      shape: StadiumBorder(),
    );
  }

  Widget _buildMarkerIcon(Mother mother) {
    if (mother.status == 'Eligible') {
      return Icon(Icons.person_pin_circle, color: Colors.blue, size: 40);
    } else if (mother.status == 'Postnatal') {
      return Icon(Icons.child_care, color: Colors.purple, size: 40);
    } else {
      // Pregnant
      if (mother.riskLevel == 'High') {
        return Icon(Icons.warning_rounded, color: Colors.red, size: 40);
      } else {
        return Icon(Icons.location_on, color: Colors.green, size: 40);
      }
    }
  }

  void _showMotherInfo(BuildContext context, Mother mother) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildMarkerIcon(mother), // Use same icon
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mother.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Status: ${mother.status}",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 32),
            Text("Address:", style: TextStyle(fontWeight: FontWeight.w600)),
            Text(mother.address),
            SizedBox(height: 16),
            Text("Risk Level:", style: TextStyle(fontWeight: FontWeight.w600)),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: mother.riskLevel == 'High'
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mother.riskLevel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: mother.riskLevel == 'High' ? Colors.red : Colors.green,
                ),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MotherHealthFileScreen(mother: mother),
                    ),
                  );
                },
                icon: Icon(Icons.folder_open),
                label: Text("View Health File"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
