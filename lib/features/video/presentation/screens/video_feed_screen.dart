import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/models/video_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../../../social/presentation/widgets/report_sheet.dart';
import '../widgets/video_comment_sheet.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final _service = VideoService();
  final _pageController = PageController();
  List<VideoModel> _items = [];
  bool _loading = true;
  bool _enabled = false;
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
      final on = await _service.isVideoFeatureEnabled();
      if (!on) {
        setState(() {
          _enabled = false;
          _loading = false;
          _items = [];
        });
        return;
      }
      final list = await _service.getFeed(limit: 40);
      setState(() {
        _enabled = true;
        _items = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // বিজ্ঞাপন ব্যানার বা AppBar-এর জন্য নিরাপদ টপ স্পেস (ধরে নিলাম ৬০ logical pixels)
    final double adSpaceHeight = MediaQuery.of(context).padding.top + 60;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!_enabled) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'ভিডিও ফিচার এখন বন্ধ আছে।',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_error != null || _items.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () => context.push('/create-video'),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Center(
          child: Text(
            _error ?? 'এখনো কোনো ভিডিও নেই',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          await context.push('/create-video');
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
                adSpaceHeight: adSpaceHeight,
                onDeleted: () {
                  setState(() => _items.removeAt(index));
                },
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: adSpaceHeight,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoFeedItem extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final VoidCallback? onDeleted;
  final double adSpaceHeight;

  const _VideoFeedItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.adSpaceHeight,
    this.onDeleted,
  });

  @override
  State<_VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<_VideoFeedItem> {
  final _service = VideoService();
  final _follow = FollowService();
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

  // সিরিজ ও নেক্সট পার্ট সম্পর্কিত স্টেট
  VideoModel? _nextPart;
  bool _showNextPart = false;
  bool _autoNext = true;

  bool _showControls = false;
  IconData _volumeIcon = Icons.volume_up;

  String? _myReaction;
  int _reactionCount = 0;
  int _commentCount = 0;

  bool get _isOwner {
    final uid = _auth.currentUser?.id;
    return uid != null && uid == widget.video.authorId;
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _volumeIcon = _muted ? Icons.volume_off : Icons.volume_up;
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

      // যদি ভিডিওটি সিরিজ হয়, তবে পরের অংশ ফেচ করা
      if (widget.video.isSeries) {
        final next = await _service.getNextPart(widget.video);
        if (mounted) setState(() => _nextPart = next);
      }

      if (mounted) {
        setState(() {
          _initialized = true;
          _saved = saved;
          _myReaction = mine;
          _reactionCount = widget.video.reactionCount;
          _commentCount = widget.video.commentCount;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _initialized = false);
    }
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

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    super.dispose();
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

  void _seekRelative(double dx, double width, Duration pos, Duration dur) {
    if (dur.inMilliseconds <= 0) return;
    final ms = (dx / width) * dur.inMilliseconds * 2;
    var t = pos + Duration(milliseconds: ms.round());
    if (t < Duration.zero) t = Duration.zero;
    if (t > dur) t = dur;
    _controller?.seekTo(t);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
       Future.delayed(const Duration(milliseconds: 2500), () {
         if (mounted && _showControls) {
           setState(() => _showControls = false);
         }
       });
    }
  }

  void _openMore() {
    final v = widget.video;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined, color: Colors.white),
              title: const Text('শেয়ার', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(
                  '${v.authorName ?? ""} · গল্পঘর ভিডিও\n#গল্পঘর',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.white),
              title: const Text('রিপোর্ট', style: TextStyle(color: Colors.white)),
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
              title: const Text('অটো লুপ', style: TextStyle(color: Colors.white)),
              value: _autoLoop,
              onChanged: (val) {
                setState(() => _autoLoop = val);
                _controller?.setLooping(val);
                Navigator.pop(ctx);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.skip_next, color: Colors.white),
              title: const Text('অটো নেক্সট', style: TextStyle(color: Colors.white)),
              value: _autoNext,
              onChanged: (val) {
                setState(() => _autoNext = val);
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
                setState(() {
                  _muted = !_muted;
                  _volumeIcon = _muted ? Icons.volume_off : Icons.volume_up;
                });
                _controller?.setVolume(_muted ? 0 : 1);
              },
            ),
            if (_isOwner) ...[
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('মুছুন', style: TextStyle(color: Colors.red)),
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
                          child: const Text('মুছুন'),
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
    
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: widget.adSpaceHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: _togglePlay,
            child: ok
                ? Center(
                    child: AspectRatio(
                      aspectRatio: c.value.aspectRatio == 0
                          ? 9 / 16
                          : c.value.aspectRatio,
                      child: VideoPlayer(c),
                    ),
                  )
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        ),
        
        if (ok && !c.value.isPlaying)
          Center(
            child: IgnorePointer(
              child: Icon(Icons.play_circle_outline,
                  size: 72, color: Colors.white70.withValues(alpha: 0.5)),
            ),
          ),

        Positioned(
            top: widget.adSpaceHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _toggleControls,
              child: Container(color: Colors.transparent),
            ),
        ),

        if(_showControls)
           Positioned(
            top: widget.adSpaceHeight + 8,
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

        // সিরিজের পরবর্তী অংশের জন্য ওভারলে ব্যানার
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _nextPart!.title.isEmpty
                      ? 'পর্ব ${_nextPart!.partNumber}'
                      : _nextPart!.title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: TextButton(
                  onPressed: () {
                    setState(() => _showNextPart = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('নিচে স্ক্রল করে পরের ভিডিও দেখুন, অথবা সিরিজ ফিডে খুঁজুন'),
                      ),
                    );
                  },
                  child: const Text('ঠিক আছে'),
                ),
                onTap: () {
                  setState(() => _showNextPart = false);
                },
              ),
            ),
          ),

        Positioned(
          right: 6,
          bottom: bottomPad + 120,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (v.authorId.isNotEmpty) {
                    context.push('/user/${v.authorId}');
                  }
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  backgroundImage:
                      v.authorAvatar != null && v.authorAvatar!.isNotEmpty
                          ? CachedNetworkImageProvider(v.authorAvatar!)
                          : null,
                  child: v.authorAvatar == null || v.authorAvatar!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: GestureDetector(
                  onTap: () async {
                    try {
                      await _follow.toggleFollow(v.authorId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ফলো আপডেট')),
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
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _sideBtn(
                _myReaction != null ? Icons.favorite : Icons.favorite_border,
                '$_reactionCount',
                () async {
                  final type = await ReactionPicker.show(context) ?? 'like';
                  try {
                    final res = await ReactionService().toggleVideoReaction(
                      videoId: widget.video.id,
                      reactionType: type,
                    );
                    final count =
                        await ReactionService().countVideoReactions(widget.video.id);
                    setState(() {
                      _myReaction = res;
                      _reactionCount = count;
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 14),
              _sideBtn(Icons.chat_bubble_outline, '$_commentCount', () {
                VideoCommentSheet.show(context, videoId: widget.video.id);
              }),
              const SizedBox(height: 14),
              _sideBtn(
                _saved ? Icons.bookmark : Icons.bookmark_border,
                'সেভ',
                () async {
                  try {
                    final r = await _service.toggleSave(v.id);
                    setState(() => _saved = r);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 14),
              _sideBtn(Icons.search, '', () => context.push('/search')),
              const SizedBox(height: 14),
              _sideBtn(Icons.more_vert, '', _openMore),
              const SizedBox(height: 14),
              _sideBtn(
                _volumeIcon,
                '',
                () {
                  setState(() {
                    _muted = !_muted;
                     _volumeIcon = _muted ? Icons.volume_off : Icons.volume_up;
                  });
                  _controller?.setVolume(_muted ? 0 : 1);
                },
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 72,
          bottom: bottomPad + 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (v.authorId.isNotEmpty) {
                    context.push('/user/${v.authorId}');
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
              if (v.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _descExpanded = !_descExpanded),
                  child: Text(
                    v.description,
                    maxLines: _descExpanded ? 20 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
              if (ok) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _fmt(pos),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
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
                              c.seekTo(Duration(
                                milliseconds:
                                    (val * dur.inMilliseconds).round(),
                              ));
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                    Text(
                      _fmt(dur),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10),
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

  Widget _sideBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          if (label.isNotEmpty)
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
