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

  // join
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;
  final int authorFollowerCount;

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
    this.authorFollowerCount = 0,
  });

  factory NovelModel.fromJson(Map<String, dynamic> json) {
    List<String> tags = [];
    final t = json['tags'];
    if (t is List) {
      tags = t.map((e) => e.toString()).toList();
    }

    return NovelModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String? ?? '',
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
      authorFollowerCount:
          (json['author_follower_count'] as num?)?.toInt() ??
              (json['follower_count'] as num?)?.toInt() ??
              0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'cover_url': coverUrl,
      'public_code': publicCode,
      'is_published': isPublished,
      'is_draft': isDraft,
      'episode_count': episodeCount,
      'view_count': viewCount,
      'reaction_count': reactionCount,
      'comment_count': commentCount,
    };
  }

  NovelModel copyWith({
    String? id,
    String? authorId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? coverUrl,
    String? publicCode,
    bool? isPublished,
    bool? isDraft,
    int? episodeCount,
    int? viewCount,
    int? reactionCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    int? authorFollowerCount,
  }) {
    return NovelModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      coverUrl: coverUrl ?? this.coverUrl,
      publicCode: publicCode ?? this.publicCode,
      isPublished: isPublished ?? this.isPublished,
      isDraft: isDraft ?? this.isDraft,
      episodeCount: episodeCount ?? this.episodeCount,
      viewCount: viewCount ?? this.viewCount,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorFollowerCount: authorFollowerCount ?? this.authorFollowerCount,
    );
  }
}
