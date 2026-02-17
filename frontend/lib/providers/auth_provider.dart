import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient;
  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAutoLoginRunning = false;

  AuthProvider(this._apiClient);

  bool get isAuth => _token != null;
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  // --- 1. LOGIN METODA (Popravljena) ---
  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // [FIX 1 & 2] Koristimo običnu mapu i puštamo Dio da odradi x-www-form-urlencoded
      final response = await _apiClient.dio.post(
        '/auth/token',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data;
      if (data == null || data['access_token'] == null) {
        throw Exception("Invalid response: missing access_token");
      }

      _token = data['access_token'];

      // Save token using ApiClient (FlutterSecureStorage)
      await _apiClient.setToken(_token!);

      // Fetch user profile
      await _fetchMe();
    } catch (e) {
      print("Login error: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Fetch User Profile
  Future<void> _fetchMe() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      _user = User.fromJson(response.data);
      print("Ulogovan: ${_user!.fullName}, Uloga: ${_user!.role}");
    } catch (e) {
      print("Greška pri fetchMe: $e");
      // If we can't fetch profile (e.g. 401), we should probably logout
      await logout();
    }
  }

  // 3. Auto Login
  Future<void> tryAutoLogin() async {
    if (_isAutoLoginRunning) return;
    _isAutoLoginRunning = true;

    try {
      final storedToken = await _apiClient.getToken();

      if (storedToken == null) {
        _isAutoLoginRunning = false;
        notifyListeners(); // Notify even if failed/no token to update UI state
        return;
      }

      _token = storedToken;
      // No need to setToken on _apiClient as it reads from storage automatically

      await _fetchMe();
      notifyListeners();
    } catch (e) {
      await logout();
    } finally {
      _isAutoLoginRunning = false;
    }
  }

  // 4. Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _apiClient.clearToken();
    notifyListeners();
  }

  // 5. Refresh user data (public, for dashboard init)
  Future<void> refreshUser() async {
    if (_token == null) return;
    await _fetchMe();
    notifyListeners();
  }
}
