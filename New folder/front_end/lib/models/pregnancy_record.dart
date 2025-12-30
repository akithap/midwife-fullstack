class PregnancyRecord {
  final int? id;
  final int motherId;
  final String? bloodGroup;
  final double? bmi;
  final double? heightCm;
  final String? allergies;
  final bool consanguinity;
  final bool rubellaImmunization;
  final bool prePregnancyScreening;
  final bool folicAcid;
  final bool subfertilityHistory;
  final String? identifiedRisks;
  final int? gravidity;
  final int? parity;
  final int? livingChildren;
  final String? youngestChildAge;
  final String? lrmp;
  final String? edd;
  final String? usCorrectedEdd;
  final String? poaAtRegistration;

  PregnancyRecord({
    this.id,
    required this.motherId,
    this.bloodGroup,
    this.bmi,
    this.heightCm,
    this.allergies,
    this.consanguinity = false,
    this.rubellaImmunization = false,
    this.prePregnancyScreening = false,
    this.folicAcid = false,
    this.subfertilityHistory = false,
    this.identifiedRisks,
    this.gravidity,
    this.parity,
    this.livingChildren,
    this.youngestChildAge,
    this.lrmp,
    this.edd,
    this.usCorrectedEdd,
    this.poaAtRegistration,
  });

  Map<String, dynamic> toJson() {
    return {
      'blood_group': bloodGroup,
      'bmi': bmi,
      'height_cm': heightCm,
      'allergies': allergies,
      'consanguinity': consanguinity,
      'rubella_immunization': rubellaImmunization,
      'pre_pregnancy_screening': prePregnancyScreening,
      'folic_acid': folicAcid,
      'subfertility_history': subfertilityHistory,
      'identified_risks': identifiedRisks,
      'gravidity': gravidity,
      'parity': parity,
      'living_children': livingChildren,
      'youngest_child_age': youngestChildAge,
      'lrmp': lrmp,
      'edd': edd,
      'us_corrected_edd': usCorrectedEdd,
      'poa_at_registration': poaAtRegistration,
    };
  }
}
