class CommentModel {
  final String id;
  final String userId;
  final String? storyId;
  final String? episodeId;
  final String? novelId;
  final String? parentId;
  final String body;
  final int likeCount;
  final DateTime createdAt;

  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;

  const CommentModel({
    required this.id,
    required this.userId,
    this.storyId,
    this.episodeId,
    this.novelId,
    this.parentId,
    required this.body,
    this.likeCount = 0,
    required this.createdAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatar,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? username;
    String? avatar;
    final profiles = json['profiles'];
    if (profiles is Map) {
      name = profiles['full_name'] as String?;
      username = profiles['username'] as String?;
      avatar = profiles['avatar_url'] as String?;
    }

    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      storyId: json['story_id'] as String?,
      episodeId: json['episode_id'] as String?,
      novelId: json['novel_id'] as String?,
      parentId: json['parent_id'] as String?,
      body: json['body'] as String? ?? '',
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      authorName: name ?? json['author_name'] as String?,
      authorUsername: username ?? json['author_username'] as String?,
      authorAvatar: avatar ?? json['author_avatar'] as String?,
    );
  }
}
