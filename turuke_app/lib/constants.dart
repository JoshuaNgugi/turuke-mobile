import 'dart:ui';

import 'package:flutter/material.dart';

class Constants {
  static const String API_BASE_URL = 'http://localhost:3000/api';

  static const String LAYERS_API_BASE_URL =
      '$API_BASE_URL/animals/chicken/layers';

  static const String USERS_API_BASE_URL = '$API_BASE_URL/users';

  static const String TERMS_OF_SERVICE_URL = 'https://www.turuke.co.ke/terms.html';

  static const String PRIVACY_POLICY =
      'https://www.turuke.co.ke/privacy-policy.html';

  // Primary color for main branding
  static const Color kPrimaryColor = Color.fromARGB(255, 103, 2, 121);

  // Accent color for secondary elements, buttons, highlights
  static const Color kAccentColor = Color.fromARGB(255, 3, 219, 198);
}

class UserRole {
  static const int ADMIN = 1;
  static const int MANAGER = 2;
  static const int SUPERVISOR = 3;
  static const int ASSISTANT = 4;
  static const int VIEWER = 5;

  static String getString(int role) {
    switch (role) {
      case ADMIN:
        return 'Admin';
      case MANAGER:
        return 'Manager';
      case SUPERVISOR:
        return 'Supervisor';
      case ASSISTANT:
        return 'Assistant';
      case VIEWER:
        return 'Viewer';
      default:
        return 'Viewer';
    }
  }

  static List<int> get allRoleValues => [
    ADMIN,
    MANAGER,
    SUPERVISOR,
    ASSISTANT,
    VIEWER,
  ];
}
