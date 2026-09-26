import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class HomeVideoSection extends StatefulWidget {
  final String videoUrl;

  const HomeVideoSection({super.key, required this.videoUrl});

  @override
  State<HomeVideoSection> createState() => _HomeVideoSectionState();
}

class _HomeVideoSectionState extends State<HomeVideoSection> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;
  int _initToken = 0;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.trim().isNotEmpty) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant HomeVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl.trim() != widget.videoUrl.trim()) {
      _initToken++;
      _controller?.dispose();
      _controller = null;
      _initialized = false;
      _failed = false;
      if (widget.videoUrl.trim().isNotEmpty) {
        _initVideo();
      } else if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initVideo() async {
    final token = ++_initToken;
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl.trim()),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = ctrl;

    try {
      await ctrl.initialize();
      if (!mounted || token != _initToken) return;
      await ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();

      if (!mounted || token != _initToken) return;
      setState(() => _initialized = true);
    } catch (_) {
      await ctrl.dispose();
      if (!mounted || token != _initToken) return;
      _controller = null;
      setState(() => _failed = true);
    }
  }

  void _togglePlayback() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl.trim().isEmpty || _failed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.getResponsiveSize(4),
        vertical: context.heightPercent(1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: _initialized && _controller != null
              ? _buildVideo(context)
              : AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Shimmer.fromColors(
                    baseColor: AppColors.primaryGold.withValues(alpha: 0.15),
                    highlightColor: AppColors.primaryGold.withValues(
                      alpha: 0.35,
                    ),
                    period: const Duration(milliseconds: 1200),
                    child: Container(color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildVideo(BuildContext context) {
    final ctrl = _controller!;
    final isPlaying = ctrl.value.isPlaying;

    return GestureDetector(
      onTap: _togglePlayback,
      child: AspectRatio(
        aspectRatio: ctrl.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(ctrl),
            if (!isPlaying) ...[
              Container(color: Colors.black.withValues(alpha: 0.25)),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
