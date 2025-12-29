class AntenatalPlan {
  final int? id;
  final int motherId;

  final String? nextClinicDate;

  // Classes (1st)
  final String? class1stDate;
  final bool class1stHusband;
  final bool class1stWife;
  final String? class1stOther;

  // Classes (2nd)
  final String? class2ndDate;
  final bool class2ndHusband;
  final bool class2ndWife;
  final String? class2ndOther;

  // Classes (3rd)
  final String? class3rdDate;
  final bool class3rdHusband;
  final bool class3rdWife;
  final String? class3rdOther;

  // Materials
  final String? bookAntenatalIssued;
  final String? bookAntenatalReturned;
  final String? bookBreastfeedingIssued;
  final String? bookBreastfeedingReturned;
  final String? bookEccdIssued;
  final String? bookEccdReturned;
  final String? leafletFpIssued;
  final String? leafletFpReturned;

  // Emergency
  final String? emergencyContactName;
  final String? emergencyContactAddress;
  final String? emergencyContactPhone;
  final String? mohOfficePhone;
  final String? phmPhone;
  final String? gramaNiladariDiv;

  AntenatalPlan({
    this.id,
    required this.motherId,
    this.nextClinicDate,
    this.class1stDate,
    this.class1stHusband = false,
    this.class1stWife = false,
    this.class1stOther,
    this.class2ndDate,
    this.class2ndHusband = false,
    this.class2ndWife = false,
    this.class2ndOther,
    this.class3rdDate,
    this.class3rdHusband = false,
    this.class3rdWife = false,
    this.class3rdOther,
    this.bookAntenatalIssued,
    this.bookAntenatalReturned,
    this.bookBreastfeedingIssued,
    this.bookBreastfeedingReturned,
    this.bookEccdIssued,
    this.bookEccdReturned,
    this.leafletFpIssued,
    this.leafletFpReturned,
    this.emergencyContactName,
    this.emergencyContactAddress,
    this.emergencyContactPhone,
    this.mohOfficePhone,
    this.phmPhone,
    this.gramaNiladariDiv,
  });

  Map<String, dynamic> toJson() {
    return {
      'next_clinic_date': nextClinicDate,
      'class_1st_date': class1stDate,
      'class_1st_husband': class1stHusband,
      'class_1st_wife': class1stWife,
      'class_1st_other': class1stOther,
      'class_2nd_date': class2ndDate,
      'class_2nd_husband': class2ndHusband,
      'class_2nd_wife': class2ndWife,
      'class_2nd_other': class2ndOther,
      'class_3rd_date': class3rdDate,
      'class_3rd_husband': class3rdHusband,
      'class_3rd_wife': class3rdWife,
      'class_3rd_other': class3rdOther,
      'book_antenatal_issued': bookAntenatalIssued,
      'book_antenatal_returned': bookAntenatalReturned,
      'book_breastfeeding_issued': bookBreastfeedingIssued,
      'book_breastfeeding_returned': bookBreastfeedingReturned,
      'book_eccd_issued': bookEccdIssued,
      'book_eccd_returned': bookEccdReturned,
      'leaflet_fp_issued': leafletFpIssued,
      'leaflet_fp_returned': leafletFpReturned,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_address': emergencyContactAddress,
      'emergency_contact_phone': emergencyContactPhone,
      'moh_office_phone': mohOfficePhone,
      'phm_phone': phmPhone,
      'grama_niladari_div': gramaNiladariDiv,
    };
  }
}
