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
      followerCount: json['follower_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
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

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty)
          ? fullName!.trim()
          : (username ?? 'ইউজার');

  String get handle =>
      username != null ? '@$username' : '';
}
