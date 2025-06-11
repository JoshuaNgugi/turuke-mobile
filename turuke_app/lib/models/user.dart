class User {
  final int? id; // nullable if not yet persisted (used in offline mode)
  final String firstName;
  final String lastName;
  final String email;
  final int role;
  final int status;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.status,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      role: json['role'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
      'status': status,
    };
  }
}
