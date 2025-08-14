import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

var logger = Logger();

class HttpClient {
  static Future<http.Response> get(
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
      return response;
    } catch (e) {
      logger.e('Network error during GET request to $uri: $e');
      throw Exception('Network error during GET request');
    }
  }

  static Future<http.Response> post(
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
      return response;
    } catch (e) {
      logger.e('Network error during POST request to $uri: $e');
      throw Exception('Network error during POST request');
    }
  }

  static Future<http.Response> patch(
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
      return response;
    } catch (e) {
      logger.e('Network error during PATCH request to $uri: $e');
      throw Exception('Network error during PATCH request');
    }
  }
}
