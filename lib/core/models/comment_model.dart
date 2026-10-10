// lib/core/models/comment_model.dart
// সংশোধিত: mentionedUserIds যোগ

/// কমেন্ট মডেল — গল্প, পর্ব, উপন্যাস, ভিডিও সবখানে একই মডেল
class CommentModel {
  final String id;
  final String userId;
  final String? storyId;
  final String? episodeId;
  final String? novelId;
  final String? videoId;
  final String? parentId;
  final String? replyToName; // reply-এর ক্ষেত্রে যাকে reply দেওয়া হচ্ছে
  final List<String> mentionedUserIds; // @mention করা users
  final String body;
  final int likeCount;
  final bool isDeleted;
  final DateTime createdAt;

  // join
  final String? authorName;
  final String? authorNickname;
  final String? authorAvatar;

  const CommentModel({
    required this.id,
    required this.userId,
    this.storyId,
    this.episodeId,
    this.novelId,
    this.videoId,
    this.parentId,
    this.replyToName,
    this.mentionedUserIds = const [],
    required this.body,
    this.likeCount = 0,
    this.isDeleted = false,
    required this.createdAt,
    this.authorName,
    this.authorNickname,
    this.authorAvatar,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? nickname;
    String? avatar;

    final profiles = json['profiles'];
    if (profiles is Map) {
      name = profiles['full_name'] as String?;
      nickname = profiles['nickname'] as String?;
      avatar = profiles['avatar_url'] as String?;
    }

    // mentioned_user_ids — list অথবা null
    List<String> mentions = [];
    final mu = json['mentioned_user_ids'];
    if (mu is List) {
      mentions = mu.map((e) => e.toString()).toList();
    }

    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      storyId: json['story_id'] as String?,
      episodeId: json['episode_id'] as String?,
      novelId: json['novel_id'] as String?,
      videoId: json['video_id'] as String?,
      parentId: json['parent_id'] as String?,
      replyToName: json['reply_to_name'] as String?,
      mentionedUserIds: mentions,
      body: json['body'] as String? ?? '',
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      authorName: name ?? json['author_name'] as String?,
      authorNickname: nickname ?? json['author_nickname'] as String?,
      authorAvatar: avatar ?? json['author_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'story_id': storyId,
      'episode_id': episodeId,
      'novel_id': novelId,
      'video_id': videoId,
      'parent_id': parentId,
      'reply_to_name': replyToName,
      'mentioned_user_ids': mentionedUserIds,
      'body': body,
      'like_count': likeCount,
    };
  }

  CommentModel copyWith({
    String? id,
    String? userId,
    String? storyId,
    String? episodeId,
    String? novelId,
    String? videoId,
    String? parentId,
    String? replyToName,
    List<String>? mentionedUserIds,
    String? body,
    int? likeCount,
    bool? isDeleted,
    DateTime? createdAt,
    String? authorName,
    String? authorNickname,
    String? authorAvatar,
  }) {
    return CommentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storyId: storyId ?? this.storyId,
      episodeId: episodeId ?? this.episodeId,
      novelId: novelId ?? this.novelId,
      videoId: videoId ?? this.videoId,
      parentId: parentId ?? this.parentId,
      replyToName: replyToName ?? this.replyToName,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      body: body ?? this.body,
      likeCount: likeCount ?? this.likeCount,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      authorNickname: authorNickname ?? this.authorNickname,
      authorAvatar: authorAvatar ?? this.authorAvatar,
    );
  }

  String get displayAuthor =>
      (authorName != null && authorName!.trim().isNotEmpty)
          ? authorName!.trim()
          : 'ইউজার';

  bool get hasNickname =>
      authorNickname != null && authorNickname!.trim().isNotEmpty;

  String get initial {
    final n = displayAuthor.trim();
    return n.isNotEmpty ? n.substring(0, 1) : '?';
  }

  bool get isReply => parentId != null && parentId!.isNotEmpty;

  bool get hasMentions => mentionedUserIds.isNotEmpty;
}
