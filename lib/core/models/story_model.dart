import 'content_block_model.dart';

class StoryModel {
  final String id;
  final String authorId;
  final String title;
  final String description;
  final String? category;
  final List<String> tags;
  final String? coverUrl;
  final List<ContentBlockModel> contentBlocks;
  final String? publicCode;
  final bool isPublished;
  final bool isDraft;
  final int viewCount;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;
  final int authorFollowerCount;

  const StoryModel({
    required this.id,
    required this.authorId,
    required this.title,
    this.description = '',
    this.category,
    this.tags = const [],
    this.coverUrl,
    this.contentBlocks = const [],
    this.publicCode,
    this.isPublished = true,
    this.isDraft = false,
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

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final blocks = <ContentBlockModel>[];
    final raw = json['content_blocks'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          blocks.add(ContentBlockModel.fromJson(item));
        } else if (item is Map) {
          blocks.add(ContentBlockModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    List<String> tags = [];
    final t = json['tags'];
    if (t is List) {
      tags = t.map((e) => e.toString()).toList();
    }

    return StoryModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      tags: tags,
      coverUrl: json['cover_url'] as String?,
      contentBlocks: blocks,
      publicCode: json['public_code'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
      isDraft: json['is_draft'] as bool? ?? false,
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
}
