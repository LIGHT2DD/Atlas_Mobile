enum UserRole {
  student,
  supervisor,
  coordinator,
  admin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'supervisor':
        return UserRole.supervisor;
      case 'coordinator':
        return UserRole.coordinator;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.supervisor:
        return 'Faculty Supervisor';
      case UserRole.coordinator:
      case UserRole.admin:
        return 'Coordinator';
    }
  }

  bool get isCoordinator => this == UserRole.coordinator || this == UserRole.admin;
  bool get isSupervisor => this == UserRole.supervisor;
  bool get isStudent => this == UserRole.student;
}

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String? department;
  final String? studentId;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.department,
    this.studentId,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      role: UserRole.fromString(json['role'] as String? ?? 'student'),
      avatarUrl: json['avatar_url'] as String?,
      department: json['department'] as String?,
      studentId: json['student_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'role': role.name,
      'avatar_url': avatarUrl,
      'department': department,
      'student_id': studentId,
      'is_active': isActive,
    };
  }
}
