import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:front_end/l10n/app_localizations.dart';
import '../models/mother.dart';
import '../services/api_service.dart';

// ... (skipping unchanged parts)

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

  // --- NEW: MOH Dropdown State ---
  Map<String, dynamic> _mohOffices = {};
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedMOH;

  Future<void> _fetchMOHOffices() async {
    try {
      final data = await _apiService
          .getAllMOHOffices(); // Assuming added to ApiService or fetch manually
      // Or duplicate here for simplicity if ApiService not updated yet (user didn't ask to update ApiService explicitly but I should)
      // I'll add to ApiService later or make a raw call here.
      // Since ApiService is in use, I should update it.
      setState(() {
        _mohOffices = data;
      });

      // If editing, we might need to match the strings back to selection
      if (widget.existingData != null) {
        _matchLocationFromText();
      }
    } catch (e) {
      print("Error fetching MOH offices: $e");
    }
  }

  void _matchLocationFromText() {
    // If we have text from pre-fill, try to find it in the tree to set dropdowns
    // Simple loop search
    final moh = _mohAreaController.text;
    if (moh.isEmpty) return;

    for (var province in _mohOffices.keys) {
      var districts = _mohOffices[province] as Map<String, dynamic>;
      for (var district in districts.keys) {
        var areas = (districts[district] as List)
            .map((e) => e.toString())
            .toList();
        if (areas.contains(moh)) {
          setState(() {
            _selectedProvince = province;
            _selectedDistrict = district;
            _selectedMOH = moh;
          });
          // Also set province/district if we had saved them separately, but we only have 'moh_division' in old data
          // so REVERSE lookup is needed.
          return;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _preFillData();
    } else {
      _regDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    _fetchMOHOffices();
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
          title: Text(AppLocalizations.of(context)!.addPastPregnancy(order)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: outcome,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.outcome,
                  ),
                  items: ["Live Birth", "Still Birth", "Abortion"].map((s) {
                    String label = s;
                    if (s == "Live Birth")
                      label = AppLocalizations.of(context)!.liveBirth;
                    else if (s == "Still Birth")
                      label = AppLocalizations.of(context)!.stillBirth;
                    else if (s == "Abortion")
                      label = AppLocalizations.of(context)!.abortion;
                    return DropdownMenuItem(value: s, child: Text(label));
                  }).toList(),
                  onChanged: (v) => outcome = v!,
                ),
                DropdownButtonFormField<String>(
                  value: delivery,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.modeOfDelivery,
                  ),
                  items: ["Normal", "LSCS", "Forceps", "Vacuum"].map((s) {
                    String label = s;
                    if (s == "Normal")
                      label = AppLocalizations.of(context)!.normal;
                    else if (s == "LSCS")
                      label = AppLocalizations.of(context)!.lscs;
                    else if (s == "Forceps")
                      label = AppLocalizations.of(context)!.forceps;
                    else if (s == "Vacuum")
                      label = AppLocalizations.of(context)!.vacuum;
                    return DropdownMenuItem(value: s, child: Text(label));
                  }).toList(),
                  onChanged: (v) => delivery = v!,
                ),
                TextField(
                  controller: weightCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.birthWeightKg,
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: ageCtrl,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.ageIfAlive,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
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
              child: Text(AppLocalizations.of(context)!.add),
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
                title: Text(AppLocalizations.of(context)!.yes),
                value: true,
                groupValue: currentValue,
                onChanged: (v) => onChanged(v!),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.teal,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text(AppLocalizations.of(context)!.no),
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
          "moh_division": _mohAreaController
              .text, // This is the MOH Area string e.g., "Dehiwala"
          "moh_province": _selectedProvince,
          "moh_district": _selectedDistrict,

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
                  ? AppLocalizations.of(context)!.recordUpdated
                  : AppLocalizations.of(context)!.pregnancyRegistered,
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

  String _getTranslatedRisk(String key, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'Age < 20 or > 35':
        return loc.riskAge;
      case '5th Pregnancy or more':
        return loc.risk5thPreg;
      case 'Birth Interval < 1yr':
        return loc.riskBirthInterval;
      case 'History of PPH':
        return loc.riskHistoryPPH;
      case 'Diabetes':
        return loc.riskDiabetes;
      case 'Malaria':
        return loc.riskMalaria;
      case 'Heart Disease':
        return loc.riskHeart;
      case 'Renal Disease':
        return loc.riskRenal;
      default:
        return key;
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
                    title: Text(AppLocalizations.of(context)!.step1Title),
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _regDateController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.regDate,
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_regDateController),
                        ),
                        TextFormField(
                          controller: _regNoController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.regNo,
                          ),
                          validator: (v) => v!.isEmpty
                              ? AppLocalizations.of(context)!.required
                              : null,
                        ),
                        TextFormField(
                          controller: _familyRegController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.familyRegNo,
                          ),
                        ),
                        // --- MOH Area Cascading Dropdowns ---
                        if (_mohOffices.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(AppLocalizations.of(context)!.loadingMOH),
                              ],
                            ),
                          )
                        else ...[
                          DropdownButtonFormField<String>(
                            value: _selectedProvince,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.province,
                            ),
                            items: _mohOffices.keys
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedProvince = val;
                                _selectedDistrict = null;
                                _selectedMOH = null;
                                _mohAreaController.text = ""; // Clear
                              });
                            },
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedDistrict,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.healthDistrict,
                            ),
                            items: _selectedProvince == null
                                ? []
                                : (_mohOffices[_selectedProvince]
                                          as Map<String, dynamic>)
                                      .keys
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                            onChanged: _selectedProvince == null
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedDistrict = val;
                                      _selectedMOH = null;
                                      _mohAreaController.text = "";
                                    });
                                  },
                          ),
                          SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedMOH,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.mohArea,
                            ),
                            items: _selectedDistrict == null
                                ? []
                                : (_mohOffices[_selectedProvince][_selectedDistrict]
                                          as List)
                                      .map<DropdownMenuItem<String>>(
                                        (m) => DropdownMenuItem(
                                          value: m.toString(),
                                          child: Text(m.toString()),
                                        ),
                                      )
                                      .toList(),
                            onChanged: _selectedDistrict == null
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedMOH = val;
                                      _mohAreaController.text = val!;
                                    });
                                  },
                            validator: (v) => v == null || v.isEmpty
                                ? AppLocalizations.of(context)!.required
                                : null,
                          ),
                        ],

                        // Hidden TextForm to keep controller sync logic if needed, or just rely on state
                        // We updated _mohAreaController in onChanged, so it's fine.
                        TextFormField(
                          controller: _phiAreaController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.phiArea,
                          ),
                        ),
                        TextFormField(
                          controller: _gnDivisionController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.gnDivision,
                          ),
                        ),
                        TextFormField(
                          controller: _distanceController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.distanceToClinic,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 0,
                  ),

                  // STEP 2: Personal (Mother & Husband)
                  Step(
                    title: Text(AppLocalizations.of(context)!.step2Title),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.motherLabel,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          controller: _motherAgeController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.age,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty
                              ? AppLocalizations.of(context)!.required
                              : null,
                        ),
                        TextFormField(
                          controller: _motherEducationController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.educationLevel,
                          ),
                        ),
                        TextFormField(
                          controller: _motherOccupationController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.occupation,
                          ),
                        ),
                        Divider(),
                        Text(
                          AppLocalizations.of(context)!.husbandLabel,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextFormField(
                          controller: _husbandNameController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.name,
                          ),
                        ),
                        TextFormField(
                          controller: _husbandAgeController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.age,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        TextFormField(
                          controller: _husbandEducationController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.educationLevel,
                          ),
                        ),
                        TextFormField(
                          controller: _husbandOccupationController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.occupation,
                          ),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 1,
                  ),

                  // STEP 3: Vitals & Medical History
                  Step(
                    title: Text(AppLocalizations.of(context)!.step3Title),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _heightController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.heightCm,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateBMI(),
                          validator: (v) => v!.isEmpty
                              ? AppLocalizations.of(context)!.required
                              : null,
                        ),
                        TextFormField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.weightKg,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => _calculateBMI(),
                          validator: (v) => v!.isEmpty
                              ? AppLocalizations.of(context)!.required
                              : null,
                        ),
                        TextFormField(
                          controller: _bmiController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.bmiAuto,
                          ),
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
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.bloodGroup,
                          ),
                        ),
                        SizedBox(height: 16),

                        _buildYesNoField(
                          AppLocalizations.of(context)!.consanguineousMarriage,
                          _consanguinity,
                          (v) => setState(() => _consanguinity = v),
                        ),
                        Divider(),
                        _buildYesNoField(
                          AppLocalizations.of(context)!.rubellaImmunization,
                          _rubella,
                          (v) => setState(() => _rubella = v),
                        ),
                        _buildYesNoField(
                          AppLocalizations.of(context)!.prePregnancyScreening,
                          _preScreening,
                          (v) => setState(() => _preScreening = v),
                        ),
                        _buildYesNoField(
                          AppLocalizations.of(context)!.folicAcidTaken,
                          _folicAcid,
                          (v) => setState(() => _folicAcid = v),
                        ),
                        _buildYesNoField(
                          AppLocalizations.of(context)!.subfertilityHistory,
                          _subfertility,
                          (v) => setState(() => _subfertility = v),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 2,
                  ),

                  // STEP 4: Family Details & Past History
                  Step(
                    title: Text(AppLocalizations.of(context)!.step4Title),
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
                                  labelText:
                                      "${AppLocalizations.of(context)!.gravidity} (G)",
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty
                                    ? AppLocalizations.of(context)!.required
                                    : null,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _parityController,
                                decoration: InputDecoration(
                                  labelText:
                                      "${AppLocalizations.of(context)!.parity} (P)",
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => v!.isEmpty
                                    ? AppLocalizations.of(context)!.required
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),

                        Text(
                          AppLocalizations.of(context)!.familyHistory,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        CheckboxListTile(
                          title: Text(AppLocalizations.of(context)!.diabetes),
                          value: _famDiabetes,
                          onChanged: (v) => setState(() => _famDiabetes = v!),
                        ),
                        CheckboxListTile(
                          title: Text(
                            AppLocalizations.of(context)!.hypertension,
                          ),
                          value: _famHypertension,
                          onChanged: (v) =>
                              setState(() => _famHypertension = v!),
                        ),
                        CheckboxListTile(
                          title: Text(AppLocalizations.of(context)!.twins),
                          value: _famTwins,
                          onChanged: (v) => setState(() => _famTwins = v!),
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.pastPregnancies,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: Colors.teal),
                              onPressed: _addPastPregnancy,
                            ),
                          ],
                        ),
                        _pastPregnancies.isEmpty
                            ? Text(
                                AppLocalizations.of(context)!.noPastPregnancies,
                              )
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
                                            ? "${AppLocalizations.of(context)!.ageIfAlive}: ${p['age_if_alive']}"
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
                    title: Text(AppLocalizations.of(context)!.step5Title),
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _lmpController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.lrmp,
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_lmpController),
                          validator: (v) => v!.isEmpty
                              ? AppLocalizations.of(context)!.required
                              : null,
                        ),
                        TextFormField(
                          controller: _eddController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.edd,
                          ),
                          readOnly: true,
                        ),
                        TextFormField(
                          controller: _usEddController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(
                              context,
                            )!.usCorrectedEdd,
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_usEddController),
                        ),
                        TextFormField(
                          controller: _poaController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.poaReg,
                          ),
                        ),
                      ],
                    ),
                    isActive: _currentStep >= 4,
                  ),

                  // STEP 6: Risk Assessment
                  Step(
                    title: Text(AppLocalizations.of(context)!.step6Title),
                    content: Column(
                      children: _risks.keys.map((key) {
                        return CheckboxListTile(
                          title: Text(_getTranslatedRisk(key, context)),
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
