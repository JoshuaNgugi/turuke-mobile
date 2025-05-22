class Constants {
  static const String API_BASE_URL = 'http://localhost:3000/api';
}

class UserRole {
  static const int ADMIN = 1;
  static const int MANAGER = 2;
  static const int SUPERVISOR = 3;
  static const int ASSISTANT = 4;
  static const int VIEWER = 5;

  String get getString {
    switch (this) {
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
        return 'Admin';
    }
  }
}
