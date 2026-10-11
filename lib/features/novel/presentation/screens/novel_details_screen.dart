// lib/features/novel/presentation/screens/novel_details_screen.dart
// সংশোধিত: localization, avatar cache

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/episode_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../social/presentation/widgets/report_sheet.dart';

class NovelDetailsScreen extends StatefulWidget {
  final String novelId;

  const NovelDetailsScreen({super.key, required this.novelId});

  @override
  State<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends State<NovelDetailsScreen> {
  final _novelService = NovelService();
  final _episodeService = EpisodeService();
  final _bookmarkService = BookmarkService();
  final _offlineService = OfflineService();
  final _auth = AuthService();

  NovelModel? _novel;
  List<EpisodeModel> _episodes = [];
  bool _loading = true;
  bool _bookmarked = false;
  bool _downloadingAll = false;
  String? _error;

  bool get _isAuthor {
    final uid = _auth.currentUser?.id;
    return uid != null && _novel != null && _novel!.authorId == uid;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final novel = await _novelService.getById(widget.novelId);
      if (novel == null) {
        if (!mounted) return;
        setState(() {
          _error = 'উপন্যাস পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }
      final episodes = await _episodeService.getByNovel(widget.novelId);
      final bm = await _bookmarkService.isNovelBookmarked(widget.novelId);

      if (!mounted) return;
      setState(() {
        _novel = novel;
        _episodes = episodes;
        _bookmarked = bm;
        _loading = false;
      });

      _novelService.recordView(widget.novelId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'লোড করা যায়নি';
        _loading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final on = await _bookmarkService.toggleNovelBookmark(widget.novelId);
      if (!mounted) return;
      setState(() => _bookmarked = on);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(on ? 'বুকমার্ক করা হয়েছে' : 'বুকমার্ক সরানো হয়েছে'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _share() async {
    final n = _novel;
    if (n == null) return;
    final code = n.publicCode ?? '';
    await Share.share(
      '${n.title}\nগল্পঘরে পড়ুন'
      '${code.isNotEmpty ? '\nকোড: $code' : ''}\n#গল্পঘর',
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.copied)),
    );
  }

  Future<void> _downloadAll() async {
    final n = _novel;
    if (n == null) return;
    if (_episodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো পর্ব নেই')),
      );
      return;
    }
    setState(() => _downloadingAll = true);
    try {
      for (final e in _episodes) {
        await _offlineService.saveEpisode(
          episodeId: e.id,
          novelTitle: n.title,
          episodeTitle: e.title,
          chapterNumber: e.chapterNumber,
          contentBlocks: e.contentBlocks,
          authorName: n.authorName,
          publicCode: e.publicCode,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_episodes.length} পর্ব অফলাইনে সেভ')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  String? _episodeCover(EpisodeModel e) {
    for (final b in e.contentBlocks) {
      if (b.isImage && b.imageUrl != null && b.imageUrl!.isNotEmpty) {
        return b.imageUrl;
      }
    }
    return null;
  }
