import 'package:flutter/material.dart';
import 'package:front_end/l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.myDeliveryRecords),
        backgroundColor: Colors.purple,
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
              child: Text(AppLocalizations.of(context)!.noRecordsFound),
            );

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
                        '${AppLocalizations.of(context)!.deliveryNumber}${r['id']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.purple,
                        ),
                      ),
                      Divider(),
                      _row(
                        AppLocalizations.of(context)!.date,
                        r['delivery_date']?.split('T')[0],
                      ),
                      _row(
                        AppLocalizations.of(context)!.deliveryMode,
                        r['delivery_mode'],
                      ),
                      // FIXED: Removed backslashes from string interpolation
                      _row(
                        AppLocalizations.of(context)!.birthWeight,
                        '${r['birth_weight']} kg',
                      ),
                      _row(
                        AppLocalizations.of(context)!.abnormalities,
                        r['abnormalities'],
                      ),
                      _row(
                        AppLocalizations.of(context)!.dischargeDate,
                        r['discharge_date']?.split('T')[0],
                      ),
                      _row(
                        AppLocalizations.of(context)!.specialNotes,
                        r['special_notes'],
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
