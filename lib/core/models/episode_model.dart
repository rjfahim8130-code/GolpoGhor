import 'content_block_model.dart';

class EpisodeModel {
  final String id;
  final String novelId;
  final String authorId;
  final int chapterNumber;
  final String title;
  final List<ContentBlockModel> contentBlocks;
  final String? publicCode;
  final bool isPublished;
  final int viewCount;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EpisodeModel({
    required this.id,
    required this.novelId,
    required this.authorId,
    required this.chapterNumber,
    required this.title,
    this.contentBlocks = const [],
    this.publicCode,
    this.isPublished = true,
    this.viewCount = 0,
    this.reactionCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
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

    return EpisodeModel(
      id: json['id'] as String,
      novelId: json['novel_id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      chapterNumber: (json['chapter_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      contentBlocks: blocks,
      publicCode: json['public_code'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'novel_id': novelId,
      'author_id': authorId,
      'chapter_number': chapterNumber,
      'title': title,
      'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
      'public_code': publicCode,
      'is_published': isPublished,
      'view_count': viewCount,
      'reaction_count': reactionCount,
      'comment_count': commentCount,
    };
  }

  EpisodeModel copyWith({
    String? id,
    String? novelId,
    String? authorId,
    int? chapterNumber,
    String? title,
    List<ContentBlockModel>? contentBlocks,
    String? publicCode,
    bool? isPublished,
    int? viewCount,
    int? reactionCount,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EpisodeModel(
      id: id ?? this.id,
      novelId: novelId ?? this.novelId,
      authorId: authorId ?? this.authorId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      contentBlocks: contentBlocks ?? this.contentBlocks,
      publicCode: publicCode ?? this.publicCode,
      isPublished: isPublished ?? this.isPublished,
      viewCount: viewCount ?? this.viewCount,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
