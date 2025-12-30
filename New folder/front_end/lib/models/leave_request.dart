class LeaveRequest {
  final int id;
  final int midwifeId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final String? mohComment;

  LeaveRequest({
    required this.id,
    required this.midwifeId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    this.mohComment,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'],
      midwifeId: json['midwife_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      reason: json['reason'],
      status: json['status'],
      mohComment: json['moh_comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String().split(
        'T',
      )[0], // Send as YYYY-MM-DD
      'end_date': endDate.toIso8601String().split('T')[0],
      'reason': reason,
      'status': status,
    };
  }
}
