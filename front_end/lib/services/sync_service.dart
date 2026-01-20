import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class SyncService with ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  final DatabaseHelper _db = DatabaseHelper();
  bool _isSyncing = false;
  bool _isOnline = true;

  factory SyncService() {
    return _instance;
  }

  SyncService._internal() {
    // Monitor connectivity
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _checkConnection();
    });
    _checkConnection();
  }

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;

  // Hardcoded base URL for now, matching ApiService
  static const String baseUrl = 'http://10.0.2.2:8000'; // Mobile to Localhost

  Future<void> _checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    bool hasConnection = !connectivityResult.contains(ConnectivityResult.none);

    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();

      if (_isOnline) {
        processQueue();
      }
    }
  }

  Future<void> queueRequest(
    String method,
    String endpoint,
    dynamic body,
  ) async {
    await _db.insertQueueItem(method, endpoint, body);
    notifyListeners();
    // Try to sync immediately if online
    if (_isOnline) {
      processQueue();
    }
  }

  Future<void> processQueue() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final queue = await _db.getQueue();
      int successCount = 0;

      for (var item in queue) {
        bool success = await _sendItem(item);
        if (success) {
          await _db.deleteQueueItem(item['id']);
          successCount++;
        } else {
          // If one fails, stop processing to preserve order/dependencies?
          // Or skip? For simple apps, stopping is safer.
          // For now, we stop on error (assuming server down or logic error).
          print("Sync failed for item ${item['id']}");
          break;
        }
      }

      if (successCount > 0) {
        print("Synced $successCount items.");
      }
    } catch (e) {
      print("Sync Error: $e");
    } finally {
      _isSyncing = false;
      notifyListeners(); // Update UI icons
    }
  }

  Future<bool> _sendItem(Map<String, dynamic> item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final headers = {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

      final url = Uri.parse('$baseUrl${item['endpoint']}');
      http.Response response;

      final body = item['body'] != null ? jsonDecode(item['body']) : null;

      print("Syncing: ${item['method']} $url");

      switch (item['method']) {
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          return true; // Unknown method, delete to avoid stuck
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        print(
          "Sync Fail Code: ${response.statusCode} | Body: ${response.body}",
        );
        // If 4xx error (client error), maybe delete it?
        // If 400 'Bad Request', retrying won't help.
        // For now, we only retry 5xx or connection errors.
        if (response.statusCode >= 400 && response.statusCode < 500) {
          // Client error: Delete it so it doesn't block queue forever
          return true; // Treat as 'processed' (discarded)
        }
        return false;
      }
    } catch (e) {
      print("Sync Exception: $e");
      return false;
    }
  }
}
