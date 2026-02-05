import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pregnancy_record.dart';
import '../models/delivery_record.dart';
import '../models/antenatal_plan.dart';
import '../models/appointment.dart';

import '../models/mother.dart';
import '../models/message.dart';
import '../models/alert.dart'; // NEW
import '../models/midwife.dart'; // NEW
import '../enums/user_role.dart';
import 'sync_service.dart';
import 'database_helper.dart';

// --- NEW: MOH Office Response ---
// No specific model needed if we return Map<String, dynamic> directly for the JSON structure

class ApiService {
  final SyncService _syncService = SyncService();
  final DatabaseHelper _db = DatabaseHelper();

  // CRITICAL: Auto-detect environment
  // Windows/Web/iOS (Simulator): localhost
  // Android Emulator: 10.0.2.2
  static String get _baseUrl {
    if (kIsWeb) {
      if (kReleaseMode) {
        return 'https://midwife-backend-1207eer98-akithas-projects-04f8a73b.vercel.app';
      }
      return 'http://127.0.0.1:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  // ----------------------------------------------------------------------
  // AUTHENTICATION (Login) - RESTORED
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
    bool success = false;
    if (role == UserRole.midwife) {
      success = await midwifeLogin(username, password);
    } else {
      success = await motherLogin(username, password);
    }
    if (success) {
      final prefs = await SharedPreferences.getInstance();
      return {'access_token': prefs.getString('token')};
    }
    throw Exception('Login failed');
  }

  // --- MOTHERS ---

  Future<List<Mother>> getMothers({String? query, int limit = 1000}) async {
    final headers = await _getHeaders();
    String endpoint = "/mothers/?limit=$limit";
    if (query != null && query.isNotEmpty) {
      endpoint += "&search=$query";
    }
    String url = "$_baseUrl$endpoint";

    if (_syncService.isOnline) {
      // ONLINE: Fetch & Cache
      try {
        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode == 200) {
          // Cache the response
          await _db.cacheResponse(endpoint, response.body);

          List<dynamic> body = jsonDecode(response.body);
          return body.map((item) => Mother.fromJson(item)).toList();
        }
      } catch (e) {
        print("Network failed, trying cache...");
      }
    }

    // OFFLINE or FAIL: Read Cache
    final cached = await _db.getCachedResponse(endpoint);
    if (cached != null) {
      List<dynamic> body = jsonDecode(cached);
      return body.map((item) => Mother.fromJson(item)).toList();
    }

    throw Exception('Failed to load mothers (Offline & No Cache)');
  }

  Future<Mother> getMother(int id) async {
    if (_syncService.isOnline) {
      final response = await http.get(
        Uri.parse("$_baseUrl/mothers/$id"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return Mother.fromJson(jsonDecode(response.body));
      }
    }
    // Fallback: Check cached list? expensive but okay
    // We don't have individual cache per ID usually, just the list 'getMothers'
    // For now, throw if online fails
    throw Exception('Failed to load mother $id');
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
    String endpoint = '/appointments/';

    if (date != null) {
      final start = DateTime(date.year, date.month, date.day).toIso8601String();
      final end = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
      ).toIso8601String();
      endpoint += '?start_date=$start&end_date=$end';
    }

    String url = '$_baseUrl$endpoint';

    if (_syncService.isOnline) {
      try {
        final response = await http.get(Uri.parse(url), headers: headers);
        if (response.statusCode == 200) {
          await _db.cacheResponse(endpoint, response.body);
          List<dynamic> body = json.decode(response.body);
          return body
              .map((dynamic item) => Appointment.fromJson(item))
              .toList();
        }
      } catch (e) {
        print("Network failed, checking cache...");
      }
    }

    // OFFLINE
    final cached = await _db.getCachedResponse(endpoint);
    if (cached != null) {
      List<dynamic> body = jsonDecode(cached);
      return body.map((dynamic item) => Appointment.fromJson(item)).toList();
    }

    throw Exception('Failed to load midwife appointments (Offline)');
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
    int? mId = motherId ?? appointment.motherId;
    String endpoint = '/appointments/?mother_id=$mId';
    String url = '$_baseUrl$endpoint';

    if (_syncService.isOnline) {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(appointment.toJson()),
      );
      if (response.statusCode == 200) return true;
    }

    // OFFLINE: Queue it
    if (!_syncService.isOnline) {
      await _syncService.queueRequest('POST', endpoint, appointment.toJson());
      return true; // "Saved successfully" (to outbox)
    }

