import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:turuke_app/core/exceptions/api_exception.dart';

var _logger = Logger(printer: PrettyPrinter());

class ErrorMapper {
  static String mapErrorToUserMessage(dynamic error) {
    const Map<String, String> apiErrorMap = {
      'duplicate key value':
          'It looks like this data has already been saved. Please check your existing records.',
    };

    if (error is ApiException) {
      _logger.e('Mapping API Exception: ${error.statusCode} - ${error.body}');

      for (var entry in apiErrorMap.entries) {
        if (error.body.contains(entry.key)) {
          return entry.value;
        }
      }

      return 'The request failed (${error.statusCode}). Please check your input.';
    } else if (error is SocketException || error is TimeoutException) {
      return 'Could not connect to the internet. Please check your connection.';
    } else if (error is PlatformException) {
      return 'A device-related error occurred. Please restart the app.';
    } else if (error is Exception) {
      _logger.e('Mapping General Exception: $error');
      return 'An unexpected error occurred: ${error.runtimeType}.';
    }

    _logger.e('Mapping Unknown Error: $error');
    return 'An unknown error occurred.';
  }
}
