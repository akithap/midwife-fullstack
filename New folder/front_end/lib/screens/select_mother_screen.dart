import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/mother.dart';
import 'pregnancy_record_form.dart';
import 'delivery_record_form.dart';
import 'antenatal_plan_form.dart';
import 'mother_health_file_screen.dart';
import 'dart:async';

class SelectMotherScreen extends StatefulWidget {
  final String formType; // 'pregnancy', 'delivery', 'antenatal', 'health_file'

  SelectMotherScreen({required this.formType});

  @override
  _SelectMotherScreenState createState() => _SelectMotherScreenState();
}

class _SelectMotherScreenState extends State<SelectMotherScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Mother>> _mothersFuture;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadMothers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMothers({String? query}) {
    setState(() {
      _mothersFuture = _apiService.getMothers(query: query);
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadMothers(query: query);
    });
  }

  void _onMotherSelected(Mother mother) {
    if (widget.formType == 'pregnancy') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PregnancyRecordForm(mother: mother.toJson()),
        ),
      );
    } else if (widget.formType == 'delivery') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryRecordForm(mother: mother.toJson()),
        ),
      );
    } else if (widget.formType == 'antenatal') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AntenatalPlanForm(mother: mother.toJson()),
        ),
      );
    } else if (widget.formType == 'health_file') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MotherHealthFileScreen(mother: mother),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Mother"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search by Name or NIC",
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadMothers();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Mother>>(
                future: _mothersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No mothers found"));
                  }

                  final mothers = snapshot.data!;
                  return ListView.builder(
                    itemCount: mothers.length,
                    itemBuilder: (context, index) {
                      final mother = mothers[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text(
                              mother.fullName[0].toUpperCase(),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            mother.fullName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("NIC: ${mother.nic}"),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () => _onMotherSelected(mother),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
