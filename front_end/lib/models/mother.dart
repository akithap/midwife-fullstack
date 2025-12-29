class Mother {
  final int id;
  final String nic;
  final String fullName;
  final String address;
  final String contactNumber;
  final int midwifeId;
  final String status;
  final String riskLevel;
  final DateTime? pregnancyStartDate;
  final DateTime? deliveryDate;

  Mother({
    required this.id,
    required this.nic,
    required this.fullName,
    required this.address,
    required this.contactNumber,
    required this.midwifeId,
    this.status = 'Eligible',
    this.riskLevel = 'Low',
    this.pregnancyStartDate,
    this.deliveryDate,
  });

  factory Mother.fromJson(Map<String, dynamic> json) {
    return Mother(
      id: json['id'],
      nic: json['nic'],
      fullName: json['full_name'], // Note: backend uses snake_case
      address: json['address'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      midwifeId: json['midwife_id'],
      status: json['status'] ?? 'Eligible',
      riskLevel: json['risk_level'] ?? 'Low',
      pregnancyStartDate: json['pregnancy_start_date'] != null
          ? DateTime.parse(json['pregnancy_start_date'])
          : null,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nic': nic,
      'full_name': fullName,
      'address': address,
      'contact_number': contactNumber,
      'midwife_id': midwifeId,
    };
  }
}
