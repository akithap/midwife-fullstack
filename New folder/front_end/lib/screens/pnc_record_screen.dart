import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/mother.dart';
import '../services/api_service.dart';

class PNCRecordScreen extends StatefulWidget {
  final Appointment appointment;
  final Mother mother;

  PNCRecordScreen({required this.appointment, required this.mother});

  @override
  _PNCRecordScreenState createState() => _PNCRecordScreenState();
}

class _PNCRecordScreenState extends State<PNCRecordScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = true;
  bool _isNewRecord = true;

  // --- Mother Fields ---
  final _temperatureController = TextEditingController();
  String _pallor = "Absent";
  String _breastCondition = "Normal";
  String _uterusInvolution = "Contracted";
  String _lochiaCharacter = "Red";
  String _lochiaSmell = "Normal";

  bool _perineumInfection = false;
  bool _fissureInfection = false;
  bool _vitaminAGiven = false;

  String _familyPlanningMethod =
      "None"; // None, Pill, Implant, LRT, Injection, Condom
  bool _referredToHospital = false;

  // --- Baby Fields ---
  final _babyWeightController = TextEditingController();
  String _babyColor = "Pink";
  String _cordStatus = "Normal"; // Normal, Bleeding, Infected
  String _breastfeeding =
      "Good Sucking"; // Good Sucking, Poor Sucking, Not Establishing
  String _babyStool = "Passed"; // Passed, Not Passed

  @override
  void initState() {
    super.initState();
    _fetchExistingData();
  }

  Future<void> _fetchExistingData() async {
    try {
      final data = await _apiService.getPNCVisit(widget.appointment.id);
      if (data != null) {
        setState(() {
          _isNewRecord = false;
          _isEditing = false;

          // Mother
          _temperatureController.text = data['temperature']?.toString() ?? '';
          _pallor = data['pallor'] ?? "Absent";
          _breastCondition = data['breast_condition'] ?? "Normal";
          _uterusInvolution = data['uterus_involution'] ?? "Contracted";
          _lochiaCharacter = data['lochia_character'] ?? "Red";
          _lochiaSmell = data['lochia_smell'] ?? "Normal";
          _perineumInfection = data['perineum_infection'] ?? false;
          _fissureInfection = data['fissure_infection'] ?? false;
          _vitaminAGiven = data['vitamin_a_given'] ?? false;
          _familyPlanningMethod = data['family_planning_method'] ?? "None";
          _referredToHospital = data['referred_to_hospital'] ?? false;

          // Baby
          _babyWeightController.text = data['baby_weight']?.toString() ?? '';
          _babyColor = data['baby_color'] ?? "Pink";
          _cordStatus = data['cord_status'] ?? "Normal";
          _breastfeeding = data['breastfeeding'] ?? "Good Sucking";
          _babyStool = data['baby_stool'] ?? "Passed";
        });
      }
    } catch (e) {
      print("No existing PNC record: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);

    final data = {
      "mother_id": widget.mother.id,
      "appointment_id": widget.appointment.id,
      "visit_date": DateFormat('yyyy-MM-dd').format(DateTime.now()),

      // Mother
      "temperature": double.tryParse(_temperatureController.text),
      "pallor": _pallor,
      "breast_condition": _breastCondition,
      "uterus_involution": _uterusInvolution,
      "lochia_character": _lochiaCharacter,
      "lochia_smell": _lochiaSmell,
      "perineum_infection": _perineumInfection,
      "fissure_infection": _fissureInfection,
      "vitamin_a_given": _vitaminAGiven,
      "family_planning_method": _familyPlanningMethod,
      "referred_to_hospital": _referredToHospital,

      // Baby
      "baby_weight": double.tryParse(_babyWeightController.text),
      "baby_color": _babyColor,
      "cord_status": _cordStatus,
      "breastfeeding": _breastfeeding,
      "baby_stool": _babyStool,
    };

    try {
      await _apiService.createPNCVisit(data);
      await _apiService.updateAppointment(widget.appointment.id, {
        "status": "Completed",
      });

      Navigator.pop(context, true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("PNC Record Saved Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PNC Visit Record"),
        backgroundColor: Colors.purple.shade300,
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
                  // --- Mother Section ---
                  _buildSectionHeader(
                    "Mother's Condition",
                    Icons.pregnant_woman,
                  ),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            "Temperature (°C)",
                            _temperatureController,
                            isNumber: true,
                            readOnly: !_isEditing,
                          ),
                          _buildDropdown(
                            "Pallor",
                            ["Absent", "Present", "Clinically Anemic"],
                            _pallor,
                            (v) => setState(() => _pallor = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Breast Condition",
                            ["Normal", "Cracked", "Engorged", "Infected"],
                            _breastCondition,
                            (v) => setState(() => _breastCondition = v!),
                            enabled: _isEditing,
                          ),

                          Divider(),
                          _buildDropdown(
                            "Uterus Involution",
                            [
                              "Contracted",
                              "Boggy",
                              "Sub-involution",
                              "Measurable",
                            ],
                            _uterusInvolution,
                            (v) => setState(() => _uterusInvolution = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Lochia Character",
                            ["Red", "Pink", "White", "Excessive"],
                            _lochiaCharacter,
                            (v) => setState(() => _lochiaCharacter = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Lochia Smell",
                            ["Normal", "Foul"],
                            _lochiaSmell,
                            (v) => setState(() => _lochiaSmell = v!),
                            enabled: _isEditing,
                          ),

                          Divider(),
                          _buildDropdown(
                            "Perineum Infection (Gaping)?",
                            ["No", "Yes"],
                            _perineumInfection ? "Yes" : "No",
                            (v) => setState(
                              () => _perineumInfection = (v == "Yes"),
                            ),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "C-Section/Episiotomy Infection?",
                            ["No", "Yes"],
                            _fissureInfection ? "Yes" : "No",
                            (v) => setState(
                              () => _fissureInfection = (v == "Yes"),
                            ),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Vitamin A Mega Dose Given?",
                            ["No", "Yes"],
                            _vitaminAGiven ? "Yes" : "No",
                            (v) =>
                                setState(() => _vitaminAGiven = (v == "Yes")),
                            enabled: _isEditing,
                          ),
                          SizedBox(height: 8),
                          _buildDropdown(
                            "Family Planning Method",
                            [
                              "None",
                              "Pill",
                              "Implant",
                              "LRT",
                              "Injection",
                              "Condom",
                            ],
                            _familyPlanningMethod,
                            (v) => setState(() => _familyPlanningMethod = v!),
                            enabled: _isEditing,
                          ),
                          // Referral Alert
                          _buildDropdown(
                            "Refer to Hospital?",
                            ["No", "Yes"],
                            _referredToHospital ? "Yes" : "No",
                            (v) => setState(
                              () => _referredToHospital = (v == "Yes"),
                            ),
                            enabled: _isEditing,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // --- Baby Section ---
                  _buildSectionHeader("Baby's Condition", Icons.child_care),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildTextField(
                            "Baby Weight (kg)",
                            _babyWeightController,
                            isNumber: true,
                            readOnly: !_isEditing,
                          ),
                          _buildDropdown(
                            "Color",
                            ["Pink", "Pale", "Icteric (Yellow)", "Blue"],
                            _babyColor,
                            (v) => setState(() => _babyColor = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Cord Status",
                            ["Normal", "Bleeding", "Infected/Pus", "Off"],
                            _cordStatus,
                            (v) => setState(() => _cordStatus = v!),
                            enabled: _isEditing,
                          ),

                          _buildDropdown(
                            "Breastfeeding",
                            [
                              "Good Sucking",
                              "Poor Sucking",
                              "Not Establishing",
                            ],
                            _breastfeeding,
                            (v) => setState(() => _breastfeeding = v!),
                            enabled: _isEditing,
                          ),
                          _buildDropdown(
                            "Stool Passage",
                            ["Passed", "Not Passed", "Delayed"],
                            _babyStool,
                            (v) => setState(() => _babyStool = v!),
                            enabled: _isEditing,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                  if (_isEditing)
                    ElevatedButton.icon(
                      icon: Icon(Icons.save),
                      label: Text(_isSaving ? "Saving..." : "Save PNC Record"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
        ],
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
}
