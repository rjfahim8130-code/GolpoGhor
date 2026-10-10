import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/models/video_model.dart';
import '../../../../core/providers/video_feature_provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/cached_avatar.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../routing/route_names.dart';
import '../../../social/presentation/widgets/comment_section.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../../../social/presentation/widgets/reaction_summary.dart';
import '../../../social/presentation/widgets/report_sheet.dart';

class VideoFeedScreen extends ConsumerStatefulWidget {
  final String? focusVideoId;

  const VideoFeedScreen({super.key, this.focusVideoId});

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> {
  final _service = VideoService();
  final _pageController = PageController();
  List<VideoModel> _items = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getFeed(limit: 40);
      if (!mounted) return;
      // focus থাকলে সেই ভিডিওকে সবার আগে
      if (widget.focusVideoId != null) {
        final i = list.indexWhere((v) => v.id == widget.focusVideoId);
        if (i > 0) {
          final focused = list.removeAt(i);
          list.insert(0, focused);
        }
      }
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoOn = ref.watch(videoFeatureProvider);

    // admin toggle বন্ধ → সরাসরি বাইরে
    if (!videoOn) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'ভিডিও ফিচার এখন বন্ধ আছে।',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingView(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    if (_items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () => context.push(RouteNames.createVideo),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: const EmptyView(
          icon: Icons.videocam_outlined,
          title: 'এখনো কোনো ভিডিও নেই',
          subtitle: 'নিচের বাটনে ট্যাপ করে প্রথম ভিডিও আপলোড করুন',
        ),
      );
    }

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await context.push(RouteNames.createVideo);
          _load();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _items.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return _VideoFeedItem(
                key: ValueKey(_items[index].id),
                video: _items[index],
                isActive: index == _currentIndex,
                topPad: topPad,
                onDeleted: () {
                  setState(() => _items.removeAt(index));
                },
                onJumpToSeriesPart: (next) {
                  final i = _items.indexWhere((e) => e.id == next.id);
                  if (i >= 0) {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  } else {
                    setState(() {
                      _items.insert(_currentIndex + 1, next);
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(
                          _currentIndex + 1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }
                },
              );
            },
          ),
          // উপরে invisible Safe Area — banner এলে এখানে বসবে
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topPad,
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

// ---------- Individual video item ----------

class _VideoFeedItem extends ConsumerStatefulWidget {
  final VideoModel video;
  final bool isActive;
  final double topPad;
  final VoidCallback? onDeleted;
  final void Function(VideoModel next)? onJumpToSeriesPart;

  const _VideoFeedItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.topPad,
    this.onDeleted,
    this.onJumpToSeriesPart,
  });

  @override
  ConsumerState<_VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends ConsumerState<_VideoFeedItem> {
  final _service = VideoService();
  final _follow = FollowService();
  final _notif = NotificationService();
  final _auth = AuthService();

  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _muted = false;
  bool _saved = false;
  bool _descExpanded = false;
  bool _dragging = false;
  double _dragValue = 0;
  bool _viewRecorded = false;
  bool _autoLoop = false;

  VideoModel? _nextPart;
  bool _showNextPart = false;

  // Back button শুধু ট্যাপে দেখাবে
  bool _showBack = false;

  String? _myReaction;
  int _reactionCount = 0;
  int _commentCount = 0;
  Map<String, int> _reactionCounts = {};

  bool get _isOwner {
    final uid = _auth.currentUser?.id;
    return uid != null && uid == widget.video.authorId;
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    try {
      final ctrl =
          VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
      await ctrl.initialize();
      ctrl.setLooping(_autoLoop);
      ctrl.setVolume(_muted ? 0 : 1);
      ctrl.addListener(_tick);
      _controller = ctrl;

      if (widget.isActive) {
        await ctrl.play();
        _recordViewOnce();
      }

      final saved = await _service.isSaved(widget.video.id);
      final r = ReactionService();
      final mine = await r.getMyVideoReaction(widget.video.id);
      final counts = await r.countVideoReactions(widget.video.id);

      if (widget.video.isSeries) {
        final next = await _service.getNextPart(widget.video);
        if (mounted) setState(() => _nextPart = next);
      }

      if (!mounted) return;
      setState(() {
        _initialized = true;
        _saved = saved;
        _myReaction = mine;
        _reactionCount = counts;
        _reactionCounts = await _reactionCountsMap();
        _commentCount = widget.video.commentCount;
      });
    } catch (_) {
      if (mounted) setState(() => _initialized = false);
    }
  }

  Future<Map<String, int>> _reactionCountsMap() async {
    // ভিডিওর জন্য শুধু মোট জানা দরকার, তবুও map আকারে দেবার জন্য
    return {};
  }

  void _tick() {
    if (!mounted || _dragging) return;
    final c = _controller;
    if (c != null && c.value.isInitialized && !_autoLoop) {
      final pos = c.value.position;
      final dur = c.value.duration;
      if (dur.inMilliseconds > 0) {
        final nearEnd = pos >= dur - const Duration(seconds: 8);
        if (nearEnd && _nextPart != null && !_showNextPart) {
          setState(() => _showNextPart = true);
          return;
        }
      }
    }
    setState(() {});
  }

  void _recordViewOnce() {
    if (_viewRecorded) return;
    _viewRecorded = true;
    _service.recordView(widget.video.id);
  }

  @override
  void didUpdateWidget(covariant _VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c == null || !_initialized) return;
    if (widget.isActive && !oldWidget.isActive) {
      c.play();
      _recordViewOnce();
    } else if (!widget.isActive && oldWidget.isActive) {
      c.pause();
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !_initialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  void _toggleTap() {
    setState(() => _showBack = !_showBack);
    if (_showBack) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted && _showBack) setState(() => _showBack = false);
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
  
  // ---------- More menu ----------

  void _openMore() {
    final v = widget.video;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white),
              title: const Text('শেয়ার',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(
                  '${v.authorName ?? ""} · গল্পঘর ভিডিও\n#গল্পঘর',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: const Text('রিপোর্ট',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                ReportSheet.show(
                  context,
                  targetType: 'video',
                  targetId: v.id,
                  title: 'ভিডিও রিপোর্ট',
                );
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.loop, color: Colors.white),
              title: const Text('অটো লুপ',
                  style: TextStyle(color: Colors.white)),
              value: _autoLoop,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() => _autoLoop = val);
                _controller?.setLooping(val);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(
                _muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
              ),
              title: Text(
                _muted ? 'সাউন্ড চালু' : 'সাউন্ড বন্ধ',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _muted = !_muted);
                _controller?.setVolume(_muted ? 0 : 1);
              },
            ),
            if (_isOwner) ...[
              const Divider(color: Colors.white24),
              ListTile(
                leading:
                    const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text('সম্পাদনা',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('${RouteNames.createVideo}/${v.id}');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('মুছুন',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('ভিডিও মুছবেন?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(d, false),
                          child: const Text('না'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(d, true),
                          child: const Text('মুছুন',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await _service.deleteVideo(v.id);
                    widget.onDeleted?.call();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final c = _controller;
    final ok = _initialized && c != null && c.value.isInitialized;
    final pos = ok ? c.value.position : Duration.zero;
    final dur = ok ? c.value.duration : Duration.zero;
    final progress = (!ok || dur.inMilliseconds == 0)
        ? 0.0
        : (_dragging
            ? _dragValue
            : pos.inMilliseconds / dur.inMilliseconds);

    final bottomPad = MediaQuery.of(context).padding.bottom;
    // ভিডিও সাইজ — উপরে ও নিচে ছোট (ব্যানারের জন্য জায়গা)
    final topSpace = widget.topPad + 60;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ভিডিও — উপরে ও নিচে ছোট করে বসানো (ব্যানার এলে ঢাকা পড়বে না)
        Positioned(
          top: topSpace,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _toggleTap,
            onDoubleTap: _togglePlay,
            child: ok
                ? Center(
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio == 0
                          ? 9 / 16
                          : c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
                  )
                : const Center(
                    child:
                        CircularProgressIndicator(color: Colors.white),
                  ),
          ),
        ),

        // play icon (pause অবস্থায়)
        if (ok && !c.value.isPlaying)
          Center(
            child: IgnorePointer(
              child: Icon(
                Icons.play_circle_outline,
                size: 72,
                color: Colors.white70.withValues(alpha: 0.6),
              ),
            ),
          ),

        // Back button (ট্যাপে দেখাবে)
        if (_showBack)
          Positioned(
            top: topSpace + 8,
            left: 12,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),

        // সিরিজ পরবর্তী অংশ ওভারলে
        if (_showNextPart && _nextPart != null)
          Positioned(
            left: 16,
            right: 80,
            bottom: bottomPad + 90,
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                title: const Text(
                  'পরের অংশ দেখুন',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _nextPart!.title.isEmpty
                      ? 'পর্ব ${_nextPart!.partNumber}'
                      : _nextPart!.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    final n = _nextPart;
                    if (n == null) return;
                    setState(() => _showNextPart = false);
                    widget.onJumpToSeriesPart?.call(n);
                  },
                  child: const Text('দেখুন'),
                ),
                onTap: () {
                  final n = _nextPart;
                  if (n == null) return;
                  setState(() => _showNextPart = false);
                  widget.onJumpToSeriesPart?.call(n);
                },
              ),
            ),
          ),

        // ডান পাশের বাটন
        Positioned(
          right: 6,
          bottom: bottomPad + 120,
          child: Column(
            children: [
              // avatar + follow
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CachedAvatar(
                    userId: v.authorId,
                    imageUrl: v.authorAvatar,
                    name: v.authorName ?? 'লেখক',
                    radius: 22,
                  ),
                  Positioned(
                    bottom: -6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          try {
                            await _follow.toggleFollow(v.authorId);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ফলো আপডেট'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // reaction
              _sideBtn(
                _myReaction != null
                    ? Icons.favorite
                    : Icons.favorite_border,
                '$_reactionCount',
                () async {
                  final type =
                      await ReactionPicker.show(context) ?? 'like';
                  try {
                    final res = await ReactionService().toggleVideoReaction(
                      videoId: widget.video.id,
                      reactionType: type,
                    );
                    final count = await ReactionService()
                        .countVideoReactions(widget.video.id);

                    // নোটিফিকেশন
                    final myId = _auth.currentUser?.id;
                    if (myId != null && myId != v.authorId) {
                      await _notif.create(
                        targetUserId: v.authorId,
                        actorId: myId,
                        type: 'like',
                        targetType: 'video',
                        targetId: v.id,
                      );
                    }

                    if (mounted) {
                      setState(() {
                        _myReaction = res;
                        _reactionCount = count;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
                iconColor: _myReaction != null ? AppColors.love : null,
              ),
              const SizedBox(height: 14),

              // comment
              _sideBtn(
                Icons.chat_bubble_outline,
                '$_commentCount',
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) => SizedBox(
                      height:
                          MediaQuery.of(ctx).size.height * 0.75,
                      child: CommentSection(
                        videoId: widget.video.id,
                        ownerId: v.authorId,
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
              const SizedBox(height: 14),

              // save
              _sideBtn(
                _saved ? Icons.bookmark : Icons.bookmark_border,
                'সেভ',
                () async {
                  try {
                    final r = await _service.toggleSave(v.id);
                    if (mounted) setState(() => _saved = r);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
                iconColor: _saved ? AppColors.primary : null,
              ),
              const SizedBox(height: 14),

              // search
              _sideBtn(
                Icons.search,
                '',
                () => context.push(RouteNames.search),
              ),
              const SizedBox(height: 14),

              // more
              _sideBtn(Icons.more_vert, '', _openMore),
              const SizedBox(height: 14),

              // volume
              _sideBtn(
                _muted ? Icons.volume_off : Icons.volume_up,
                '',
                () {
                  setState(() => _muted = !_muted);
                  _controller?.setVolume(_muted ? 0 : 1);
                },
              ),
            ],
          ),
        ),

        // নিচের তথ্য (নাম, description, slider)
        Positioned(
          left: 12,
          right: 72,
          bottom: bottomPad + 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // author
              GestureDetector(
                onTap: () {
                  if (v.authorId.isNotEmpty) {
                    context.push('${RouteNames.user}/${v.authorId}');
                  }
                },
                child: Text(
                  v.authorName ?? 'লেখক',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              // description
              if (v.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () =>
                      setState(() => _descExpanded = !_descExpanded),
                  child: Text(
                    v.description,
                    maxLines: _descExpanded ? 20 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              // time ago
              const SizedBox(height: 2),
              Text(
                TimeAgo.bn(v.createdAt),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              // progress slider
              if (ok) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _fmt(pos),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.white24,
                          onChangeStart: (_) {
                            _dragging = true;
                            _dragValue = progress;
                          },
                          onChanged: (val) =>
                              setState(() => _dragValue = val),
                          onChangeEnd: (val) {
                            _dragging = false;
                            if (dur.inMilliseconds > 0) {
                              c.seekTo(
                                Duration(
                                  milliseconds:
                                      (val * dur.inMilliseconds).round(),
                                ),
                              );
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    Text(
                      _fmt(dur),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _sideBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 28),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
