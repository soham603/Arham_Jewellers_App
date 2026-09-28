import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ratnesh_gold_app/core/theme/app_colors.dart';
import 'package:ratnesh_gold_app/domain/entities/pdf_catalog_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/admin/AdminPdfCatalogController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class PdfCatalogManagerScreen extends StatefulWidget {
  const PdfCatalogManagerScreen({super.key});

  @override
  State<PdfCatalogManagerScreen> createState() =>
      _PdfCatalogManagerScreenState();
}

class _PdfCatalogManagerScreenState extends State<PdfCatalogManagerScreen> {
  late final AdminPdfCatalogController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<AdminPdfCatalogController>()
        ? Get.find<AdminPdfCatalogController>()
        : Get.put(AdminPdfCatalogController());
    _controller.fetchCatalogs();
  }

  Future<void> _showUploadDialog() async {
    final titleCtrl = TextEditingController();
    File? pickedFile;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Upload PDF catalog'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pickedFile == null
                          ? 'No file selected'
                          : pickedFile!.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf'],
                        allowMultiple: false,
                      );
                      final path = result?.files.single.path;
                      if (path != null && path.isNotEmpty) {
                        setLocal(() => pickedFile = File(path));
                      }
                    },
                    child: const Text('Choose PDF'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: _controller.isUploading
                    ? null
                    : () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ToastUtils.showWarning('Enter a title');
                          return;
                        }
                        if (pickedFile == null) {
                          ToastUtils.showWarning('Choose a PDF file');
                          return;
                        }

                        final ok = await _controller.uploadCatalog(
                          file: pickedFile!,
                          title: title,
                        );

                        if (ok && ctx.mounted) Get.back();
                      },
                child: _controller.isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PdfCatalogModel catalog) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete catalog?'),
        content: Text(
          '"${catalog.title}" will no longer appear in the order form. '
          'Existing orders keep their selected design.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteCatalog(catalog.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        title: const Text('PDF Catalogs'),
        backgroundColor: AppColors.pageBg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload PDF'),
      ),
      body: Obx(() {
        if (_controller.isLoading && _controller.catalogs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.catalogs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No PDF catalogs yet.\nUpload a PDF to offer design choices in the custom order form.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchCatalogs,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: _controller.catalogs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final catalog = _controller.catalogs[index];
              return _CatalogCard(
                catalog: catalog,
                isDeleting: _controller.isDeleting(catalog.id),
                onDelete: () => _confirmDelete(catalog),
                onTogglePage: (page, isActive) => _controller.togglePage(
                  catalogId: catalog.id,
                  page: page,
                  isActive: isActive,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final PdfCatalogModel catalog;
  final bool isDeleting;
  final VoidCallback onDelete;
  final void Function(PdfCatalogPageModel page, bool isActive) onTogglePage;

  const _CatalogCard({
    required this.catalog,
    required this.isDeleting,
    required this.onDelete,
    required this.onTogglePage,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = catalog.pages.where((p) => p.isActive).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catalog.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: context.getResponsiveSize(4),
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeCount of ${catalog.pages.length} pages shown',
                      style: TextStyle(
                        fontSize: context.getResponsiveSize(3),
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDeleting)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: catalog.pages.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final page = catalog.pages[index];
              return _PageTile(
                page: page,
                onToggle: (value) => onTogglePage(page, value),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  final PdfCatalogPageModel page;
  final ValueChanged<bool> onToggle;

  const _PageTile({required this.page, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: page.isActive
              ? AppColors.primaryGold.withValues(alpha: 0.6)
              : const Color(0xFFE0E0E0),
          width: page.isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: page.imageUrl,
                    fit: BoxFit.cover,
                    color: page.isActive ? null : Colors.grey,
                    colorBlendMode:
                        page.isActive ? null : BlendMode.saturation,
                    placeholder: (_, _) => Container(color: Colors.grey.shade200),
                    errorWidget: (_, _, _) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                  if (!page.isActive)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.visibility_off,
                          color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  'P${page.pageNumber}',
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: page.isActive,
                    onChanged: onToggle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
