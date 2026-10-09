import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/models/video_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({super.key, required this.videoId});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _videoService = VideoService();
  final _auth = AuthService();

  VideoModel? _video;
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  bool _muted = false;
  bool _showControls = true;
  bool _dragging = false;
  double _dragValue = 0;

  // ইউজার প্রেফারেন্স (⋮ মেনু — পরে SharedPreferences)
  bool _autoLoop = false;
  bool _autoNext = true;

  bool _saved = false;
  bool _descExpanded = false;

  bool get _isOwner {
    final uid = _auth.currentUser?.id;
    return uid != null && _video != null && _video!.authorId == uid;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _load();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onTick() {
    if (mounted && !_dragging) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enabled = await _videoService.isVideoFeatureEnabled();
      if (!enabled) {
        setState(() {
          _error = 'ভিডিও ফিচার এখন বন্ধ আছে।';
          _loading = false;
        });
        return;
      }

      final v = await _videoService.getById(widget.videoId);
      if (v == null) {
        setState(() {
          _error = 'ভিডিও পাওয়া যায়নি';
          _loading = false;
        });
        return;
      }

      final ctrl = VideoPlayerController.networkUrl(Uri.parse(v.videoUrl));
      await ctrl.initialize();
      ctrl.setLooping(_autoLoop);
      ctrl.setVolume(_muted ? 0 : 1);
      ctrl.addListener(_onTick);
      await ctrl.play();

      _videoService.recordView(v.id);
      final saved = await _videoService.isSaved(v.id);

      if (!mounted) {
        ctrl.dispose();
        return;
      }

      setState(() {
        _video = v;
        _controller = ctrl;
        _saved = saved;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'লোড সমস্যা: $e';
        _loading = false;
      });
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
    setState(() {});
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
  }

  void _seekTo(Duration d) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final max = c.value.duration;
    var t = d;
    if (t < Duration.zero) t = Duration.zero;
    if (t > max) t = max;
    c.seekTo(t);
  }

  Future<void> _onVideoEnded() async {
    final c = _controller;
    final v = _video;
    if (c == null || v == null) return;
    if (_autoLoop) return;

    if (_autoNext && v.isSeries) {
      final next = await _videoService.getNextPart(v);
      if (next != null && mounted) {
        context.pushReplacement('/video/${next.id}');
        return;
      }
    }
  }

  void _openMore() {
    final v = _video;
    if (v == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('শেয়ার'),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(
                  '${v.title.isEmpty ? "গল্পঘর ভিডিও" : v.title}\n#গল্পঘর',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('রিপোর্ট'),
              onTap: () {
                Navigator.pop(ctx);
                // ReportSheet পরে video_id দিয়ে
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('রিপোর্ট শীঘ্রই')),
                );
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.loop),
              title: const Text('অটো লুপ'),
              value: _autoLoop,
              onChanged: (val) {
                setState(() => _autoLoop = val);
                _controller?.setLooping(val);
                Navigator.pop(ctx);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.skip_next),
              title: const Text('অটো নেক্সট / স্ক্রল'),
              value: _autoNext,
              onChanged: (val) {
                setState(() => _autoNext = val);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              title: Text(_muted ? 'সাউন্ড চালু' : 'সাউন্ড বন্ধ'),
              onTap: () {
                Navigator.pop(ctx);
                _toggleMute();
              },
            ),
            if (_isOwner) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('সম্পাদনা'),
                onTap: () {
                  Navigator.pop(ctx);
                  // /edit-video/:id পরে
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('মুছুন', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('ভিডিও মুছবেন?'),
                      content: const Text('একেবারে মুছে যাবে।'),
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
                    await _videoService.deleteVideo(v.id);
                    if (mounted) context.pop();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave() async {
    try {
      final on = await _videoService.toggleSave(widget.videoId);
      setState(() => _saved = on);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null || _video == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            _error ?? 'সমস্যা',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final v = _video!;
    final c = _controller;
    final initialized = c != null && c.value.isInitialized;
    final pos = initialized ? c.value.position : Duration.zero;
    final dur = initialized ? c.value.duration : Duration.zero;
    final progress = (!_dragging && dur.inMilliseconds > 0)
        ? pos.inMilliseconds / dur.inMilliseconds
        : _dragValue;

    // শেষ হলে নেক্সট
    if (initialized &&
        dur.inMilliseconds > 0 &&
        pos >= dur - const Duration(milliseconds: 400) &&
        !c.value.isPlaying &&
        !_autoLoop) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onVideoEnded());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // উপর–নিচ সেফ স্পেস + মাঝে ভিডিও
          Positioned(
            top: topPad + 8,
            left: 0,
            right: 0,
            bottom: bottomPad + 120,
            child: Center(
              child: initialized
                  ? GestureDetector(
                      onTap: _togglePlay,
                      onHorizontalDragUpdate: (d) {
                        if (!initialized || dur.inMilliseconds <= 0) return;
                        final delta = d.primaryDelta ?? 0;
                        final ms = (delta / MediaQuery.of(context).size.width) *
                            dur.inMilliseconds *
                            2;
                        _seekTo(pos + Duration(milliseconds: ms.round()));
                      },
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio == 0
                            ? 9 / 16
                            : c.value.aspectRatio,
                        child: VideoPlayer(c),
                      ),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // পজ আইকন (পজ থাকলে)
          if (initialized && !c.value.isPlaying)
            Center(
              child: IgnorePointer(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),

          // ক্লোজ
          Positioned(
            top: topPad + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),

          // ডান অ্যাকশন বার
          Positioned(
            right: 6,
            bottom: bottomPad + 140,
            child: Column(
              children: [
                _sideProfile(v),
                const SizedBox(height: 18),
                _sideBtn(Icons.favorite_border, '${v.reactionCount}', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('প্রতিক্রিয়া শীঘ্রই')),
                  );
                }),
                const SizedBox(height: 16),
                _sideBtn(Icons.chat_bubble_outline, '${v.commentCount}', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('মন্তব্য শীঘ্রই')),
                  );
                }),
                const SizedBox(height: 16),
                _sideBtn(
                  _saved ? Icons.bookmark : Icons.bookmark_border,
                  'সেভ',
                  _toggleSave,
                ),
                const SizedBox(height: 16),
                _sideBtn(Icons.search, '', () => context.push('/search')),
                const SizedBox(height: 16),
                _sideBtn(Icons.more_vert, '', _openMore),
                const SizedBox(height: 16),
                _sideBtn(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  '',
                  _toggleMute,
                ),
              ],
            ),
          ),

          // নিচের তথ্য + প্রোগ্রেস
          Positioned(
            left: 12,
            right: 72,
            bottom: bottomPad + 12,
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
                  if (v.description.length > 80)
                    Text(
                      _descExpanded ? 'কম' : 'আরও',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
                if (v.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    v.tags.map((t) => '#$t').join(' '),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                if (initialized)
                  Row(
                    children: [
                      Text(
                        _fmt(pos),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
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
                            onChanged: (val) {
                              setState(() => _dragValue = val);
                            },
                            onChangeEnd: (val) {
                              _dragging = false;
                              if (dur.inMilliseconds > 0) {
                                _seekTo(
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
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideProfile(VideoModel v) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (v.authorId.isNotEmpty) context.push('/user/${v.authorId}');
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
            onTap: () {
              // FollowService পরে
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ফলো শীঘ্রই')),
              );
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
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
