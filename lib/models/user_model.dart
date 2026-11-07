enum UserRole {
  participant,
  manufacturer;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.participant;
    switch (role.toLowerCase()) {
      case 'manufacturer':
        return UserRole.manufacturer;
      case 'participant':
      default:
        return UserRole.participant;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.participant:
        return 'Participant';
      case UserRole.manufacturer:
        return 'Manufacturer';
    }
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      name: data['name'] as String? ?? 'Anonymous',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String?,
      role: UserRole.fromString(data['role'] as String?),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt'] as DateTime
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? profileImageUrl,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
