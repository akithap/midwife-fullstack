import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyAntenatalScreen extends StatefulWidget {
  @override
  _MyAntenatalScreenState createState() => _MyAntenatalScreenState();
}

class _MyAntenatalScreenState extends State<MyAntenatalScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.getMyAntenatalPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Antenatal Plan'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error loading records'));
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('No plan found.'));

          final plan = snapshot.data![0]; // Show the first plan
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.orange),
                  title: Text('Next Clinic Visit'),
                  // Fixed String Interpolation
                  subtitle: Text(
                    plan['next_clinic_date'] != null
                        ? plan['next_clinic_date'].split('T')[0]
                        : 'Not Scheduled',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 16),

              Text(
                'Classes Attended',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _classCard('1st Trimester', plan['class_1st_date']),
              _classCard('2nd Trimester', plan['class_2nd_date']),
              _classCard('3rd Trimester', plan['class_3rd_date']),

              SizedBox(height: 16),
              Text(
                'Emergency Contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Name', plan['emergency_contact_name']),
                      _row('Phone', plan['emergency_contact_phone']),
                      _row('MOH Office', plan['moh_office_phone']),
                      _row('PHM Phone', plan['phm_phone']),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _classCard(String title, String? date) {
    bool attended = date != null;
    // Fixed String Interpolation syntax here
    String dateText = attended
        ? "Date: ${date.split('T')[0]}"
        : "Not yet attended";

    return Card(
      color: attended ? Colors.green[50] : Colors.grey[50],
      child: ListTile(
        title: Text(title),
        trailing: Icon(
          attended ? Icons.check_circle : Icons.radio_button_unchecked,
          color: attended ? Colors.green : Colors.grey,
        ),
        subtitle: Text(dateText),
      ),
    );
  }

  Widget _row(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Text(value ?? 'N/A'),
        ],
      ),
    );
  }
}
