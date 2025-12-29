import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/delivery_record.dart';

class DeliveryRecordForm extends StatefulWidget {
  final Map<String, dynamic> mother;

  DeliveryRecordForm({required this.mother});

  @override
  _DeliveryRecordFormState createState() => _DeliveryRecordFormState();
}

class _DeliveryRecordFormState extends State<DeliveryRecordForm> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers - REMOVED default "None" text to force validation
  final _deliveryDateController = TextEditingController();
  final _complicationsController = TextEditingController(); // Was "None"
  final _birthWeightController = TextEditingController();
  final _poaBirthController = TextEditingController();
  final _apgarController = TextEditingController();
  final _abnormalitiesController = TextEditingController(); // Was "None"
  final _notesController = TextEditingController(); // Was "None"
  final _dischargeDateController = TextEditingController();

  // State Variables
  String _deliveryMode = 'Normal Vaginal';
  bool _episiotomy = false;
  bool _tempNormal = false;
  bool _vaginalExam = false;
  bool _woundInfection = false;
  bool _familyPlanning = false;
  bool _dangerSignals = false;
  bool _breastFeeding = false;

  bool _vitaminA = false;
  bool _rubella = false;
  bool _antiD = false;
  bool _diagnosisCard = false;
  bool _chdr = false;
  bool _prescription = false;
  bool _referred = false;

  final List<String> _deliveryModes = [
    'Normal Vaginal',
    'Forceps',
    'Vacuum',
    'LSCS',
  ];

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
    // 1. Trigger Validation
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors in red before saving.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return; // Stop here if invalid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final record = DeliveryRecord(
        motherId: widget.mother['id'],
        deliveryDate: _deliveryDateController.text.isNotEmpty
            ? _deliveryDateController.text
            : null,
        deliveryMode: _deliveryMode,
        episiotomy: _episiotomy,
        tempNormal: _tempNormal,
        vaginalExamDone: _vaginalExam,
        maternalComplications: _complicationsController.text,
        woundInfection: _woundInfection,
        familyPlanningDiscussed: _familyPlanning,
        dangerSignalsExplained: _dangerSignals,
        breastFeedingEstablished: _breastFeeding,
        // Validation ensures these are valid numbers
        birthWeight: double.tryParse(_birthWeightController.text),
        poaAtBirth: int.tryParse(_poaBirthController.text),
        apgarScore: int.tryParse(_apgarController.text),
        abnormalities: _abnormalitiesController.text,
        vitaminAGiven: _vitaminA,
        rubellaGiven: _rubella,
        antiDGiven: _antiD,
        diagnosisCardGiven: _diagnosisCard,
        chdrCompleted: _chdr,
        prescriptionGiven: _prescription,
        referredToPhm: _referred,
        specialNotes: _notesController.text,
        dischargeDate: _dischargeDateController.text.isNotEmpty
            ? _dischargeDateController.text
            : null,
      );

      bool success = await _apiService.createDeliveryRecord(
        widget.mother['id'],
        record,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save. Check internet/server.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery & Postnatal', style: TextStyle(fontSize: 18)),
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
              autovalidateMode: AutovalidateMode
                  .onUserInteraction, // Show errors as user types
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // SECTION 1: DELIVERY
                  _buildSectionHeader('Delivery Details', Icons.local_hospital),
                  TextFormField(
                    controller: _deliveryDateController,
                    decoration: InputDecoration(
                      labelText: 'Date of Delivery',
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(_deliveryDateController),
                    readOnly: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Date is required' : null,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: _deliveryMode,
                    items: _deliveryModes
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _deliveryMode = v.toString()),
                    decoration: InputDecoration(
                      labelText: 'Mode of Delivery',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _complicationsController,
                    decoration: InputDecoration(
                      labelText: 'Maternal Complications',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required (Enter "None" if none)'
                        : null,
                  ),

                  // Booleans
                  SwitchListTile(
                    title: Text('Episiotomy?'),
                    value: _episiotomy,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _episiotomy = v),
                  ),
                  SwitchListTile(
                    title: Text('Body Temp Normal (Last 2 Days)?'),
                    value: _tempNormal,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _tempNormal = v),
                  ),
                  SwitchListTile(
                    title: Text('Vaginal Exam (Packs Checked)?'),
                    value: _vaginalExam,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _vaginalExam = v),
                  ),
                  SwitchListTile(
                    title: Text('Wound Infection?'),
                    value: _woundInfection,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _woundInfection = v),
                  ),
                  SwitchListTile(
                    title: Text('Family Planning Discussed?'),
                    value: _familyPlanning,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _familyPlanning = v),
                  ),
                  SwitchListTile(
                    title: Text('Danger Signals Explained?'),
                    value: _dangerSignals,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _dangerSignals = v),
                  ),
                  SwitchListTile(
                    title: Text('Breast Feeding Established?'),
                    value: _breastFeeding,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _breastFeeding = v),
                  ),

                  // SECTION 2: BABY
                  _buildSectionHeader('Baby Details', Icons.child_care),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _birthWeightController,
                          decoration: InputDecoration(
                            labelText: 'Birth Weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (double.tryParse(v) == null) return 'Invalid #';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _poaBirthController,
                          decoration: InputDecoration(
                            labelText: 'POA (Weeks)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _apgarController,
                          decoration: InputDecoration(
                            labelText: 'Apgar',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _abnormalitiesController,
                    decoration: InputDecoration(
                      labelText: 'Abnormalities',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required (Enter "None")'
                        : null,
                  ),

                  // SECTION 3: DISCHARGE
                  _buildSectionHeader(
                    'Postnatal & Discharge',
                    Icons.exit_to_app,
                  ),
                  SwitchListTile(
                    title: Text('Vitamin A Megadose?'),
                    value: _vitaminA,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _vitaminA = v),
                  ),
                  SwitchListTile(
                    title: Text('Rubella Immunization?'),
                    value: _rubella,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _rubella = v),
                  ),
                  SwitchListTile(
                    title: Text('Anti-D Given?'),
                    value: _antiD,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _antiD = v),
                  ),
                  SwitchListTile(
                    title: Text('Diagnosis Card Given?'),
                    value: _diagnosisCard,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _diagnosisCard = v),
                  ),
                  SwitchListTile(
                    title: Text('CHDR Completed?'),
                    value: _chdr,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _chdr = v),
                  ),
                  SwitchListTile(
                    title: Text('Prescription Given?'),
                    value: _prescription,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _prescription = v),
                  ),
                  SwitchListTile(
                    title: Text('Referred to Field Midwife?'),
                    value: _referred,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _referred = v),
                  ),

                  SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Special Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required (Enter "None")'
                        : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _dischargeDateController,
                    decoration: InputDecoration(
                      labelText: 'Date of Discharge',
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(_dischargeDateController),
                    readOnly: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Date is required' : null,
                  ),

                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('SAVE RECORD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
