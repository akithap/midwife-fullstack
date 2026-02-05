import 'package:flutter/material.dart';
import 'package:front_end/l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.myAntenatalPlan),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Text(AppLocalizations.of(context)!.errorLoadingMeetings),
            );
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(
              child: Text(AppLocalizations.of(context)!.noPlanFound),
            );

          final plan = snapshot.data![0]; // Show the first plan
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.orange),
                  title: Text(AppLocalizations.of(context)!.nextClinicVisit),
                  // Fixed String Interpolation
                  subtitle: Text(
                    plan['next_clinic_date'] != null
                        ? plan['next_clinic_date'].split('T')[0]
                        : AppLocalizations.of(context)!.notScheduled,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 16),

              Text(
                AppLocalizations.of(context)!.classesAttended,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              _classCard(
                AppLocalizations.of(context)!.firstTrimester,
                plan['class_1st_date'],
              ),
              _classCard(
                AppLocalizations.of(context)!.secondTrimester,
                plan['class_2nd_date'],
              ),
              _classCard(
                AppLocalizations.of(context)!.thirdTrimester,
                plan['class_3rd_date'],
              ),

              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.emergencyContact,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row(
                        AppLocalizations.of(context)!.name,
                        plan['emergency_contact_name'],
                      ),
                      _row(
                        AppLocalizations.of(context)!.phone,
                        plan['emergency_contact_phone'],
                      ),
                      _row(
                        AppLocalizations.of(context)!.mohOffice,
                        plan['moh_office_phone'],
                      ),
                      _row(
                        AppLocalizations.of(context)!.phmPhone,
                        plan['phm_phone'],
                      ),
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
        ? "${AppLocalizations.of(context)!.date}: ${date.split('T')[0]}"
        : AppLocalizations.of(context)!.notYetAttended;

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
