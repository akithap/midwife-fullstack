import 'package:flutter/material.dart';
import 'select_mother_screen.dart';

class RecordDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Health Forms Dashboard'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select a Form to Fill',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // Option 1: Pregnancy Record
            _buildFormButton(
              context,
              label: 'Pregnancy Record',
              icon: Icons.pregnant_woman,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SelectMotherScreen(formType: 'pregnancy'),
                  ),
                );
              },
            ),
            SizedBox(height: 16),

            // Option 2: Delivery & Postnatal
            _buildFormButton(
              context,
              label: 'Delivery & Postnatal Care',
              icon: Icons.child_friendly,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SelectMotherScreen(formType: 'delivery'),
                  ),
                );
              },
            ),
            SizedBox(height: 16),

            // Option 3: Antenatal Plan (FIXED)
            _buildFormButton(
              context,
              label: 'Antenatal Plan',
              icon: Icons.calendar_today,
              onTap: () {
                // FIXED: Now navigates to Select Mother with 'antenatal' type
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SelectMotherScreen(formType: 'antenatal'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.teal, width: 1),
        ),
      ),
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      onPressed: onTap,
    );
  }
}
