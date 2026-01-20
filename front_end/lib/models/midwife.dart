class Midwife {
  final int id;
  final String username;
  final String fullName;
  final String nic;
  final String phoneNumber;
  final String email;
  final String slmcRegNo;
  final String serviceGrade;
  final String assignedMohArea;

  Midwife({
    required this.id,
    required this.username,
    required this.fullName,
    required this.nic,
    required this.phoneNumber,
    required this.email,
    required this.slmcRegNo,
    required this.serviceGrade,
    required this.assignedMohArea,
  });

  factory Midwife.fromJson(Map<String, dynamic> json) {
    return Midwife(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      nic: json['nic'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      email: json['email'] ?? '',
      slmcRegNo: json['slmc_reg_no'] ?? '',
      serviceGrade: json['service_grade'] ?? '',
      assignedMohArea: json['assigned_moh_area'] ?? '',
    );
  }
}
