/// In-app notification মডেল
/// type: like | comment | reply | follow | mention
class NotificationModel {
  final String id;
  final String userId; // যাকে notification পাঠানো হয়েছে
  final String actorId; // যে কাজ করেছে
  final String type;
  final String? targetType; // story | novel | episode | video | profile
  final String? targetId;
  final String? message;
  final bool isRead;
  final DateTime createdAt;

  // join — actor-এর তথ্য
  final String? actorName;
  final String? actorUsername;
  final String? actorAvatar;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.targetType,
    this.targetId,
    this.message,
    this.isRead = false,
    required this.createdAt,
    this.actorName,
    this.actorUsername,
    this.actorAvatar,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? username;
    String? avatar;

    final profiles = json['actor'] ?? json['profiles'];
    if (profiles is Map) {
      name = profiles['full_name'] as String?;
      username = profiles['username'] as String?;
      avatar = profiles['avatar_url'] as String?;
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      actorId: json['actor_id'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      message: json['message'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      actorName: name ?? json['actor_name'] as String?,
      actorUsername: username ?? json['actor_username'] as String?,
      actorAvatar: avatar ?? json['actor_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_id': actorId,
      'type': type,
      'target_type': targetType,
      'target_id': targetId,
      'message': message,
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? actorId,
    String? type,
    String? targetType,
    String? targetId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? actorName,
    String? actorUsername,
    String? actorAvatar,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actorName: actorName ?? this.actorName,
      actorUsername: actorUsername ?? this.actorUsername,
      actorAvatar: actorAvatar ?? this.actorAvatar,
    );
  }

  String get actorDisplayName =>
      (actorName != null && actorName!.trim().isNotEmpty)
          ? actorName!.trim()
          : 'ইউজার';

  String get initial {
    final n = actorDisplayName.trim();
    return n.isNotEmpty ? n.substring(0, 1) : '?';
  }
}
