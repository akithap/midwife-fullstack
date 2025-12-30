import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/mother.dart';
import '../services/api_service.dart';

class ANCRecordScreen extends StatefulWidget {
  final Appointment appointment;
  final Mother mother;

  ANCRecordScreen({required this.appointment, required this.mother});

  @override
  _ANCRecordScreenState createState() => _ANCRecordScreenState();
}

class _ANCRecordScreenState extends State<ANCRecordScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = true; // Default to true for new, false for existing
  bool _isNewRecord = true;

  // Clinical Fields
  final _poaController = TextEditingController();
  final _weightController = TextEditingController();
  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _fundalHeightController = TextEditingController();

  String _pallor = "Absent";
  String _oedema = "Absent";
  String _fetalLie = "Cephalic";
  String _fetalHeartSound = "Normal";
  String _fetalMovement = "+";
  String _urineSugar = "Neg";
  String _urineAlbumin = "Neg";

  // Health Education (Checkboxes)
  bool _nutrientSupplements = false;
  bool _counselNutrition = false;
  bool _counselDangerSigns = false;
  bool _counselFamilyPlanning = false;
  bool _counselBreastfeeding = false;
  bool _counselDeliveryPlan = false;
  bool _counselEmergencyPrep = false;
  bool _counselPostnatalCare = false;

  @override
  void initState() {
    super.initState();
    _calculatePOA();
    _fetchExistingData();
  }

  void _calculatePOA() {
    if (widget.mother.pregnancyStartDate != null) {
      final lmp = widget.mother.pregnancyStartDate!;
      final today = DateTime.now();
      final diff = today.difference(lmp).inDays;
      final weeks = (diff / 7).floor();
      final days = diff % 7;
      _poaController.text = "$weeks + $days";
    }
  }

  Future<void> _fetchExistingData() async {
    try {
      final data = await _apiService.getANCVisit(widget.appointment.id);
      if (data != null) {
        setState(() {
          _isNewRecord = false;
          _isEditing = false; // Lock by default

          _poaController.text = data['poa_weeks'] ?? _poaController.text;
          _weightController.text = data['weight_kg']?.toString() ?? '';
          _bpSystolicController.text = data['bp_systolic']?.toString() ?? '';
          _bpDiastolicController.text = data['bp_diastolic']?.toString() ?? '';
          _fundalHeightController.text =
              data['fundal_height_cm']?.toString() ?? '';

          _pallor = data['pallor'] ?? "Absent";
          _oedema = data['oedema'] ?? "Absent";
          _fetalLie = data['fetal_lie'] ?? "Cephalic";
          _fetalHeartSound = data['fetal_heart_sound'] ?? "Normal";
          _fetalMovement = data['fetal_movement'] ?? "+";
          _urineSugar = data['urine_sugar'] ?? "Neg";
          _urineAlbumin = data['urine_albumin'] ?? "Neg";

          _nutrientSupplements = data['nutrient_supplements'] ?? false;
          _counselNutrition = data['counsel_nutrition'] ?? false;
          _counselDangerSigns = data['counsel_danger_signs'] ?? false;
          _counselFamilyPlanning = data['counsel_family_planning'] ?? false;
          _counselBreastfeeding = data['counsel_breastfeeding'] ?? false;
          _counselDeliveryPlan = data['counsel_delivery_plan'] ?? false;
          _counselEmergencyPrep = data['counsel_emergency_prep'] ?? false;
          _counselPostnatalCare = data['counsel_postnatal_care'] ?? false;
        });
      }
    } catch (e) {
      // 404 means no record, which is fine for new entry
      print("No existing record found: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    final data = {
      "mother_id": widget.mother.id,
      "appointment_id": widget.appointment.id,
      "visit_date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "poa_weeks": _poaController.text,
      "weight_kg": double.tryParse(_weightController.text),
      "bp_systolic": int.tryParse(_bpSystolicController.text),
      "bp_diastolic": int.tryParse(_bpDiastolicController.text),
      "pallor": _pallor,
      "oedema": _oedema,
      "fundal_height_cm": double.tryParse(_fundalHeightController.text),
      "fetal_lie": _fetalLie,
      "fetal_heart_sound": _fetalHeartSound,
      "fetal_movement": _fetalMovement,
      "urine_sugar": _urineSugar,
      "urine_albumin": _urineAlbumin,

      "nutrient_supplements": _nutrientSupplements,
      "counsel_nutrition": _counselNutrition,
      "counsel_danger_signs": _counselDangerSigns,
      "counsel_family_planning": _counselFamilyPlanning,
      "counsel_breastfeeding": _counselBreastfeeding,
      "counsel_delivery_plan": _counselDeliveryPlan,
      "counsel_emergency_prep": _counselEmergencyPrep,
      "counsel_postnatal_care": _counselPostnatalCare,
    };

    try {
      await _apiService.createANCVisit(data);
      // Also mark appointment as completed
      await _apiService.updateAppointment(widget.appointment.id, {
        "status": "Completed",
      });

      Navigator.pop(context, true); // Return true to refresh
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ANC Record Saved Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  bool _validate() {
    if (_weightController.text.isEmpty || _bpSystolicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill mandatory vitals (Weight, BP)")),
      );
      return false;
    }
    return true;
  }

  int _getPOAWeeks() {
    // Helper to extract numeric weeks mainly for logic
    try {
      return int.parse(_poaController.text.split(' ')[0]);
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show Postnatal advice only if 3rd trimester (> 28 weeks)
    bool showPostnatal = _getPOAWeeks() >= 28;

    return Scaffold(
      appBar: AppBar(
        title: Text("ANC Visit Record"),
        backgroundColor: Colors.teal,
        actions: [
          if (!_isEditing && !_isNewRecord)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle("Clinical Vitals"),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            "POA (Weeks)",
                            _poaController,
                            readOnly: !_isEditing,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  "Weight (kg)",
                                  _weightController,
                                  isNumber: true,
                                  readOnly: !_isEditing,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  "Fundal Height (cm)",
                                  _fundalHeightController,
                                  isNumber: true,
                                  readOnly: !_isEditing,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  "BP Systolic",
                                  _bpSystolicController,
                                  isNumber: true,
                                  readOnly: !_isEditing,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  "BP Diastolic",
                                  _bpDiastolicController,
                                  isNumber: true,
                                  readOnly: !_isEditing,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildDropdown(
                            "Pallor",
                            ["Absent", "Present"],
                            _pallor,
                            (v) => setState(() => _pallor = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Oedema",
                            ["Absent", "+", "++"],
                            _oedema,
                            (v) => setState(() => _oedema = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Fetal Lie",
                            ["Cephalic", "Breech", "Transverse", "Oblique"],
                            _fetalLie,
                            (v) => setState(() => _fetalLie = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Fetal Heart Sound",
                            ["Normal", "Not Heard", "< 110", "> 160"],
                            _fetalHeartSound,
                            (v) => setState(() => _fetalHeartSound = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Fetal Movement",
                            ["+", "-", "Reduced"],
                            _fetalMovement,
                            (v) => setState(() => _fetalMovement = v!),
                            enabled: _isEditing,
                          ),

                          Divider(),
                          Text(
                            "Urine Test",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  "Sugar",
                                  ["Neg", "+", "++"],
                                  _urineSugar,
                                  (v) => setState(() => _urineSugar = v!),
                                  enabled: _isEditing,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdown(
                                  "Albumin",
                                  ["Neg", "+", "++"],
                                  _urineAlbumin,
                                  (v) => setState(() => _urineAlbumin = v!),
                                  enabled: _isEditing,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                  _buildSectionTitle("Health Education & Counsel"),
                  Card(
                    elevation: 2,
                    child: Column(
                      children: [
                        _buildCheckbox(
                          "Given Iron/Calcium/Vitamins?",
                          _nutrientSupplements,
                          (v) => setState(() => _nutrientSupplements = v!),
                        ),
                        _buildCheckbox(
                          "Nutrition Advised",
                          _counselNutrition,
                          (v) => setState(() => _counselNutrition = v!),
                        ),
                        _buildCheckbox(
                          "Danger Signs Explained",
                          _counselDangerSigns,
                          (v) => setState(() => _counselDangerSigns = v!),
                        ),
                        _buildCheckbox(
                          "Family Planning Discussed",
                          _counselFamilyPlanning,
                          (v) => setState(() => _counselFamilyPlanning = v!),
                        ),
                        _buildCheckbox(
                          "Breastfeeding Advised",
                          _counselBreastfeeding,
                          (v) => setState(() => _counselBreastfeeding = v!),
                        ),
                        _buildCheckbox(
                          "Delivery Plan Discussed",
                          _counselDeliveryPlan,
                          (v) => setState(() => _counselDeliveryPlan = v!),
                        ),
                        _buildCheckbox(
                          "Emergency Prep Discussed",
                          _counselEmergencyPrep,
                          (v) => setState(() => _counselEmergencyPrep = v!),
                        ),
                        if (showPostnatal)
                          Container(
                            color: Colors.orange.shade50,
                            child: _buildCheckbox(
                              "Postnatal Care Advised (Last Trimester)",
                              _counselPostnatalCare,
                              (v) => setState(() => _counselPostnatalCare = v!),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),
                  if (_isEditing)
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text(_isSaving ? "Saving..." : "Save Record"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                      onPressed: _isSaving ? null : _saveData,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[100] : null,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            onChanged: enabled ? onChanged : null,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: _isEditing ? onChanged : null,
      activeColor: Colors.teal,
    );
  }
}
