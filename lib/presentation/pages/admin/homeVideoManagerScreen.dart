import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';
import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/presentation/controllers/AuthController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/home_video_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

class HomeVideoManagerScreen extends StatefulWidget {
  const HomeVideoManagerScreen({super.key});

  @override
  State<HomeVideoManagerScreen> createState() => _HomeVideoManagerScreenState();
}

class _HomeVideoManagerScreenState extends State<HomeVideoManagerScreen> {
  late final HomeVideoController controller;

  File? _pickedFile;
  bool _isPicking = false;

  bool get _isSuperAdmin =>
      Get.find<AuthController>().user?.role == 'SUPERADMIN';

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<HomeVideoController>()
        ? Get.find<HomeVideoController>()
        : Get.put(HomeVideoController(), permanent: true);

    if (controller.video == null) {
      controller.fetchVideo();
    }
  }

  @override
  void dispose() {
    VideoCompress.cancelCompression();
    super.dispose();
  }

  Future<File?> _compressVideo(File file) async {
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (info != null && info.file != null) {
        return info.file!;
      }
      return file;
    } catch (e) {
      return file;
    }
  }

  Future<void> _pickVideo() async {
    if (!_isSuperAdmin || _isPicking) return;

    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );

    if (picked == null || !mounted) return;

    setState(() => _isPicking = true);

    final compressed = await _compressVideo(File(picked.path));

    if (!mounted) return;
    setState(() {
      _pickedFile = compressed;
      _isPicking = false;
    });
  }

  Future<void> _savePicked() async {
    final file = _pickedFile;
    if (file == null) return;

    final ok = await controller.uploadVideo(
      file,
      isActive: controller.video?.isActive ?? true,
    );

    if (!mounted) return;

    if (ok) {
      ToastUtils.showSuccess('Home video updated');
      setState(() => _pickedFile = null);
    } else {
      ToastUtils.showError(controller.error);
    }
  }

  Future<void> _toggleActive(bool value) async {
    final ok = await controller.setActive(value);
    if (!mounted) return;
    if (!ok) {
      ToastUtils.showError(controller.error);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colorPalette.backgroundColor,
        title: Text(
          'Delete home video?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'This removes the video from the storefront and permanently deletes the file.',
          style: TextStyle(color: context.colorPalette.subTitleColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colorPalette.subTitleColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final ok = await controller.deleteVideo();
    if (!mounted) return;

    if (ok) {
      ToastUtils.showSuccess('Home video deleted');
      setState(() => _pickedFile = null);
    } else {
      ToastUtils.showError(controller.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.pageBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.colorPalette.backgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Home Video',
          style: TextStyle(
            fontSize: context.getResponsiveSize(5.5),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _isSuperAdmin
          ? Obx(_buildBody)
          : Center(
              child: Padding(
                padding: EdgeInsets.all(context.getResponsiveSize(6)),
                child: Text(
                  'Only super admins can manage the home video.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.getResponsiveSize(4),
                    color: context.colorPalette.subTitleColor,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    final video = controller.video;
    final isFetching =
        controller.state == CurrentAppState.LOADING && video == null;
    final isBusy =
        controller.uploadState == CurrentAppState.LOADING ||
        controller.toggleState == CurrentAppState.LOADING ||
        controller.deleteState == CurrentAppState.LOADING ||
        _isPicking;

    return RefreshIndicator(
      color: AppColors.primaryGold,
      backgroundColor: Colors.white,
      onRefresh: () async {
        await controller.fetchVideo();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: context.getResponsiveSize(4),
          vertical: context.heightPercent(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storefront promo',
              style: TextStyle(
                fontSize: context.getResponsiveSize(4.2),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: context.heightPercent(0.6)),
            Text(
              'Shown on the home screen. Upload a portrait or landscape clip — it adapts to any orientation.',
              style: TextStyle(
                fontSize: context.getResponsiveSize(3.2),
                color: context.colorPalette.subTitleColor,
              ),
            ),
            SizedBox(height: context.heightPercent(2)),
            if (_pickedFile != null) ...[
              _label('New video ready to save'),
              SizedBox(height: context.heightPercent(1)),
              _VideoPreview(file: _pickedFile),
              SizedBox(height: context.heightPercent(1.5)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () => setState(() => _pickedFile = null),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: context.heightPercent(1.4),
                        ),
                        side: BorderSide(color: context.colorPalette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: context.colorPalette.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.getResponsiveSize(3)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isBusy ? null : _savePicked,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colorPalette.primaryColor,
                        padding: EdgeInsets.symmetric(
                          vertical: context.heightPercent(1.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _label('Current video'),
              SizedBox(height: context.heightPercent(1)),
              if (isFetching)
                _shimmerBox()
              else if (video == null || video.videoUrl.isEmpty)
                _emptyState()
              else
                _VideoPreview(networkUrl: video.videoUrl),
              SizedBox(height: context.heightPercent(2)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isBusy ? null : _pickVideo,
                  icon: _isPicking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.video_library_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isPicking
                        ? 'Compressing…'
                        : video == null
                        ? 'Upload Video'
                        : 'Replace Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorPalette.primaryColor,
                    padding: EdgeInsets.symmetric(
                      vertical: context.heightPercent(1.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (video != null) ...[
                SizedBox(height: context.heightPercent(1.5)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.getResponsiveSize(3),
                    vertical: context.heightPercent(0.4),
                  ),
                  decoration: BoxDecoration(
                    color: context.colorPalette.boxColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.colorPalette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visible on storefront',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3.6),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              video.isActive
                                  ? 'Currently shown on the home screen'
                                  : 'Hidden from the home screen',
                              style: TextStyle(
                                fontSize: context.getResponsiveSize(3),
                                color: context.colorPalette.subTitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: video.isActive,
                        activeThumbColor: context.colorPalette.primaryColor,
                        onChanged: isBusy ? null : _toggleActive,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: context.heightPercent(1.5)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Delete Video',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: context.heightPercent(1.4),
                      ),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: context.getResponsiveSize(3.6),
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: context.heightPercent(6)),
      decoration: BoxDecoration(
        color: context.colorPalette.boxColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorPalette.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.movie_creation_outlined,
            size: context.getResponsiveSize(12),
            color: context.colorPalette.gold.withValues(alpha: 0.6),
          ),
          SizedBox(height: context.heightPercent(1)),
          Text(
            'No home video yet',
            style: TextStyle(
              fontSize: context.getResponsiveSize(3.8),
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: context.colorPalette.shimmerBaseColor,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  final String? networkUrl;
  final File? file;

  const _VideoPreview({this.networkUrl, this.file});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  String? get _source => widget.file?.path ?? widget.networkUrl;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSource = oldWidget.file?.path ?? oldWidget.networkUrl;
    if (oldSource != _source) {
      _disposeController();
      _init();
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _initialized = false;
  }

  Future<void> _init() async {
    final file = widget.file;
    final url = widget.networkUrl;

    VideoPlayerController? ctrl;
    if (file != null) {
      ctrl = VideoPlayerController.file(file);
    } else if (url != null && url.isNotEmpty) {
      ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    if (ctrl == null) return;
    _controller = ctrl;

    try {
      await ctrl.initialize();
      await ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();
      if (!mounted) return;
      setState(() => _initialized = true);
    } catch (_) {
      await ctrl.dispose();
      _controller = null;
      if (!mounted) return;
      setState(() => _initialized = false);
    }
  }

  void _toggle() {
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
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: context.colorPalette.shimmerBaseColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.play_circle_outline_rounded,
              size: context.getResponsiveSize(10),
              color: context.colorPalette.gold.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final ctrl = _controller!;
    final isPlaying = ctrl.value.isPlaying;

    return GestureDetector(
      onTap: _toggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
                    padding: EdgeInsets.all(context.getResponsiveSize(2.5)),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: context.getResponsiveSize(7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
