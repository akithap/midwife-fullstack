class Appointment {
  final int id;
  final int midwifeId;
  final int motherId;
  final DateTime dateTime;
  final String visitType;
  final String status;
  final String? notes;

  Appointment({
    required this.id,
    required this.midwifeId,
    required this.motherId,
    required this.dateTime,
    this.visitType = "Home Visit",
    required this.status,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      midwifeId: json['midwife_id'],
      motherId: json['mother_id'],
      dateTime: DateTime.parse(json['date_time']),
      visitType: json['visit_type'] ?? "Home Visit",
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_time': dateTime.toIso8601String(),
      'visit_type': visitType,
      'status': status,
      'notes': notes,
    };
  }
}
