import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:turuke_app/screens/login.dart';

import '../providers/auth_provider.dart';

class HttpClient {
  static Future<http.Response> get(
    BuildContext context,
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(uri, headers: headers);
    _handleResponse(context, response);
    return response;
  }

  static Future<http.Response> post(
    BuildContext context,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.post(uri, headers: headers, body: body);
    _handleResponse(context, response);
    return response;
  }

  static Future<http.Response> patch(
    BuildContext context,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http.patch(uri, headers: headers, body: body);
    _handleResponse(context, response);
    return response;
  }

  static void _handleResponse(BuildContext context, http.Response response) {
    if (response.statusCode == 401) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout().then((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          LoginScreen.routeName,
          (route) => false,
        );
      });
    }
  }
}
