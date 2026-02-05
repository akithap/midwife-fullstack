import 'package:flutter/material.dart';
import 'package:front_end/l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.myPregnancyRecords),
        backgroundColor: Colors.pink,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: Text(AppLocalizations.of(context)!.errorLoadingMeetings),
            ); // Reusing generic error or create new
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(
              child: Text(AppLocalizations.of(context)!.noRecordsFound),
            );

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
                      Text(
                        '${AppLocalizations.of(context)!.recordNumber}${r['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.pink,
                        ),
                      ),
                      Divider(),
                      _row(
                        AppLocalizations.of(context)!.bloodGroup,
                        r['blood_group'],
                      ),
                      _row(AppLocalizations.of(context)!.bmi, '${r['bmi']}'),
                      _row(
                        AppLocalizations.of(context)!.height,
                        '${r['height_cm']}',
                      ),
                      _row(
                        AppLocalizations.of(context)!.allergies,
                        r['allergies'],
                      ),
                      _row(
                        AppLocalizations.of(context)!.riskFactors,
                        r['identified_risks'],
                      ),
                      _row(
                        AppLocalizations.of(context)!.edd,
                        r['edd'] != null ? r['edd'].split('T')[0] : 'N/A',
                      ),
                      _row(
                        AppLocalizations.of(context)!.lrmp,
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
