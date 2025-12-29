import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/antenatal_plan.dart';

class AntenatalPlanForm extends StatefulWidget {
  final Map<String, dynamic> mother;

  AntenatalPlanForm({required this.mother});

  @override
  _AntenatalPlanFormState createState() => _AntenatalPlanFormState();
}

class _AntenatalPlanFormState extends State<AntenatalPlanForm> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Controllers ---
  final _nextClinicController = TextEditingController();

  // Classes
  final _class1DateController = TextEditingController();
  final _class1OtherController = TextEditingController();
  final _class2DateController = TextEditingController();
  final _class2OtherController = TextEditingController();
  final _class3DateController = TextEditingController();
  final _class3OtherController = TextEditingController();

  // Books (Issued/Returned)
  final _bookAntIssued = TextEditingController();
  final _bookAntReturned = TextEditingController();
  final _bookBreastIssued = TextEditingController();
  final _bookBreastReturned = TextEditingController();
  final _bookEccdIssued = TextEditingController();
  final _bookEccdReturned = TextEditingController();
  final _leafFpIssued = TextEditingController();
  final _leafFpReturned = TextEditingController();

  // Emergency
  final _emergNameController = TextEditingController();
  final _emergAddressController = TextEditingController();
  final _emergPhoneController = TextEditingController();
  final _mohPhoneController = TextEditingController();
  final _phmPhoneController = TextEditingController();
  final _gramaController = TextEditingController();

  // --- Booleans ---
  bool _c1Husband = false;
  bool _c1Wife = false;
  bool _c2Husband = false;
  bool _c2Wife = false;
  bool _c3Husband = false;
  bool _c3Wife = false;

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = picked.toIso8601String();
    }
  }

  Future<void> _submitForm() async {
    // 1. Validate
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix errors in red.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final plan = AntenatalPlan(
        motherId: widget.mother['id'],
        nextClinicDate: _nextClinicController.text.isNotEmpty
            ? _nextClinicController.text
            : null,

        class1stDate: _class1DateController.text.isNotEmpty
            ? _class1DateController.text
            : null,
        class1stHusband: _c1Husband,
        class1stWife: _c1Wife,
        class1stOther: _class1OtherController.text,

        class2ndDate: _class2DateController.text.isNotEmpty
            ? _class2DateController.text
            : null,
        class2ndHusband: _c2Husband,
        class2ndWife: _c2Wife,
        class2ndOther: _class2OtherController.text,

        class3rdDate: _class3DateController.text.isNotEmpty
            ? _class3DateController.text
            : null,
        class3rdHusband: _c3Husband,
        class3rdWife: _c3Wife,
        class3rdOther: _class3OtherController.text,

        bookAntenatalIssued: _bookAntIssued.text.isNotEmpty
            ? _bookAntIssued.text
            : null,
        bookAntenatalReturned: _bookAntReturned.text.isNotEmpty
            ? _bookAntReturned.text
            : null,
        bookBreastfeedingIssued: _bookBreastIssued.text.isNotEmpty
            ? _bookBreastIssued.text
            : null,
        bookBreastfeedingReturned: _bookBreastReturned.text.isNotEmpty
            ? _bookBreastReturned.text
            : null,
        bookEccdIssued: _bookEccdIssued.text.isNotEmpty
            ? _bookEccdIssued.text
            : null,
        bookEccdReturned: _bookEccdReturned.text.isNotEmpty
            ? _bookEccdReturned.text
            : null,
        leafletFpIssued: _leafFpIssued.text.isNotEmpty
            ? _leafFpIssued.text
            : null,
        leafletFpReturned: _leafFpReturned.text.isNotEmpty
            ? _leafFpReturned.text
            : null,

        emergencyContactName: _emergNameController.text,
        emergencyContactAddress: _emergAddressController.text,
        emergencyContactPhone: _emergPhoneController.text,
        mohOfficePhone: _mohPhoneController.text,
        phmPhone: _phmPhoneController.text,
        gramaNiladariDiv: _gramaController.text,
      );

      bool success = await _apiService.createAntenatalPlan(
        widget.mother['id'],
        plan,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plan Saved!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassRow(
    String title,
    TextEditingController dateCtrl,
    TextEditingController otherCtrl,
    bool husb,
    bool wife,
    Function(bool?) setHusb,
    Function(bool?) setWife,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: dateCtrl,
              decoration: InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today, size: 16),
              ),
              onTap: () => _selectDate(dateCtrl),
              readOnly: true,
            ),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: Text('Husband'),
                    value: husb,
                    onChanged: setHusb,
                    activeColor: Colors.teal,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: Text('Wife'),
                    value: wife,
                    onChanged: setWife,
                    activeColor: Colors.teal,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: otherCtrl,
              decoration: InputDecoration(labelText: 'Others'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookRow(
    String title,
    TextEditingController issuedCtrl,
    TextEditingController returnedCtrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: issuedCtrl,
                  decoration: InputDecoration(
                    labelText: 'Issued',
                    suffixIcon: Icon(Icons.arrow_outward, size: 14),
                  ),
                  onTap: () => _selectDate(issuedCtrl),
                  readOnly: true,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: returnedCtrl,
                  decoration: InputDecoration(
                    labelText: 'Returned',
                    suffixIcon: Icon(Icons.arrow_back, size: 14),
                  ),
                  onTap: () => _selectDate(returnedCtrl),
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Antenatal Plan', style: TextStyle(fontSize: 18)),
            Text(
              widget.mother['full_name'],
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode:
                  AutovalidateMode.onUserInteraction, // Validate live
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('Schedule', Icons.calendar_month),
                  TextFormField(
                    controller: _nextClinicController,
                    decoration: InputDecoration(
                      labelText: 'Date of Next Clinic Visit',
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(_nextClinicController),
                    readOnly: true,
                    validator: (v) =>
                        v!.isEmpty ? 'Required' : null, // Validation Added
                  ),

                  _buildSectionHeader('Antenatal Classes', Icons.group),
                  _buildClassRow(
                    '1st Trimester',
                    _class1DateController,
                    _class1OtherController,
                    _c1Husband,
                    _c1Wife,
                    (v) => setState(() => _c1Husband = v!),
                    (v) => setState(() => _c1Wife = v!),
                  ),
                  _buildClassRow(
                    '2nd Trimester',
                    _class2DateController,
                    _class2OtherController,
                    _c2Husband,
                    _c2Wife,
                    (v) => setState(() => _c2Husband = v!),
                    (v) => setState(() => _c2Wife = v!),
                  ),
                  _buildClassRow(
                    '3rd Trimester',
                    _class3DateController,
                    _class3OtherController,
                    _c3Husband,
                    _c3Wife,
                    (v) => setState(() => _c3Husband = v!),
                    (v) => setState(() => _c3Wife = v!),
                  ),

                  _buildSectionHeader('IEC Materials', Icons.menu_book),
                  _buildBookRow(
                    'Antenatal Book',
                    _bookAntIssued,
                    _bookAntReturned,
                  ),
                  _buildBookRow(
                    'Breast Feeding Books',
                    _bookBreastIssued,
                    _bookBreastReturned,
                  ),
                  _buildBookRow(
                    'ECCD Books',
                    _bookEccdIssued,
                    _bookEccdReturned,
                  ),
                  _buildBookRow(
                    'Family Planning Leaflet',
                    _leafFpIssued,
                    _leafFpReturned,
                  ),

                  _buildSectionHeader('Emergency Contact', Icons.emergency),
                  TextFormField(
                    controller: _emergNameController,
                    decoration: InputDecoration(
                      labelText: 'Contact Person Name',
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Required' : null, // Validation Added
                  ),
                  TextFormField(
                    controller: _emergAddressController,
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                  TextFormField(
                    controller: _emergPhoneController,
                    decoration: InputDecoration(labelText: 'Telephone No'),
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v!.isEmpty ? 'Required' : null, // Validation Added
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _mohPhoneController,
                    decoration: InputDecoration(labelText: 'MOH Office Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: _phmPhoneController,
                    decoration: InputDecoration(labelText: 'PHM Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: _gramaController,
                    decoration: InputDecoration(
                      labelText: 'Grama Niladari Division',
                    ),
                  ),

                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('SAVE PLAN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
