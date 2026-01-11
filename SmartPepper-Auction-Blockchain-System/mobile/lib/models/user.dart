class User {
  final String id;
  final String email;
  final String name;
  final String role; // 'farmer', 'exporter', 'admin'
  final String? walletAddress;
  final String? phone;
  final bool verified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.walletAddress,
    this.phone,
    this.verified = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      walletAddress: json['walletAddress'] as String?,
      phone: json['phone'] as String?,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'walletAddress': walletAddress,
      'phone': phone,
      'verified': verified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isFarmer => role == 'farmer';
  bool get isExporter => role == 'exporter';
  bool get isAdmin => role == 'admin';
}
