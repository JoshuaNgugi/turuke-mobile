import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/utils/http_client.dart';

final secureStorage = const FlutterSecureStorage();
var logger = Logger();

class AuthProvider with ChangeNotifier {
  String? _accessToken;
  DateTime? _accessTokenExpiry;
  User? _user;

  String? get token => _accessToken;
  User? get user => _user;

  bool get isTokenExpired {
    if (_accessToken == null || _accessTokenExpiry == null) return true;
    return DateTime.now().isAfter(_accessTokenExpiry!);
  }

  // ===== REGISTER =====
  Future<void> register({required User user}) async {
    final response = await HttpClient.post(
      Uri.parse('${Constants.API_BASE_URL}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: user.toJson(),
    );

    if (response.statusCode != 201) {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // ===== LOGIN =====
  Future<void> login(String email, String password) async {
    final response = await HttpClient.post(
      Uri.parse('${Constants.API_BASE_URL}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      _accessToken = data['accessToken'];
      _accessTokenExpiry = _decodeExpiry(_accessToken!);
      _user = User.fromJson(data['user']);

      // Store refresh token securely
      await secureStorage.write(
        key: 'refresh_token',
        value: data['refreshToken'],
      );

      // Store access token in prefs for quick startup use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString(
        'access_token_expiry',
        _accessTokenExpiry!.toIso8601String(),
      );
      await prefs.setString('user', jsonEncode(_user!.toJson()));

      notifyListeners();
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  // ===== REFRESH TOKEN =====
  Future<bool> refreshAccessToken() async {
    final refreshToken = await secureStorage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    final response = await HttpClient.post(
      Uri.parse('${Constants.API_BASE_URL}/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['accessToken'];
      _accessTokenExpiry = _decodeExpiry(_accessToken!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString(
        'access_token_expiry',
        _accessTokenExpiry!.toIso8601String(),
      );

      notifyListeners();
      return true;
    } else {
      await logout();
      return false;
    }
  }

  // ===== AUTO LOGIN =====
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('access_token');
    final storedExpiry = prefs.getString('access_token_expiry');
    final userJson = prefs.getString('user');

    if (storedToken != null && storedExpiry != null && userJson != null) {
      _accessToken = storedToken;
      _accessTokenExpiry = DateTime.tryParse(storedExpiry);
      _user = User.fromJson(jsonDecode(userJson));

      if (isTokenExpired) {
        await refreshAccessToken();
      } else {
        notifyListeners();
      }
    }
  }

  // ===== LOGOUT =====
  Future<void> logout() async {
    _accessToken = null;
    _accessTokenExpiry = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await secureStorage.deleteAll();

    notifyListeners();
  }

  // ===== GET HEADERS =====
  // Every API call will refresh the token if expired before making the request
  Future<Map<String, String>> getHeaders() async {
    if (isTokenExpired) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) return {'Content-Type': 'application/json'};
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
  }

  // ===== DECODE JWT EXPIRY =====
  DateTime _decodeExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    return DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
  }
}