    return false;
  }

  Future<bool> updateAppointment(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$_baseUrl/appointments/$id"),
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      // Parse error message
      String errorMsg = "Failed to update appointment";
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('detail')) {
          errorMsg = body['detail'];
        }
      } catch (_) {}
      throw Exception(errorMsg);
    }
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
    String endpoint = '/anc-visits/';
    String url = '$_baseUrl$endpoint';

    if (_syncService.isOnline) {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return true;
    }

    // OFFLINE
    if (!_syncService.isOnline) {
      await _syncService.queueRequest('POST', endpoint, data);
      return true; // Saved to Outbox
    }

    return false;
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

  // PNC VISITS
  Future<Map<String, dynamic>?> createPNCVisit(
    Map<String, dynamic> data,
  ) async {
    String endpoint = '/pnc-visits/';
    String url = '$_baseUrl$endpoint';

    if (_syncService.isOnline) {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    }

    // OFFLINE
    if (!_syncService.isOnline) {
      await _syncService.queueRequest('POST', endpoint, data);
      return data; // Return local data pretending success
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
  Future<List<String>> getNotifications() async {
    // 1. Get Today's Visits
    final today = DateTime.now();
    final appointments = await getMidwifeAppointments(date: today);

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

  // ----------------------------------------------------------------------
  // CHAT (POLLING)
  // ----------------------------------------------------------------------

  Future<bool> sendMessage(
    int receiverId,
    String content,
    UserRole role,
  ) async {
    // Determine Endpoint based on Sender Role
    String endpoint = role == UserRole.midwife
        ? "/midwives/messages/"
        : "/mothers/messages/";

    final response = await http.post(
      Uri.parse("$_baseUrl$endpoint"),
      headers: await _getHeaders(),
      body: jsonEncode({"receiver_id": receiverId, "content": content}),
    );
    return response.statusCode == 200;
  }

  Future<List<Message>> getChatMessages(int otherUserId, UserRole role) async {
    // Determine Endpoint based on My Role
    // If I am Midwife, I call /midwives/messages/{mother_id}
    // If I am Mother, I call /mothers/messages/{midwife_id}

    String endpoint = role == UserRole.midwife
        ? "/midwives/messages/$otherUserId"
        : "/mothers/messages/$otherUserId";

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl$endpoint"),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Message.fromJson(item)).toList();
      }
    } catch (e) {
      print("Chat Polling Error: $e");
      return [];
    }
    return [];
  }

  // --- MIDWIFE ANALYTICS (Actionable) ---
  Future<Map<String, int>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/midwives/dashboard/stats"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return Map<String, int>.from(jsonDecode(response.body));
      }
      return {'todays_visits': 0};
    } catch (e) {
      print("Error fetching dashboard stats: $e");
      return {'todays_visits': 0};
    }
  }

  Future<List<dynamic>> getMidwifeDefaulters() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/midwives/analytics/defaulters"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching defaulters: $e");
      return [];
    }
  }

  Future<List<dynamic>> getMidwifeForecast() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/midwives/analytics/forecast"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error fetching forecast: $e");
      return [];
    }
  }

  Future<int> getUnreadMessageCount() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/midwives/messages/unread/count"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['count'];
      }
    } catch (e) {
      print("Error fetching unread count: $e");
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getUnreadSenders() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/midwives/messages/unread/senders"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching unread senders: $e");
    }
    return [];
  }

  Future<void> markChatRead(int motherId) async {
    try {
      await http.put(
        Uri.parse("$_baseUrl/midwives/messages/$motherId/read"),
        headers: await _getHeaders(),
      );
    } catch (e) {
      print("Error marking chat read: $e");
    }
  }

  // --- MOTHER CHAT METHODS ---
  Future<int> getUnreadMessageCountMother() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/mothers/messages/unread/count"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['count'];
      }
    } catch (e) {
      print("Error fetching mother unread count: $e");
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> getUnreadSendersMother() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/mothers/messages/unread/senders"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      print("Error fetching mother unread senders: $e");
    }
    return [];
  }

  Future<void> markChatReadMother(int midwifeId) async {
    try {
      await http.put(
        Uri.parse("$_baseUrl/mothers/messages/$midwifeId/read"),
        headers: await _getHeaders(),
      );
    } catch (e) {
      print("Error marking mother chat read: $e");
    }
  }

  // --- MIDWIFE PROFILE ---
  Future<Midwife?> getMidwifeProfile() async {
    try {
      final response = await http.get(
        Uri.parse("$_baseUrl/midwives/me"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return Midwife.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print("Error fetching midwife profile: $e");
      return null;
    }
  }

  // --- RISK ALERT APIs ---

  Future<List<Alert>> getMidwifeAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/midwives/alerts'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Alert.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching alerts: $e');
      return [];
    }
  }

  Future<String> getHealthTip() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/mothers/health-tip'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['content'] ?? "Stay healthy!";
      } else {
        return "Enjoy your day!";
      }
    } catch (e) {
      return "Remember to drink plenty of water.";
    }
  }

  // --- NEW: Get All MOH Offices (Hierarchical JSON) ---
  Future<Map<String, dynamic>> getAllMOHOffices() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/moh-offices'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      print("Failed to load MOH Offices: ${response.statusCode}");
      return {};
    } catch (e) {
      print("Error fetching MOH Offices: $e");
      return {};
    }
  }
}
