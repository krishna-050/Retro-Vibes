class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String provider; // 'email', 'google', 'anonymous'
  final bool isGuest;
  final String? profileImageType; // 'default' or 'custom'
  final String? profileAvatarId; // e.g., 'avatar_03'
  final String role; // 'user' or 'admin'
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final DateTime? updatedAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl = '',
    this.provider = 'email',
    this.isGuest = false,
    this.profileImageType,
    this.profileAvatarId,
    this.role = 'user',
    this.createdAt,
    this.lastLoginAt,
    this.updatedAt,
    this.isActive = true,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'isGuest': isGuest,
      'profileImageType': profileImageType,
      'profileAvatarId': profileAvatarId,
      'role': role,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'isActive': isActive,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      provider: map['provider'] ?? 'email',
      isGuest: map['isGuest'] ?? false,
      profileImageType: map['profileImageType'],
      profileAvatarId: map['profileAvatarId'],
      role: map['role'] ?? 'user',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      lastLoginAt: map['lastLoginAt'] != null ? DateTime.tryParse(map['lastLoginAt'].toString()) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
      isActive: map['isActive'] ?? true,
    );
  }
}
