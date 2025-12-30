import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

import '../enums/user_role.dart';

// Enum to hold the different types of users
// enum UserRole { none, midwife, mother } -> Moved to enums/user_role.dart

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserRole _role = UserRole.none;
  bool _isLoading = true; // Start in loading state

  UserRole get role => _role;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // When the app starts, check if a token is already saved
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if token exists
    final token = prefs.getString('token');
    if (token == null) {
      _role = UserRole.none;
    } else {
      // Check what role was saved
      final savedRole = prefs.getString('user_role');
      if (savedRole == 'midwife') {
        _role = UserRole.midwife;
      } else if (savedRole == 'mother') {
        _role = UserRole.mother;
      } else {
        _role = UserRole.none;
      }
    }

    _isLoading = false;
    notifyListeners(); // Tell the UI to update
  }

  Future<bool> midwifeLogin(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.midwifeLogin(username, password);

    if (success) {
      _role = UserRole.midwife;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> motherLogin(String nic, String password) async {
    _isLoading = true;
    notifyListeners();

    // This calls the *real* function in api_service
    final success = await _apiService.motherLogin(nic, password);

    if (success) {
      _role = UserRole.mother;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _apiService.logout();
    _role = UserRole.none;
    notifyListeners();
  }
}
