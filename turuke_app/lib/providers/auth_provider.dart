import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turuke_app/constants.dart';
import 'package:turuke_app/models/user.dart';
import 'package:turuke_app/utils/http_client.dart';

var logger = Logger();

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _tokenExpiresAt;
  User? _user;

  String? get token => _token;
  String? get tokenExpiresAt => _tokenExpiresAt;
  User? get user => _user;

  bool get isTokenExpired {
    if (_token == null || _tokenExpiresAt == null) {
      return true;
    }
    try {
      final expiryDate = DateTime.parse(_tokenExpiresAt!);
      return expiryDate.isBefore(DateTime.now());
    } catch (e) {
      logger.e('Error parsing token expiry date: $e');
      return true; // Assume expired if parsing fails
    }
  }

  Future<void> register({required User user}) async {
    try {
      final response = await HttpClient.post(
        Uri.parse('${Constants.API_BASE_URL}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: user.toJson(),
      );

      if (response.statusCode == 201) {
        notifyListeners();
      } else {
        String errorMessage = 'Registration failed. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          logger.e('Error parsing registration error response: $e');
        }
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error during registration: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during registration: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await HttpClient.post(
        Uri.parse('${Constants.API_BASE_URL}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);

        _tokenExpiresAt =
            DateTime.now().add(const Duration(days: 365)).toIso8601String();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString(
          'user',
          jsonEncode(_user!.toJson()),
        ); // _user.toJson() returns Map, so encode it
        await prefs.setString('expires_at', _tokenExpiresAt!);

        notifyListeners();
      } else {
        // More robust error parsing for login
        String errorMessage = 'Login failed. Please check your credentials.';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          logger.e('Error parsing login error response: $e');
        }
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error during login: ${e.message}');
    } on TimeoutException catch (e) {
      throw e; // Re-throw the specific TimeoutException
    } catch (e) {
      throw Exception('An unexpected error occurred during login: $e');
    }
  }

  Future<void> verifyEmail(String code) async {
    final response = await HttpClient.post(
      Uri.parse('${Constants.API_BASE_URL}/auth/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );
    if (response.statusCode != 200) {
      throw Exception('Verification failed: ${response.body}');
    }
  }

  Future<void> logout() async {
    // Invalidate local state
    _token = null;
    _user = null;
    _tokenExpiresAt = null;

    // Clear persistent storage
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
      try {
        final Map<String, dynamic> decodedJson = jsonDecode(userJson);
        _user = User.fromJson(decodedJson);
      } catch (e) {
        logger.e('Error decoding user JSON from prefs: $e');
        await prefs.remove('user');
        _user = null;
      }
    }

    // After loading, check if the token is expired.
    // If expired, automatically log out to ensure consistent state.
    if (_token != null && isTokenExpired) {
      logger.i('Token expired, logging out automatically.');
      await logout();
    } else {
      notifyListeners();
    }
  }

  Future<Map<String, String>> getHeaders() async {
    // Check if the token is expired before returning it
    if (_token != null && !isTokenExpired) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };
    } else {
      // If token is null or expired, only return content type.
      // This is crucial: don't send an expired or null token.
      return {'Content-Type': 'application/json'};
    }
  }
}
