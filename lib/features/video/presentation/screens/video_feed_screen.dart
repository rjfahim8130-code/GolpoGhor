import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/models/video_model.dart';
import '../../../../core/services/video_service.dart';
import '../../../../core/theme/app_colors.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final _service = VideoService();
  List<VideoModel> _items = [];
  bool _loading = true;
  bool _enabled = false;
  String? _error;

  final PageController _pageController = PageController();
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
      final list = await _service.getFeed(limit: 30);
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'ভিডিও ফিচার এখন বন্ধ আছে।',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
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
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _items.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final video = _items[index];
          // ফিডের প্রতিটি পেজের জন্য আলাদা সিঙ্গেল ভিডিও আইটেম উইজেট
          return _VideoFeedItem(
            video: video,
            isActive: index == _currentIndex,
          );
        },
      ),
    );
  }
}

// தனி রিলস আইটেম উইজেট যা শুধুমাত্র স্ক্রিনে থাকা অবস্থায় প্লে হবে
class _VideoFeedItem extends StatefulWidget {
  final VideoModel video;
  final bool isActive;

  const _VideoFeedItem({required this.video, required this.isActive});

  @override
  State<_VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<_VideoFeedItem> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _muted = false;
  bool _saved = false;
  bool _descExpanded = false;
  final _service = VideoService();

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
      _controller = ctrl;
      await ctrl.initialize();
      ctrl.setLooping(false);
      ctrl.setVolume(_muted ? 0 : 1);
      
      if (widget.isActive) {
        ctrl.play();
        _service.recordView(widget.video.id);
      }

      final saved = await _service.isSaved(widget.video.id);

      if (mounted) {
        setState(() {
          _initialized = true;
          _saved = saved;
        });
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant _VideoFeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller != null && _initialized) {
      if (widget.isActive) {
        _controller!.play();
        _service.recordView(widget.video.id);
      } else {
        _controller!.pause();
        _controller!.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final v = widget.video;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ভিডিও প্লেয়ার কন্টেইনার
        Positioned(
          top: topPad + 8,
          left: 0,
          right: 0,
          bottom: bottomPad + 120,
          child: Center(
            child: _initialized && _controller != null
                ? GestureDetector(
                    onTap: _togglePlay,
                    child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio == 0
                          ? 9 / 16
                          : _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.white),
          ),
        ),

        // পজ আইকন ইন্ডিকেটর
        if (_initialized && _controller != null && !_controller!.value.isPlaying)
          Center(
            child: IgnorePointer(
              child: Icon(
                Icons.play_circle_outline,
                size: 72,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),

        // ক্লোজ বা ব্যাক বাটন
        Positioned(
          top: topPad + 4,
          left: 4,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),

        // ডান পাশের অ্যাকশন বার (প্রোফাইল, লাইক, কমেন্ট, শেয়ার ইত্যাদি)
        Positioned(
          right: 6,
          bottom: bottomPad + 140,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (v.authorId.isNotEmpty) context.push('/user/${v.authorId}');
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  backgroundImage: v.authorAvatar != null && v.authorAvatar!.isNotEmpty
                      ? CachedNetworkImageProvider(v.authorAvatar!)
                      : null,
                  child: v.authorAvatar == null || v.authorAvatar!.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 18),
              _sideBtn(Icons.favorite_border, '${v.reactionCount}', () {}),
              const SizedBox(height: 16),
              _sideBtn(Icons.chat_bubble_outline, '${v.commentCount}', () {}),
              const SizedBox(height: 16),
              _sideBtn(
                _saved ? Icons.bookmark : Icons.bookmark_border,
                'সেভ',
                () async {
                  final res = await _service.toggleSave(v.id);
                  setState(() => _saved = res);
                },
              ),
              const SizedBox(height: 16),
              _sideBtn(Icons.search, '', () => context.push('/search')),
              const SizedBox(height: 16),
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

        // নিচের বিবরণ ও ইনফো
        Positioned(
          left: 12,
          right: 72,
          bottom: bottomPad + 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.authorName ?? 'লেখক',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
