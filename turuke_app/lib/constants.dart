class Constants {
  static const String API_BASE_URL = 'http://192.168.156.34:3000/api';

  static const String LAYERS_API_BASE_URL = '$API_BASE_URL/animals/chicken/layers';

  static const String USERS_API_BASE_URL = '$API_BASE_URL/users';
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
