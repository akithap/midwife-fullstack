import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyDeliveryScreen extends StatefulWidget {
  // Use 'key' in constructor for best practices (fixes warning)
  const MyDeliveryScreen({super.key});

  @override
  _MyDeliveryScreenState createState() => _MyDeliveryScreenState();
}

// Removed leading underscore to make State public if needed, but keeping private is fine for this file.
class _MyDeliveryScreenState extends State<MyDeliveryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.getMyDeliveryRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Delivery Records'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error loading records'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No records found.'));

          final records = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIXED: Removed backslashes from string interpolation
                      Text(
                        'Delivery #${r['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.purple,
                        ),
                      ),
                      Divider(),
                      _row('Date', r['delivery_date']?.split('T')[0]),
                      _row('Mode', r['delivery_mode']),
                      // FIXED: Removed backslashes from string interpolation
                      _row('Birth Weight', '${r['birth_weight']} kg'),
                      _row('Abnormalities', r['abnormalities']),
                      _row(
                        'Discharge Date',
                        r['discharge_date']?.split('T')[0],
                      ),
                      _row('Special Notes', r['special_notes']),
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

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
