class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? username;
  final String role;
  final String instituteId;
  final String? avatarUrl;
  final bool needsPasswordReset;
  final bool isProfileComplete;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.username,
    required this.role,
    required this.instituteId,
    this.avatarUrl,
    this.needsPasswordReset = true,
    this.isProfileComplete = false,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:          json['id'] as String,
        name:        json['name'] as String,
        email:       json['email'] as String,
        phone:       json['phone'] as String?,
        username:    json['username'] as String?,
        role:        json['role'] as String,
        instituteId: json['institute_id'] as String,
        avatarUrl:   json['avatar_url'] as String?,
        needsPasswordReset: json['needs_password_reset'] as bool? ?? false,
        isProfileComplete: json['is_profile_complete'] as bool? ?? true,
        createdAt:   json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id':           id,
        'name':         name,
        'email':        email,
        'phone':        phone,
        'username':     username,
        'role':         role,
        'institute_id': instituteId,
        'avatar_url':   avatarUrl,
        'needs_password_reset': needsPasswordReset,
        'is_profile_complete': isProfileComplete,
      };

  // ── Convenience getters ───────────────────────────────────────────────────
  bool get isAdmin   => role == 'admin';
  bool get isTutor   => role == 'tutor';
  bool get isStudent => role == 'student';
  bool get isStaff   => role == 'staff';

  /// Managers are Super Admins OR Staff members with higher privileges
  bool get isManager => 
      isAdmin || 
      (isStaff && (name.toLowerCase().contains('manager') || email.toLowerCase().startsWith('manager')));

  String get roleLabel =>
      role[0].toUpperCase() + role.substring(1); // "Admin" / "Tutor" / "Student"
}
