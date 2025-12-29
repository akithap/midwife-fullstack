class DeliveryRecord {
  final int? id;
  final int motherId;

  // Delivery
  final String? deliveryDate;
  final String? deliveryMode;
  final bool episiotomy;
  final bool tempNormal;
  final bool vaginalExamDone;
  final String? maternalComplications;
  final bool woundInfection;
  final bool familyPlanningDiscussed;
  final bool dangerSignalsExplained;
  final bool breastFeedingEstablished;

  // Baby
  final double? birthWeight;
  final int? poaAtBirth;
  final int? apgarScore;
  final String? abnormalities;

  // Discharge
  final bool vitaminAGiven;
  final bool rubellaGiven;
  final bool antiDGiven;
  final bool diagnosisCardGiven;
  final bool chdrCompleted;
  final bool prescriptionGiven;
  final bool referredToPhm;
  final String? specialNotes;
  final String? dischargeDate;

  DeliveryRecord({
    this.id,
    required this.motherId,
    this.deliveryDate,
    this.deliveryMode,
    this.episiotomy = false,
    this.tempNormal = false,
    this.vaginalExamDone = false,
    this.maternalComplications,
    this.woundInfection = false,
    this.familyPlanningDiscussed = false,
    this.dangerSignalsExplained = false,
    this.breastFeedingEstablished = false,
    this.birthWeight,
    this.poaAtBirth,
    this.apgarScore,
    this.abnormalities,
    this.vitaminAGiven = false,
    this.rubellaGiven = false,
    this.antiDGiven = false,
    this.diagnosisCardGiven = false,
    this.chdrCompleted = false,
    this.prescriptionGiven = false,
    this.referredToPhm = false,
    this.specialNotes,
    this.dischargeDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'delivery_date': deliveryDate,
      'delivery_mode': deliveryMode,
      'episiotomy': episiotomy,
      'temp_normal': tempNormal,
      'vaginal_exam_done': vaginalExamDone,
      'maternal_complications': maternalComplications,
      'wound_infection': woundInfection,
      'family_planning_discussed': familyPlanningDiscussed,
      'danger_signals_explained': dangerSignalsExplained,
      'breast_feeding_established': breastFeedingEstablished,
      'birth_weight': birthWeight,
      'poa_at_birth': poaAtBirth,
      'apgar_score': apgarScore,
      'abnormalities': abnormalities,
      'vitamin_a_given': vitaminAGiven,
      'rubella_given': rubellaGiven,
      'anti_d_given': antiDGiven,
      'diagnosis_card_given': diagnosisCardGiven,
      'chdr_completed': chdrCompleted,
      'prescription_given': prescriptionGiven,
      'referred_to_phm': referredToPhm,
      'special_notes': specialNotes,
      'discharge_date': dischargeDate,
    };
  }
}
