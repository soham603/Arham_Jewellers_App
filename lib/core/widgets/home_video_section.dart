import 'package:flutter/material.dart';
import 'package:ratnesh_gold_app/core/constants/social_links.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/home_video_model.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/utils/link_navigation_util.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class HomeVideoSection extends StatefulWidget {
  final HomeVideoModel? video;

  const HomeVideoSection({super.key, this.video});

  @override
  State<HomeVideoSection> createState() => _HomeVideoSectionState();
}

class _HomeVideoSectionState extends State<HomeVideoSection> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _isMuted = true;
  int _initToken = 0;

  String get _videoUrl => widget.video?.videoUrl.trim() ?? '';

  @override
  void initState() {
    super.initState();
    if (_videoUrl.isNotEmpty) {
      _initVideo();
    }
  }

  @override
  void didUpdateWidget(covariant HomeVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.video?.videoUrl.trim() ?? '') != _videoUrl) {
      _initToken++;
      _controller?.dispose();
      _controller = null;
      _initialized = false;
      _failed = false;
      if (_videoUrl.isNotEmpty) {
        _initVideo();
      } else if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initVideo() async {
    final token = ++_initToken;
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(_videoUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = ctrl;
    _isMuted = true;

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

  void _toggleMute() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final next = !_isMuted;
    ctrl.setVolume(next ? 0 : 1);
    setState(() => _isMuted = next);
  }

  Future<void> _openInstagram() async {
    final uri = Uri.parse(SocialLinks.instagramUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ToastUtils.showError('Unable to open Instagram');
    }
  }

  void _showOptions() {
    final video = widget.video;
    if (video == null) return;

    final linkType = video.linkType?.toLowerCase();
    final isProduct = linkType == 'product';
    final isCategory = linkType == 'category';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              if (isProduct || isCategory)
                ListTile(
                  leading: Icon(
                    isProduct
                        ? Icons.shopping_bag_rounded
                        : Icons.category_rounded,
                    color: AppColors.primaryGold,
                  ),
                  title: Text(
                    isProduct ? 'View Product' : 'View Collection',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: (video.linkName != null &&
                          video.linkName!.isNotEmpty)
                      ? Text(video.linkName!)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    LinkNavigationUtil.open(
                      linkType: video.linkType,
                      linkId: video.linkId,
                      linkRef: video.linkRef,
                      linkName: video.linkName,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primaryGold,
                ),
                title: const Text(
                  'View Instagram',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openInstagram();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoUrl.isEmpty || _failed) {
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

    return GestureDetector(
      onTap: _showOptions,
      child: AspectRatio(
        aspectRatio: ctrl.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(ctrl),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _toggleMute,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: 0.55,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Explore',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
