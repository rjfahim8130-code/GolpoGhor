class UserModel {
  final String id;
  final String? email;
  final String? fullName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? inviteCode;
  final bool isAdmin;
  final bool profileSetupDone;
  final int followerCount;
  final int followingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.email,
    this.fullName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.inviteCode,
    this.isAdmin = false,
    this.profileSetupDone = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      inviteCode: json['invite_code'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      profileSetupDone: json['profile_setup_done'] as bool? ?? false,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'invite_code': inviteCode,
      'is_admin': isAdmin,
      'profile_setup_done': profileSetupDone,
      'follower_count': followerCount,
      'following_count': followingCount,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? inviteCode,
    bool? isAdmin,
    bool? profileSetupDone,
    int? followerCount,
    int? followingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      inviteCode: inviteCode ?? this.inviteCode,
      isAdmin: isAdmin ?? this.isAdmin,
      profileSetupDone: profileSetupDone ?? this.profileSetupDone,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// নাম দেখানোর জন্য (username কখনোই নয়)
  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return 'ইউজার';
  }

  /// শুধু প্রোফাইল স্ক্রিনে ব্যবহৃত হবে
  String get handle =>
      (username != null && username!.isNotEmpty) ? '@$username' : '';

  /// Avatar না থাকলে প্রথম অক্ষর দেখানোর জন্য
  String get initial {
    final n = displayName.trim();
    if (n.isEmpty) return '?';
    return n.substring(0, 1);
  }
}
