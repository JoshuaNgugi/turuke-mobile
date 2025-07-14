import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:turuke_app/providers/auth_provider.dart';
import 'package:turuke_app/screens/login_screen.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class HttpClient {

  static Future<http.Response> get(
    BuildContext context,
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'The request took too long to respond. Please try again later.',
              );
            },
          );

      _handleResponse(context, response);
      return response;
    } catch (e) {
      throw Exception('Network error during GET request to $uri: $e');
    }
  }

  static Future<http.Response> post(
    BuildContext context,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'The request took too long to respond. Please try again later.',
              );
            },
          );
      _handleResponse(context, response);
      return response;
    } catch (e) {
      throw Exception('Network error during POST request to $uri: $e');
    }
  }

  static Future<http.Response> patch(
    BuildContext context,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    try {
      final response = await http
          .patch(uri, headers: headers, body: body)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException(
                'The request took too long to respond. Please try again later.',
              );
            },
          );
      _handleResponse(context, response);
      return response;
    } catch (e) {
      throw Exception('Network error during PATCH request to $uri: $e');
    }
  }

  static void _handleResponse(BuildContext context, http.Response response) {
    if (!context.mounted) {
      return;
    }

    if (response.statusCode == 401) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      authProvider
          .logout()
          .then((_) {
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginScreen.routeName,
                (route) => false,
              );
            }
          })
          .catchError((error) {
            logger.e('Error during logout on 401: $error');
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                LoginScreen.routeName,
                (route) => false,
              );
            }
          });
    }
  }
}
