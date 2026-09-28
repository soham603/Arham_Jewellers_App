import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ratnesh_gold_app/domain/entities/pdf_catalog_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/pdf_catalog_controller.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/pdf_page_selection_page.dart';

class PdfCatalogPickerPage extends StatefulWidget {
  final CatalogDesignSelection? initialSelection;
  final bool persistSelection;

  const PdfCatalogPickerPage({
    super.key,
    this.initialSelection,
    this.persistSelection = true,
  });

  @override
  State<PdfCatalogPickerPage> createState() => _PdfCatalogPickerPageState();
}

class _PdfCatalogPickerPageState extends State<PdfCatalogPickerPage> {
  late final PdfCatalogController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<PdfCatalogController>()
        ? Get.find<PdfCatalogController>()
        : Get.put(PdfCatalogController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchCatalogs();
    });
  }

  Future<void> _openPage(
    PdfCatalogModel catalog,
    PdfCatalogPageModel page,
  ) async {
    final existing = widget.initialSelection ?? _controller.selection;
    final Offset? initialTick =
        (existing != null && existing.pageId == page.id)
            ? Offset(existing.x, existing.y)
            : null;

    final result = await Get.to<Offset>(
      () => PdfPageSelectionPage(
        catalogTitle: catalog.title,
        page: page,
        initialTick: initialTick,
      ),
    );

    if (result == null) return;

    final selection = CatalogDesignSelection(
      catalogId: catalog.id,
      catalogTitle: catalog.title,
      pageId: page.id,
      pageNumber: page.pageNumber,
      imageUrl: page.imageUrl,
      width: page.width,
      height: page.height,
      x: result.dx,
      y: result.dy,
    );

    if (widget.persistSelection) {
      await _controller.saveSelection(selection);
    }

    if (mounted) Get.back(result: selection);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select from catalog')),
      body: Obx(
        () {
          if (_controller.isLoading && _controller.catalogs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.error.isNotEmpty && _controller.catalogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_controller.error),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _controller.fetchCatalogs,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_controller.catalogs.isEmpty) {
            return const Center(
              child: Text('No design catalogs available right now.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.fetchCatalogs,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Tap a page, then tap the design you want. Only one design can be selected.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                for (final catalog in _controller.catalogs) ...[
                  Text(
                    catalog.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CatalogPagesGrid(
                    catalog: catalog,
                    onPageTap: (page) => _openPage(catalog, page),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CatalogPagesGrid extends StatelessWidget {
  final PdfCatalogModel catalog;
  final ValueChanged<PdfCatalogPageModel> onPageTap;

  const _CatalogPagesGrid({
    required this.catalog,
    required this.onPageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: catalog.pages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final page = catalog.pages[index];
        return InkWell(
          onTap: () => onPageTap(page),
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: page.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, _, _) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: Text(
                      'Page ${page.pageNumber}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
