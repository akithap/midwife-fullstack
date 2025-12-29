class HealthRecord {
  final int id;
  final int motherId;
  final String date;
  final String weight;
  final String bloodPressure;
  final String notes;

  HealthRecord({
    required this.id,
    required this.motherId,
    required this.date,
    required this.weight,
    required this.bloodPressure,
    required this.notes,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'],
      motherId: json['mother_id'],
      date: json['date'],
      weight: json['weight'],
      bloodPressure: json['blood_pressure'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mother_id': motherId,
      'date': date,
      'weight': weight,
      'blood_pressure': bloodPressure,
      'notes': notes,
    };
  }
}
