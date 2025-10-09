class User {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final String? firstName;
  final String? lastName;
  final String email;
  final int role;
  final int? status;
  final int? farmId;
  final String? farmName;
  final String? password;

  User({
    this.id,
    this.firstName,
    this.lastName,
    required this.email,
    required this.role,
    this.status,
    this.farmId,
    this.farmName,
    this.password,
  });

  String get fullName {
    final parts =
        [firstName, lastName]
            .where((name) => name != null && name.isNotEmpty)
            .map((name) => name!)
            .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    // Fallback
    return email;
  }

  String get farmNameOrDefault {
    return (farmName?.trim().isNotEmpty ?? false) ? farmName!.trim() : 'Turuke';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
      farmId: json['farm_id'],
      farmName: json['farm_name'],
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'farm_id': farmId,
      'farm_name': farmName,
      'role': role,
      'status': status,
    };

    // Only include password if adding a new user OR if editing and password field is not empty
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }

    return data;
  }
}
