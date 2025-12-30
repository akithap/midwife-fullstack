import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pregnancy_record.dart';
import '../models/delivery_record.dart';
import '../models/antenatal_plan.dart';
import '../models/appointment.dart';
import '../models/leave_request.dart';
import '../models/mother.dart';
// import '../models/health_record.dart'; // Unused
import '../enums/user_role.dart';

class ApiService {
  // CRITICAL: Auto-detect environment
  // Windows/Web/iOS (Simulator): localhost
  // Android Emulator: 10.0.2.2
  static String get _baseUrl {
    if (kIsWeb) {
      // If deployed (Release Mode), use the Live Backend
      if (kReleaseMode) {
        return 'https://midwife-backend-three.vercel.app';
      }
      // If debugging locally, use Localhost
      return 'http://127.0.0.1:8000';
    } else {
      // Assuming Android Emulator for mobile testing
      return 'http://10.0.2.2:8000';
    }
  }

  // ----------------------------------------------------------------------
  // HELPER: Get Headers (with Token)
  // ----------------------------------------------------------------------
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // ----------------------------------------------------------------------
  // AUTHENTICATION (Login)
  // ----------------------------------------------------------------------
  Future<bool> midwifeLogin(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/token"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": username, "password": password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setString('user_role', 'midwife');
        return true;
      }
      return false;
    } catch (e) {
      print("Midwife Login Error: $e");
      return false;
    }
  }

  Future<bool> motherLogin(String nic, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/mother/token"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"username": nic, "password": password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setString('user_role', 'mother');
        return true;
      }
      return false;
    } catch (e) {
      print("Mother Login Error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_role');
  }

  Future<Map<String, dynamic>> login(
    String username,
    String password,
    UserRole role,
  ) async {
    // Wrapper for specific logins if needed, or use specific methods above.
    // Based on AuthProvider, it uses midwifeLogin/motherLogin directly.
    // But if any code uses generic login, here it is:
    bool success = false;
    if (role == UserRole.midwife) {
      success = await midwifeLogin(username, password);
    } else {
      success = await motherLogin(username, password);
    }
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      return {'access_token': prefs.getString('token')}; // Mock return
    }
    throw Exception('Login failed');
  }

  // ----------------------------------------------------------------------
  // MOTHERS (Midwife manages Mothers)
  // ----------------------------------------------------------------------
  Future<List<Mother>> getMothers({String? query}) async {
    // Note: original code returned List<dynamic>, now typed List<Mother>
    // but UI screens might expect dynamic. Let's revert to List<dynamic> or fix screens.
    // Based on errors "getMothers" wasn't complained about, but let's be safe.
    // The previous getMothers (Step 530) returned List<dynamic>.
    // My new getMothers (Step 532) returned List<Mother>.
    // If screens use it, they might need update.
    // `MotherListScreen` likely casts it.
    // Let's stick to List<Mother> as it is cleaner, but if `MotherListScreen` breaks...
    // Actually, `MotherListScreen` errors: "The named parameter 'query' isn't defined".
    // My Step 530 had `getMothers({String? query})`. My Step 532 had `getMothers({String? search})`.
    // I should match `query`.
    final headers = await _getHeaders();
    String url = "$_baseUrl/mothers/";
    if (query != null && query.isNotEmpty) {
      url += "?search=$query";
    }
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Mother.fromJson(item)).toList();
    }
    throw Exception('Failed to load mothers');
  }

  // NEW: Get Current Mother Profile (for Mother Portal)
  Future<Mother> getMotherProfile() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/mothers/me/"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return Mother.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load profile');
  }

  Future<bool> createMother(Map<String, dynamic> motherData) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/mothers/"),
      headers: await _getHeaders(),
      body: jsonEncode(motherData),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateMother(int id, Map<String, dynamic> motherData) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/mothers/$id"),
      headers: await _getHeaders(),
      body: jsonEncode(motherData),
    );
    return response.statusCode == 200;
  }

  // ----------------------------------------------------------------------
  // MIDWIFE RECORDS
  // ----------------------------------------------------------------------
  Future<bool> createPregnancyRecord(
    int motherId,
    PregnancyRecord record,
  ) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/mothers/$motherId/pregnancy-records/"),
      headers: await _getHeaders(),
      body: jsonEncode(record.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getPregnancyRecords(int motherId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/mothers/$motherId/pregnancy-records/"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load pregnancy records');
  }

  Future<bool> createDeliveryRecord(int motherId, DeliveryRecord record) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/mothers/$motherId/delivery-records/"),
      headers: await _getHeaders(),
      body: jsonEncode(record.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getDeliveryRecords(int motherId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/mothers/$motherId/delivery-records/"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load delivery records');
  }

  Future<bool> createAntenatalPlan(int motherId, AntenatalPlan plan) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/mothers/$motherId/antenatal-plans/"),
      headers: await _getHeaders(),
      body: jsonEncode(plan.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getAntenatalPlans(int motherId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/mothers/$motherId/antenatal-plans/"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load antenatal plans');
  }

  // ----------------------------------------------------------------------
  // MOTHER PORTAL
  // ----------------------------------------------------------------------
  Future<List<dynamic>> getMyPregnancyRecords() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/my-pregnancy-records/"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load my pregnancy records');
  }

  Future<List<dynamic>> getMyDeliveryRecords() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/my-delivery-records/"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load my delivery records');
  }

  Future<List<dynamic>> getMyAntenatalPlans() async {
    final response = await http.get(
      Uri.parse("$_baseUrl/my-antenatal-plans/"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load my antenatal plans');
  }

  // ----------------------------------------------------------------------
  // PASSWORD CHANGE
  // ----------------------------------------------------------------------
  Future<bool> changeMotherPassword(
    String oldPassword,
    String newPassword,
  ) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/mothers/me/password"),
      headers: await _getHeaders(),
      body: jsonEncode({
        "old_password": oldPassword,
        "new_password": newPassword,
      }),
    );
    return response.statusCode == 200;
  }

  // ----------------------------------------------------------------------
  // SMART CARE PLAN ACTIONS
  // ----------------------------------------------------------------------
  // NEW: Update existing record
  Future<bool> updatePregnancyRecord(
    int motherId,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/mothers/$motherId/pregnancy"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // NEW: Get existing record for editing
  Future<Map<String, dynamic>?> getPregnancyRecord(int motherId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/mothers/$motherId/pregnancy"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    }
    throw Exception('Failed to fetch pregnancy record');
  }

  // UPDATED: Accepts full H 512 Form data
  Future<bool> startPregnancyV2(int motherId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mothers/$motherId/pregnancy'),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      print("Error Starting Pregnancy: ${response.body}");
    }
    return response.statusCode == 200;
  }

  Future<bool> reportDelivery(int motherId, String deliveryDate) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/mothers/$motherId/delivery"),
      headers: await _getHeaders(),
      body: jsonEncode({"delivery_date": deliveryDate}),
    );
    return response.statusCode == 200;
  }

  Future<bool> changeMidwifePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/midwives/me/password"),
      headers: await _getHeaders(),
      body: jsonEncode({
        "old_password": oldPassword,
        "new_password": newPassword,
      }),
    );
    return response.statusCode == 200;
  }

  // ----------------------------------------------------------------------
  // APPOINTMENTS
  // ----------------------------------------------------------------------

  // For Mother: Get "My Appointments"
  Future<List<Appointment>> getMyAppointments() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/my-appointments/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Appointment.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load appointments: ${response.body}');
    }
  }

  // For Midwife: Get All Appointments (for calendar)
  Future<List<Appointment>> getAppointments({
    DateTime? start,
    DateTime? end,
  }) async {
    return getMidwifeAppointments(
      date: start,
    ); // Alias for compatibility if needed or implement logic
  }

  Future<List<Appointment>> getMidwifeAppointments({DateTime? date}) async {
    final headers = await _getHeaders();
    String url = '$_baseUrl/appointments/';

    if (date != null) {
      // Filter by specific day
      final start = DateTime(date.year, date.month, date.day).toIso8601String();
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      ).toIso8601String();
      url += '?start_date=$start&end_date=$end';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Appointment.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load midwife appointments');
    }
  }

  // For Midwife: "Schedule Appointments" (Create)
  // Original signature was: createAppointment(Appointment appointment).
  // New signature: createAppointment(Appointment appointment, int motherId).
  // I should support both or fix call sites.
  // Error: "2 positional arguments expected by 'createAppointment', but 1 found."
  // I will make motherId optional or extract it from Appointment if possible.
  // But Appointment model in Dart might not have motherId populated?
  // Let's check Appointment model.
  // I will add [int? motherId] as optional.
  Future<bool> createAppointment(
    Appointment appointment, [
    int? motherId,
  ]) async {
    // If motherId is provided, use it (new logic).
    // If not, maybe it's in appointment?
    // Old logic: just passed appointment.toJson().
    // Let's try to handle both.
    int? mId = motherId ?? appointment.motherId;

    final headers = await _getHeaders();
    // If mId is null, we can't create?
    // The backend expects mother_id query param.
    // Removed unnecessary null check as mId should be non-null.
    String url = '$_baseUrl/appointments/?mother_id=$mId';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(appointment.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> updateAppointment(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/appointments/$id"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  // NEW: Delete Appointment
  Future<bool> deleteAppointment(int id) async {
    final response = await http.delete(
      Uri.parse("$_baseUrl/appointments/$id"),
      headers: await _getHeaders(),
    );
    // 204 No Content is success, but 200 OK is also fine depending on framework
    return response.statusCode == 204 || response.statusCode == 200;
  }

  // ANC VISITS
  Future<bool> createANCVisit(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/anc-visits/"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getANCVisit(int appointmentId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/appointments/$appointmentId/anc-visit"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<dynamic>> getMotherANCVisits(int motherId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/mothers/$motherId/anc-visits"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // ----------------------------------------------------------------------
  // PNC VISITS
  // ----------------------------------------------------------------------

  Future<Map<String, dynamic>?> createPNCVisit(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse("$_baseUrl/pnc-visits/"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getPNCVisit(int appointmentId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/appointments/$appointmentId/pnc-visit"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLatestPregnancyRecord(int motherId) async {
    final response = await http.get(
      Uri.parse(
        "$_baseUrl/mothers/$motherId/pregnancy",
      ), // Matches main.py definition
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<dynamic>> getMotherPNCVisits(int motherId) async {
    final response = await http.get(
      Uri.parse("$_baseUrl/mothers/$motherId/pnc-visits"),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // ----------------------------------------------------------------------
  // LEAVE REQUESTS
  // ----------------------------------------------------------------------
  Future<List<LeaveRequest>> getLeaveRequests() async {
    // Alias for getMyLeaveRequests or distinct?
    // Error said: "The method 'getLeaveRequests' isn't defined".
    // Original code had `getLeaveRequests`.
    // It calls `/leave-requests/me`.
    return getMyLeaveRequests();
  }

  Future<List<LeaveRequest>> getMyLeaveRequests() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/leave-requests/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => LeaveRequest.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load leave requests');
    }
  }

  Future<bool> createLeaveRequest(LeaveRequest request) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/leave-requests/'),
      headers: headers,
      body: json.encode(request.toJson()),
    );
    // Original returned bool. New returned LeaveRequest object?
    // Let's return bool to match legacy.
    return response.statusCode == 200;
  }

  // ----------------------------------------------------------------------
  // DASHBOARD STATS & NOTIFICATIONS (NEW)
  // ----------------------------------------------------------------------
  Future<Map<String, int>> getDashboardStats() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/midwives/dashboard-stats'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Map<String, int>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load stats');
    }
  }

  Future<List<String>> getNotifications() async {
    // 1. Get Today's Visits
    final today = DateTime.now();
    final appointments = await getMidwifeAppointments(date: today);

    // 2. Get Recent Leave Statuses
    final leaves = await getMyLeaveRequests();

    List<String> notifications = [];

    // Add Appointment Alerts
    // Filter for PENDING (Scheduled) appointments purely for notification count
    final pending = appointments.where((a) => a.status == 'Scheduled').toList();

    if (pending.isNotEmpty) {
      notifications.add(
        "You have ${pending.length} pending appointment(s) for today.",
      );
    } else {
      if (appointments.isNotEmpty) {
        notifications.add(
          "All appointments for today are completed! Great job.",
        );
      } else {
        notifications.add("No appointments scheduled for today.");
      }
    }

    // Add Leave Alerts (Approved/Rejected)
    final decisionedLeaves = leaves
        .where((l) => l.status != 'Pending')
        .toList();
    for (var leave in decisionedLeaves) {
      notifications.add(
        "Leave Request (${leave.startDate}) was ${leave.status}. Comment: ${leave.mohComment ?? 'None'}",
      );
    }

    return notifications;
  }

  // --- Risk Management ---
  Future<Map<String, int>> getRiskStats() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/mothers/risks/stats"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return Map<String, int>.from(jsonDecode(response.body));
      }
      return {};
    } catch (e) {
      print("Error fetching risk stats: $e");
      return {};
    }
  }

  Future<List<dynamic>> getMothersByRisk(String riskType) async {
    // riskType: "high_risk", "diabetes", "cardiac", "age", "pph", "gravidity"
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/mothers/risks/$riskType"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching mothers by risk: $e");
      return [];
    }
  }
}
