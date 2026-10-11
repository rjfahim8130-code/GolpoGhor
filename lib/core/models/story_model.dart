// lib/core/models/story_model.dart
// authorUsername বাদ, authorNickname যোগ

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

  // join
  final String? authorName;
  final String? authorNickname;
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
    this.authorNickname,
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
          blocks.add(
            ContentBlockModel.fromJson(Map<String, dynamic>.from(item)),
          );
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
      authorId: json['author_id'] as String? ?? '',
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
      authorNickname: json['author_nickname'] as String?,
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
      'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
      'public_code': publicCode,
      'is_published': isPublished,
      'is_draft': isDraft,
      'view_count': viewCount,
      'reaction_count': reactionCount,
      'comment_count': commentCount,
    };
  }

  StoryModel copyWith({
    String? id,
    String? authorId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    String? coverUrl,
    List<ContentBlockModel>? contentBlocks,
    String? publicCode,
    bool? isPublished,
    bool? isDraft,
    int? viewCount,
    int? reactionCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authorName,
    String? authorNickname,
    String? authorAvatar,
    int? authorFollowerCount,
  }) {
    return StoryModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      coverUrl: coverUrl ?? this.coverUrl,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      publicCode: publicCode ?? this.publicCode,
      isPublished: isPublished ?? this.isPublished,
      isDraft: isDraft ?? this.isDraft,
      viewCount: viewCount ?? this.viewCount,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authorName: authorName ?? this.authorName,
      authorNickname: authorNickname ?? this.authorNickname,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorFollowerCount: authorFollowerCount ?? this.authorFollowerCount,
    );
  }

  String get displayNickname =>
      (authorNickname != null && authorNickname!.trim().isNotEmpty)
          ? authorNickname!.trim()
          : '';

  bool get hasNickname => displayNickname.isNotEmpty;
}
