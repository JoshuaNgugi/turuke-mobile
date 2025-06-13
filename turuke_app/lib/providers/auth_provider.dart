import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _tokenExpiresAt;
  User? _user;

  String? get token => _token;
  String? get tokenExpiresAt => _tokenExpiresAt;
  User? get user => _user;

  Future<void> register({required User user}) async {
    final response = await http.post(
      Uri.parse('${Constants.API_BASE_URL}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: user.toJson(),
    );
    if (response.statusCode == 201) {
      notifyListeners();
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<void> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('${Constants.API_BASE_URL}/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            // Return a response to trigger the TimeoutException
            throw TimeoutException(
              'The login request took too long to respond. Please try again later.',
            );
          },
        );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      _user = User.fromJson(data['user']);
      _tokenExpiresAt =
          DateTime.now().add(const Duration(days: 365)).toIso8601String();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', jsonEncode(_user!.toJson()));
      await prefs.setString('expires_at', _tokenExpiresAt!);
      notifyListeners();
    } else {
      throw Exception('Login failed: ${jsonDecode(response.body)['error']}');
    }
  }

  Future<void> verifyEmail(String code) async {
    final response = await http.post(
      Uri.parse('${Constants.API_BASE_URL}/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );
    if (response.statusCode != 200) {
      throw Exception('Verification failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _tokenExpiresAt = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('expires_at');
    notifyListeners();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _tokenExpiresAt = prefs.getString('expires_at');
    final userJson = prefs.getString('user');
    if (userJson != null) {
      // Decode the JSON string into a Map<String, dynamic>
      final Map<String, dynamic> decodedJson = jsonDecode(userJson);
      _user = User.fromJson(decodedJson);
    }
    notifyListeners();
  }

  Future<Map<String, String>> getHeaders() async {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
