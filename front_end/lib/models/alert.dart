class Alert {
  final int id;
  final int motherId;
  final String severity; // "High", "Medium", "Info"
  final String alertType; // "Hypertension", "Diabetes", etc.
  final String message;
  final bool isResolved;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.motherId,
    required this.severity,
    required this.alertType,
    required this.message,
    required this.isResolved,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      motherId: json['mother_id'],
      severity: json['severity'],
      alertType: json['alert_type'],
      message: json['message'],
      isResolved: json['is_resolved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
