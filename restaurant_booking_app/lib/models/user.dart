class User {
  final int? id;
  final String username;
  final String password;
  final String role; // 'admin' or 'user'
  final String? email;
  final String? phone;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'email': email,
      'phone': phone,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? email,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
}
