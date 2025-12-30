import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mother.dart';
import '../services/api_service.dart';

class PregnancyRegistrationScreen extends StatefulWidget {
  final Mother mother;
  final Map<String, dynamic>? existingData; // NEW: For Edit Mode

  const PregnancyRegistrationScreen({
    Key? key,
    required this.mother,
    this.existingData,
  }) : super(key: key);

  @override
  _PregnancyRegistrationScreenState createState() =>
      _PregnancyRegistrationScreenState();
}

class _PregnancyRegistrationScreenState
    extends State<PregnancyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  int _currentStep = 0;

  // --- CONTROLLERS ---

  // Section 1: Registration
  final _regDateController = TextEditingController();
  final _regNoController = TextEditingController();
  final _familyRegController = TextEditingController();
  final _mohAreaController = TextEditingController();
  final _phiAreaController = TextEditingController();
  final _gnDivisionController = TextEditingController();

  // Section 2: Personal (Mother)
  final _motherAgeController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _motherEducationController = TextEditingController();
  final _distanceController = TextEditingController();

  // Section 3: Husband
  final _husbandNameController = TextEditingController();
  final _husbandAgeController = TextEditingController();
  final _husbandOccupationController = TextEditingController();
  final _husbandEducationController = TextEditingController();

  // Section 4: History & Vitals
  final _marriedAgeController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bmiController = TextEditingController();
  final _gravidityController = TextEditingController();
  final _parityController = TextEditingController();

  String _bloodGroup = 'A+';
  bool _consanguinity = false;

  // NEW: History Checkboxes
  bool _rubella = false;
  bool _folicAcid = false;
  bool _preScreening = false;
  bool _subfertility = false;

  // NEW: Family History
  bool _famDiabetes = false;
  bool _famHypertension = false;
  bool _famTwins = false;
  final _otherHistoryController = TextEditingController();

  // NEW: Past Pregnancies Table List
  List<Map<String, dynamic>> _pastPregnancies = [];

  // Section 5: Current Pregnancy Dates
  final _lmpController = TextEditingController();
  final _eddController = TextEditingController();
  final _usEddController = TextEditingController();
  final _poaController = TextEditingController();

  // Section 6: Risks
  Map<String, bool> _risks = {
    'Age < 20 or > 35': false,
    '5th Pregnancy or more': false,
    'Birth Interval < 1yr': false,
    'History of PPH': false, // NEW
    'Diabetes': false,
    'Malaria': false,
    'Heart Disease': false,
    'Renal Disease': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _preFillData();
    } else {
      _regDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
  }

  void _preFillData() {
    final data = widget.existingData!['record_data'];
    final history = widget.existingData!['past_history'] as List;

    // 1. Registration
    if (data['registration_date'] != null)
      _regDateController.text = data['registration_date'];
    _regNoController.text = data['registration_no'] ?? '';
    _familyRegController.text = data['family_register_no'] ?? '';
    _mohAreaController.text = data['moh_division'] ?? '';
    _phiAreaController.text = data['phi_area'] ?? '';
    _gnDivisionController.text = data['village_division'] ?? '';
    _distanceController.text = data['distance_to_clinic']?.toString() ?? '';

    // 2. Personal
    _motherAgeController.text = data['mother_age']?.toString() ?? '';
    _motherOccupationController.text = data['mother_occupation'] ?? '';
    _motherEducationController.text = data['mother_education'] ?? '';

    _husbandNameController.text = data['husband_name'] ?? '';
    _husbandAgeController.text = data['husband_age']?.toString() ?? '';
    _husbandOccupationController.text = data['husband_occupation'] ?? '';
    _husbandEducationController.text = data['husband_education'] ?? '';

    // 3. Vitals
    _marriedAgeController.text = data['married_age']?.toString() ?? '';
    _consanguinity = data['consanguinity'] ?? false;
    _weightController.text = data['weight_kg']?.toString() ?? '';
    _heightController.text = data['height_cm']?.toString() ?? '';
    _bmiController.text = data['bmi']?.toString() ?? '';
    _bloodGroup = data['blood_group'] ?? 'A+';

    // G/P
    _gravidityController.text = data['gravidity']?.toString() ?? '';
    _parityController.text = data['parity']?.toString() ?? '';

    // History Boolean Fields
    _rubella = data['rubella_immunization'] ?? false;
    _preScreening = data['pre_pregnancy_screening'] ?? false;
    _folicAcid = data['folic_acid'] ?? false;
    _subfertility = data['history_of_subfertility'] ?? false;

    // Family History
    _famDiabetes = data['family_diabetes'] ?? false;
    _famHypertension = data['family_hypertension'] ?? false;
    _famTwins = data['family_twins'] ?? false;
    _otherHistoryController.text = data['other_family_history'] ?? '';

    // Dates
    if (data['lrmp'] != null) _lmpController.text = data['lrmp'];
    if (data['edd'] != null) _eddController.text = data['edd'];
    if (data['us_corrected_edd'] != null)
      _usEddController.text = data['us_corrected_edd'];
    _poaController.text = data['poa_at_registration'] ?? '';

    // Risks
    _risks['Age < 20 or > 35'] = data['risk_age_lt_20_gt_35'] ?? false;
    _risks['5th Pregnancy or more'] = data['risk_5th_pregnancy'] ?? false;
    _risks['Birth Interval < 1yr'] =
        data['risk_birth_interval_lt_1yr'] ?? false;
    _risks['History of PPH'] = data['risk_history_pph'] ?? false; // NEW
    _risks['Diabetes'] = data['risk_diabetes'] ?? false;
    _risks['Malaria'] = data['risk_malaria'] ?? false;
    _risks['Heart Disease'] = data['risk_cardiac'] ?? false;
    _risks['Renal Disease'] = data['risk_renal'] ?? false;

    // Past History Table
    setState(() {
      _pastPregnancies = history.map((e) => e as Map<String, dynamic>).toList();
    });
  }

  // --- HELPERS ---

  void _autoDetectRisks() {
    setState(() {
      // 1. Age Risk
      final age = int.tryParse(_motherAgeController.text);
      if (age != null) {
        if (age < 20 || age > 35)
          _risks['Age < 20 or > 35'] = true;
        else
          _risks['Age < 20 or > 35'] = false;
      }

      // 2. Gravidity Risk (5th or more)
      final g = int.tryParse(_gravidityController.text);
      if (g != null && g >= 5) {
        _risks['5th Pregnancy or more'] = true;
      } else {
        _risks['5th Pregnancy or more'] = false;
      }

      // 3. BMI Risk (Optional: Visual Logic)
      // If we had a BMI risk checkbox, we'd set it here.
    });
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        if (controller == _lmpController) {
          final edd = picked.add(Duration(days: 280));
          _eddController.text = DateFormat('yyyy-MM-dd').format(edd);
        }
      });
    }
  }

  void _calculateBMI() {
    final h = double.tryParse(_heightController.text) ?? 0;
    final w = double.tryParse(_weightController.text) ?? 0;
    if (h > 0 && w > 0) {
      final hM = h / 100;
      final bmi = w / (hM * hM);
      _bmiController.text = bmi.toStringAsFixed(1);
    }
  }

  void _addPastPregnancy() {
    showDialog(
      context: context,
      builder: (ctx) {
        String order = "G${_pastPregnancies.length + 1}";
        String outcome = "Live Birth";
        String delivery = "Normal";
        final weightCtrl = TextEditingController();
        final ageCtrl = TextEditingController();

        return AlertDialog(
          title: Text("Add Past Pregnancy ($order)"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: outcome,
                  decoration: InputDecoration(labelText: "Outcome"),
                  items: ["Live Birth", "Still Birth", "Abortion"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => outcome = v!,
                ),
                DropdownButtonFormField<String>(
                  value: delivery,
                  decoration: InputDecoration(labelText: "Mode of Delivery"),
                  items: ["Normal", "LSCS", "Forceps", "Vacuum"]
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => delivery = v!,
                ),
                TextField(
                  controller: weightCtrl,
                  decoration: InputDecoration(labelText: "Birth Weight (kg)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: ageCtrl,
                  decoration: InputDecoration(labelText: "Age if Alive"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pastPregnancies.add({
                    "pregnancy_order": order,
                    "outcome": outcome,
                    "delivery_mode": delivery,
                    "birth_weight": double.tryParse(weightCtrl.text),
                    "age_if_alive": ageCtrl.text,
                    "complications": "", // Simplified for now
                    "place_of_delivery": "",
                    "sex": "",
                  });
                });
                Navigator.pop(ctx);
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYesNoField(
    String label,
    bool currentValue,
    Function(bool) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text("Yes"),
                value: true,
                groupValue: currentValue,
                onChanged: (v) => onChanged(v!),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.teal,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text("No"),
                value: false,
                groupValue: currentValue,
                onChanged: (v) => onChanged(v!),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- SUBMIT ---

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Auto-detect one last time before submit to be safe
    _autoDetectRisks();

    String finalRisk = "Low";
    if (_risks.containsValue(true)) finalRisk = "High";

    try {
      final formData = {
        "risk_level": finalRisk,
        "past_history": _pastPregnancies, // THE NEW LIST
        "record_data": {
          "registration_date": _regDateController.text.isNotEmpty
              ? _regDateController.text
              : null,
          "registration_no": _regNoController.text,
          "family_register_no": _familyRegController.text,
          "moh_division": _mohAreaController.text,
          "phi_area": _phiAreaController.text,
          "village_division": _gnDivisionController.text,

          "mother_age": int.tryParse(_motherAgeController.text),
          "mother_occupation": _motherOccupationController.text,
          "mother_education": _motherEducationController.text,
          "distance_to_clinic": double.tryParse(_distanceController.text),

          "husband_name": _husbandNameController.text,
          "husband_age": int.tryParse(_husbandAgeController.text),
          "husband_occupation": _husbandOccupationController.text,
          "husband_education": _husbandEducationController.text,

          "married_age": int.tryParse(_marriedAgeController.text),
          "consanguinity": _consanguinity,

          "weight_kg": double.tryParse(_weightController.text),
          "height_cm": double.tryParse(_heightController.text),
          "bmi": double.tryParse(_bmiController.text),
          "blood_group": _bloodGroup,

          // G/P RESTORED:
          "gravidity": int.tryParse(_gravidityController.text),
          "parity": int.tryParse(_parityController.text),

          // History Checkboxes
          "rubella_immunization": _rubella,
          "pre_pregnancy_screening": _preScreening,
          "folic_acid": _folicAcid,
          "history_of_subfertility": _subfertility,

          // Family History
          "family_diabetes": _famDiabetes,
          "family_hypertension": _famHypertension,
          "family_twins": _famTwins,
          "other_family_history": _otherHistoryController.text,

          "lrmp": _lmpController.text.isNotEmpty ? _lmpController.text : null,
          "edd": _eddController.text.isNotEmpty ? _eddController.text : null,
          "us_corrected_edd": _usEddController.text.isNotEmpty
              ? _usEddController.text
              : null,
          "poa_at_registration": _poaController.text,

          // Risks
          "risk_age_lt_20_gt_35": _risks['Age < 20 or > 35'],
          "risk_5th_pregnancy": _risks['5th Pregnancy or more'],
          "risk_birth_interval_lt_1yr": _risks['Birth Interval < 1yr'],
          "risk_history_pph": _risks['History of PPH'], // NEW
          "risk_diabetes": _risks['Diabetes'],
          "risk_malaria": _risks['Malaria'],
          "risk_cardiac": _risks['Heart Disease'],
          "risk_renal": _risks['Renal Disease'],
        },
      };

      bool success;
      if (widget.existingData != null) {
        // UPDATE MODE
        success = await _apiService.updatePregnancyRecord(
          widget.mother.id,
          formData,
        );
      } else {
        // CREATE MODE
        success = await _apiService.startPregnancyV2(
          widget.mother.id,
          formData,
        );
      }

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingData != null
                  ? "Record Updated Successfully!"
                  : "Pregnancy Registered Successfully!",
            ),
          ),
        );
      } else {
        throw Exception("API Failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingData != null
              ? "Edit H 512 Record"
              : "Registration (H 512)",
        ),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  // Trigger smart logic when moving to Risks (last step)
                  if (_currentStep == 4) _autoDetectRisks();

                  if (_currentStep < 5)
                    setState(() => _currentStep += 1);
                  else
                    _submitForm();
                },
                onStepCancel: () {
                  if (_currentStep > 0)
                    setState(() => _currentStep -= 1);
                  else
                    Navigator.pop(context);
                },
                steps: [
                  // STEP 1: Admin
                  Step(
                    title: Text("1. Registration & Admin"),
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _regDateController,
                          decoration: InputDecoration(labelText: "Reg Date"),
                          readOnly: true,
                          onTap: () => _selectDate(_regDateController),
                        ),
                        TextFormField(
                          controller: _regNoController,
                          decoration: InputDecoration(labelText: "Reg No"),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        TextFormField(
                          controller: _familyRegController,
                          decoration: InputDecoration(
                            labelText: "Family Reg No",
                          ),
                        ),
                        TextFormField(
                          controller: _mohAreaController,
                          decoration: InputDecoration(labelText: "MOH Area"),
                        ),
                        TextFormField(
                          controller: _phiAreaController,
                          decoration: InputDecoration(labelText: "PHI Area"),
                        ),
                        TextFormField(
                          controller: _gnDivisionController,
                          decoration: InputDecoration(
                            labelText: "Gramaniladhari Division",
                          ),
                        ),
                        TextFormField(
                          controller: _distanceController,
                          decoration: InputDecoration(
                            labelText: "Distance to Clinic (km)",
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 0,
                  ),

                  // STEP 2: Personal (Mother & Husband)
                  Step(
                    title: Text("2. Personal Info (Mother & Husband)"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mother:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          controller: _motherAgeController,
                          decoration: InputDecoration(labelText: "Age"),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        TextFormField(
                          controller: _motherEducationController,
                          decoration: InputDecoration(
                            labelText: "Education Level",
                          ),
                        ),
                        TextFormField(
                          controller: _motherOccupationController,
                          decoration: InputDecoration(labelText: "Occupation"),
                        ),
                        Divider(),
                        Text(
                          "Husband:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          controller: _husbandNameController,
                          decoration: InputDecoration(labelText: "Name"),
                        ),
                        TextFormField(
                          controller: _husbandAgeController,
                          decoration: InputDecoration(labelText: "Age"),
                          keyboardType: TextInputType.number,
                        ),
                        TextFormField(
                          controller: _husbandEducationController,
                          decoration: InputDecoration(
                            labelText: "Education Level",
                          ),
                        ),
                        TextFormField(
                          controller: _husbandOccupationController,
                          decoration: InputDecoration(labelText: "Occupation"),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 1,
                  ),

                  // STEP 3: Vitals & Medical History
                  Step(
                    title: Text("3. Vitals & Medical History"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _heightController,
                          decoration: InputDecoration(labelText: "Height (cm)"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateBMI(),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        TextFormField(
                          controller: _weightController,
                          decoration: InputDecoration(labelText: "Weight (kg)"),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateBMI(),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        TextFormField(
                          controller: _bmiController,
                          decoration: InputDecoration(labelText: "BMI (Auto)"),
                          readOnly: true,
                        ),
                        DropdownButtonFormField<String>(
                          value: _bloodGroup,
                          items:
                              ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                  .map(
                                    (bg) => DropdownMenuItem(
                                      value: bg,
                                      child: Text(bg),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _bloodGroup = v!),
                          decoration: InputDecoration(labelText: "Blood Group"),
                        ),
                        SizedBox(height: 16),

                        _buildYesNoField(
                          "Consanguineous Marriage?",
                          _consanguinity,
                          (v) => setState(() => _consanguinity = v),
                        ),
                        Divider(),
                        _buildYesNoField(
                          "Rubella Immunization?",
                          _rubella,
                          (v) => setState(() => _rubella = v),
                        ),
                        _buildYesNoField(
                          "Pre-Pregnancy Screening?",
                          _preScreening,
                          (v) => setState(() => _preScreening = v),
                        ),
                        _buildYesNoField(
                          "Folic Acid Taken?",
                          _folicAcid,
                          (v) => setState(() => _folicAcid = v),
                        ),
                        _buildYesNoField(
                          "History of Subfertility?",
                          _subfertility,
                          (v) => setState(() => _subfertility = v),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 2,
                  ),

                  // STEP 4: Family Details & Past History
                  Step(
                    title: Text("4. Family & Obstetric History"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // G/P RESTORED:
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _gravidityController,
                                decoration: InputDecoration(
                                  labelText: "Gravidity (G)",
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? "Required" : null,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _parityController,
                                decoration: InputDecoration(
                                  labelText: "Parity (P)",
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? "Required" : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        Text(
                          "Family History:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        CheckboxListTile(
                          title: Text("Diabetes"),
                          value: _famDiabetes,
                          onChanged: (v) => setState(() => _famDiabetes = v!),
                        ),
                        CheckboxListTile(
                          title: Text("Hypertension"),
                          value: _famHypertension,
                          onChanged: (v) =>
                              setState(() => _famHypertension = v!),
                        ),
                        CheckboxListTile(
                          title: Text("Twins"),
                          value: _famTwins,
                          onChanged: (v) => setState(() => _famTwins = v!),
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Past Pregnancies:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.teal),
                              onPressed: _addPastPregnancy,
                            ),
                          ],
                        ),
                        _pastPregnancies.isEmpty
                            ? Text("No past pregnancies added.")
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: _pastPregnancies.length,
                                itemBuilder: (ctx, i) {
                                  final p = _pastPregnancies[i];
                                  return Card(
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text(p['pregnancy_order']),
                                      ),
                                      title: Text(
                                        "${p['outcome']} (${p['delivery_mode']})",
                                      ),
                                      subtitle: Text(
                                        p['age_if_alive'] != null
                                            ? "Age: ${p['age_if_alive']}"
                                            : "",
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => setState(
                                          () => _pastPregnancies.removeAt(i),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                    isActive: _currentStep >= 3,
                  ),

                  // STEP 5: Dating
                  Step(
                    title: Text("5. Dating (LMP & EDD)"),
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _lmpController,
                          decoration: InputDecoration(
                            labelText: "LMP",
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_lmpController),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        TextFormField(
                          controller: _eddController,
                          decoration: InputDecoration(labelText: "EDD"),
                          readOnly: true,
                        ),
                        TextFormField(
                          controller: _usEddController,
                          decoration: InputDecoration(
                            labelText: "US Corrected EDD",
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_usEddController),
                        ),
                        TextFormField(
                          controller: _poaController,
                          decoration: InputDecoration(
                            labelText: "POA at Registration",
                          ),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 4,
                  ),

                  // STEP 6: Risk Assessment
                  Step(
                    title: Text("6. Risk Assessment"),
                    content: Column(
                      children: _risks.keys.map((key) {
                        return CheckboxListTile(
                          title: Text(key),
                          value: _risks[key],
                          onChanged: (val) {
                            setState(() {
                              _risks[key] = val!;
                            });
                          },
                          dense: true,
                          activeColor: Colors.red,
                        );
                      }).toList(),
                    ),
                    isActive: _currentStep >= 5,
                  ),
                ],
              ),
            ),
    );
  }
}
