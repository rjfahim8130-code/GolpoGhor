class NovelModel {
  final String id;
  final String authorId;
  final String title;
  final String description;
  final String? category;
  final List<String> tags;
  final String? coverUrl;
  final String? publicCode;
  final bool isPublished;
  final bool isDraft;
  final int episodeCount;
  final int viewCount;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;

  const NovelModel({
    required this.id,
    required this.authorId,
    required this.title,
    this.description = '',
    this.category,
    this.tags = const [],
    this.coverUrl,
    this.publicCode,
    this.isPublished = true,
    this.isDraft = false,
    this.episodeCount = 0,
    this.viewCount = 0,
    this.reactionCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatar,
  });

  factory NovelModel.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    final t = json['tags'];
    if (t is List) {
      tags = t.map((e) => e.toString()).toList();
    }

    return NovelModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      tags: tags,
      coverUrl: json['cover_url'] as String?,
      publicCode: json['public_code'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
      isDraft: json['is_draft'] as bool? ?? false,
      episodeCount: (json['episode_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      authorName: json['author_name'] as String?,
      authorUsername: json['author_username'] as String?,
      authorAvatar: json['author_avatar'] as String?,
    );
  }
}
