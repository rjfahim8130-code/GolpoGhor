import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/novel_model.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/video_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/app_dot_menu.dart';
import '../../../../core/widgets/empty_view.dart';

/// প্রোফাইলের ৩টি ট্যাব (গল্প · উপন্যাস · ভিডিও) —
/// একই UI, শুধু ডেটা আলাদা
class ProfilePostsTab {
  ProfilePostsTab._();

  // ---------- Stories ----------

  static Widget stories({
    required List<StoryModel> stories,
    required void Function(StoryModel) onOpenStory,
    void Function(StoryModel)? onEditStory,
    void Function(StoryModel)? onDeleteStory,
  }) {
    if (stories.isEmpty) {
      return const EmptyView(
        icon: Icons.article_outlined,
        title: 'এখনো কোনো গল্প নেই',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: stories.length,
      itemBuilder: (context, i) {
        final s = stories[i];
        return _postTile(
          context: context,
          cover: s.coverUrl,
          title: s.title.isEmpty ? '(শিরোনামহীন)' : s.title,
          subtitle:
              '${TimeAgo.compact(s.viewCount)} দেখা · ${TimeAgo.compact(s.reactionCount)} রিঅ্যাকশন · ${TimeAgo.bn(s.createdAt)}',
          onTap: () => onOpenStory(s),
          menuItems: [
            if (onEditStory != null)
              AppDotMenuItem(
                icon: Icons.edit_outlined,
                label: 'সম্পাদনা',
                onTap: () => onEditStory(s),
              ),
            if (onDeleteStory != null)
              AppDotMenuItem(
                icon: Icons.delete_outline,
                label: 'মুছুন',
                onTap: () => onDeleteStory(s),
                danger: true,
              ),
          ],
        );
      },
    );
  }

  // ---------- Novels ----------

  static Widget novels({
    required List<NovelModel> novels,
    required void Function(NovelModel) onOpenNovel,
    void Function(NovelModel)? onEditNovel,
    void Function(NovelModel)? onDeleteNovel,
  }) {
    if (novels.isEmpty) {
      return const EmptyView(
        icon: Icons.menu_book_outlined,
        title: 'এখনো কোনো উপন্যাস নেই',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: novels.length,
      itemBuilder: (context, i) {
        final n = novels[i];
        return _postTile(
          context: context,
          cover: n.coverUrl,
          title: n.title.isEmpty ? '(শিরোনামহীন)' : n.title,
          subtitle:
              '${n.episodeCount} পর্ব · ${TimeAgo.compact(n.viewCount)} দেখা',
          onTap: () => onOpenNovel(n),
          menuItems: [
            if (onEditNovel != null)
              AppDotMenuItem(
                icon: Icons.edit_outlined,
                label: 'সম্পাদনা',
                onTap: () => onEditNovel(n),
              ),
            if (onDeleteNovel != null)
              AppDotMenuItem(
                icon: Icons.delete_outline,
                label: 'মুছুন',
                onTap: () => onDeleteNovel(n),
                danger: true,
              ),
          ],
        );
      },
    );
  }

  // ---------- Videos ----------

  static Widget videos({
    required List<VideoModel> videos,
    required void Function(VideoModel) onOpenVideo,
    void Function(VideoModel)? onEditVideo,
    void Function(VideoModel)? onDeleteVideo,
  }) {
    if (videos.isEmpty) {
      return const EmptyView(
        icon: Icons.videocam_outlined,
        title: 'এখনো কোনো ভিডিও নেই',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: videos.length,
      itemBuilder: (context, i) {
        final v = videos[i];
        return _postTile(
          context: context,
          cover: v.thumbnailUrl,
          isVideo: true,
          title: v.displayTitle,
          subtitle:
              '${TimeAgo.compact(v.viewCount)} দেখা · ${TimeAgo.compact(v.reactionCount)} রিঅ্যাকশন · ${TimeAgo.bn(v.createdAt)}',
          onTap: () => onOpenVideo(v),
          menuItems: [
            if (onEditVideo != null)
              AppDotMenuItem(
                icon: Icons.edit_outlined,
                label: 'সম্পাদনা',
                onTap: () => onEditVideo(v),
              ),
            if (onDeleteVideo != null)
              AppDotMenuItem(
                icon: Icons.delete_outline,
                label: 'মুছুন',
                onTap: () => onDeleteVideo(v),
                danger: true,
              ),
          ],
        );
      },
    );
  }

  // ---------- Common tile ----------

  static Widget _postTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? cover,
    bool isVideo = false,
    List<AppDotMenuItem> menuItems = const [],
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final hasCover = cover != null && cover.trim().isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: hasCover
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: cover,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              placeholder: (_, __) => Container(
                                color: AppColors.primary.withValues(alpha: 0.08),
                              ),
                              errorWidget: (_, __, ___) =>
                                  _placeholder(isVideo),
                            ),
                            if (isVideo)
                              Container(
                                color: Colors.black.withValues(alpha: 0.25),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : _placeholder(isVideo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: secondary),
                    ),
                  ],
                ),
              ),
              if (menuItems.isNotEmpty)
                AppDotMenu(items: menuItems, iconSize: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _placeholder(bool isVideo) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.article_outlined,
        color: AppColors.primary,
        size: 26,
      ),
    );
  }
}
