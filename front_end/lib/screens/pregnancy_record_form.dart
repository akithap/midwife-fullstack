import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/pregnancy_record.dart';

class PregnancyRecordForm extends StatefulWidget {
  final Map<String, dynamic> mother;

  PregnancyRecordForm({required this.mother});

  @override
  _PregnancyRecordFormState createState() => _PregnancyRecordFormState();
}

class _PregnancyRecordFormState extends State<PregnancyRecordForm> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // --- Controllers ---
  final _bmiController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController(text: "None");
  final _risksController = TextEditingController(text: "None");
  final _gravidityController = TextEditingController();
  final _parityController = TextEditingController();
  final _childrenController = TextEditingController();
  final _youngestController = TextEditingController();
  final _lrmpController = TextEditingController();
  final _eddController = TextEditingController();
  final _usEddController = TextEditingController();
  final _poaController = TextEditingController();

  // --- State Variables ---
  String _bloodGroup = 'O+';
  bool _consanguinity = false;
  bool _rubella = false;
  bool _prePreg = false;
  bool _folic = false;
  bool _subfertility = false;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Helper: Select Date
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
      // Format: YYYY-MM-DDTHH:MM:SS
      controller.text = picked.toIso8601String();
    }
  }

  // Submit
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the errors in red.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final record = PregnancyRecord(
        motherId: widget.mother['id'],
        bloodGroup: _bloodGroup,
        bmi: double.tryParse(_bmiController.text),
        heightCm: double.tryParse(_heightController.text),
        allergies: _allergiesController.text,
        consanguinity: _consanguinity,
        rubellaImmunization: _rubella,
        prePregnancyScreening: _prePreg,
        folicAcid: _folic,
        subfertilityHistory: _subfertility,
        identifiedRisks: _risksController.text,
        gravidity: int.tryParse(_gravidityController.text),
        parity: int.tryParse(_parityController.text),
        livingChildren: int.tryParse(_childrenController.text),
        youngestChildAge: _youngestController.text,
        lrmp: _lrmpController.text.isNotEmpty ? _lrmpController.text : null,
        edd: _eddController.text.isNotEmpty ? _eddController.text : null,
        usCorrectedEdd: _usEddController.text.isNotEmpty
            ? _usEddController.text
            : null,
        poaAtRegistration: _poaController.text,
      );

      bool success = await _apiService.createPregnancyRecord(
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
              content: Text('Record Saved Successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Back to Mother Selection
          Navigator.pop(context); // Back to Dashboard
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save data.'),
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

  // Helper: Section Header
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
        // FIXED: Removed 'subtitle' parameter. Used a Column for title/subtitle layout.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Pregnancy Record', style: TextStyle(fontSize: 18)),
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
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // --- SECTION 1: VITALS ---
                  _buildSectionHeader('Physical Vitals', Icons.accessibility),

                  DropdownButtonFormField(
                    value: _bloodGroup,
                    items: _bloodGroups
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _bloodGroup = v.toString()),
                    decoration: InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          decoration: InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _bmiController,
                          decoration: InputDecoration(
                            labelText: 'BMI',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: InputDecoration(
                      labelText: 'Allergies',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),

                  // --- SECTION 2: MEDICAL CHECKLIST ---
                  _buildSectionHeader(
                    'Medical Checks',
                    Icons.health_and_safety,
                  ),
                  SwitchListTile(
                    title: Text('Rubella Immunized?'),
                    value: _rubella,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _rubella = v),
                  ),
                  SwitchListTile(
                    title: Text('Folic Acid?'),
                    value: _folic,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _folic = v),
                  ),
                  SwitchListTile(
                    title: Text('Consanguinity?'),
                    value: _consanguinity,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _consanguinity = v),
                  ),
                  SwitchListTile(
                    title: Text('Subfertility History?'),
                    value: _subfertility,
                    activeColor: Colors.teal,
                    onChanged: (v) => setState(() => _subfertility = v),
                  ),

                  // --- SECTION 3: OBSTETRIC HISTORY ---
                  _buildSectionHeader('Obstetric History', Icons.history),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _gravidityController,
                          decoration: InputDecoration(
                            labelText: 'G (Gravidity)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _parityController,
                          decoration: InputDecoration(
                            labelText: 'P (Parity)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _childrenController,
                          decoration: InputDecoration(
                            labelText: 'C (Children)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _risksController,
                    decoration: InputDecoration(
                      labelText: 'Identified Risks',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),

                  // --- SECTION 4: TIMELINE ---
                  _buildSectionHeader('Timeline', Icons.calendar_month),
                  TextFormField(
                    controller: _lrmpController,
                    decoration: InputDecoration(
                      labelText: 'LRMP',
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(_lrmpController),
                    readOnly: true,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _eddController,
                    decoration: InputDecoration(
                      labelText: 'EDD',
                      suffixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () => _selectDate(_eddController),
                    readOnly: true,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _poaController,
                    decoration: InputDecoration(
                      labelText: 'POA at Registration (Weeks)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
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
