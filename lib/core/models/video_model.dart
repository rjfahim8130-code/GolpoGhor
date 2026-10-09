class VideoModel {
  final String id;
  final String authorId;
  final String title;
  final String description;
  final List<String> tags;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? seriesId;
  final String? seriesTitle;
  final int partNumber;
  final int viewCount;
  final int reactionCount;
  final int commentCount;
  final int saveCount;
  final bool isPublished;
  final bool isDraft;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // join
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;

  const VideoModel({
    required this.id,
    required this.authorId,
    this.title = '',
    this.description = '',
    this.tags = const [],
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.seriesId,
    this.seriesTitle,
    this.partNumber = 1,
    this.viewCount = 0,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.isPublished = true,
    this.isDraft = false,
    required this.createdAt,
    this.updatedAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatar,
  });

  bool get isSeries => seriesId != null && seriesId!.isNotEmpty;

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    List<String> tags = [];
    if (tagsRaw is List) {
      tags = tagsRaw.map((e) => e.toString()).toList();
    }

    return VideoModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: tags,
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      seriesId: json['series_id'] as String?,
      seriesTitle: json['series_title'] as String?,
      partNumber: (json['part_number'] as num?)?.toInt() ?? 1,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      saveCount: (json['save_count'] as num?)?.toInt() ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      isDraft: json['is_draft'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      authorName: json['author_name'] as String?,
      authorUsername: json['author_username'] as String?,
      authorAvatar: json['author_avatar'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap({required String authorId}) {
    return {
      'author_id': authorId,
      'title': title,
      'description': description,
      'tags': tags,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration_seconds': durationSeconds,
      'series_id': seriesId,
      'series_title': seriesTitle,
      'part_number': partNumber,
      'is_published': isPublished,
      'is_draft': isDraft,
    };
  }
}
