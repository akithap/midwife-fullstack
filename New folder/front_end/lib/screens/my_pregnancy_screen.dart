import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyPregnancyScreen extends StatefulWidget {
  // Use 'key' in constructor for best practices
  const MyPregnancyScreen({super.key});

  @override
  _MyPregnancyScreenState createState() => _MyPregnancyScreenState();
}

class _MyPregnancyScreenState extends State<MyPregnancyScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.getMyPregnancyRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Pregnancy Records'),
        backgroundColor: Colors.pink,
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
          // Just showing the latest one for simplicity, or list if multiple
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
                        'Record #${r['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.pink,
                        ),
                      ),
                      Divider(),
                      _row('Blood Group', r['blood_group']),
                      // FIXED: Removed backslashes
                      _row('BMI', '${r['bmi']}'),
                      _row('Height (cm)', '${r['height_cm']}'),
                      _row('Allergies', r['allergies']),
                      _row('Risks', r['identified_risks']),
                      // FIXED: Added null check before split
                      _row(
                        'EDD',
                        r['edd'] != null ? r['edd'].split('T')[0] : 'N/A',
                      ),
                      _row(
                        'LRMP',
                        r['lrmp'] != null ? r['lrmp'].split('T')[0] : 'N/A',
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
