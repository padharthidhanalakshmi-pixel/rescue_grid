import 'enums.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.department,
    this.phone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String email;

  /// Demo-only. Real deployments authenticate through Firebase Auth / campus SSO
  /// and never hold passwords client-side.
  final String password;
  final UserRole role;
  final String? department;
  final String? phone;
  final DateTime createdAt;
}
