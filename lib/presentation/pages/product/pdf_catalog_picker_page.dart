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
  PdfCatalogModel? _selectedCatalog;

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

  PdfCatalogModel? _resolveSelected(List<PdfCatalogModel> catalogs) {
    final selected = _selectedCatalog;
    if (selected == null) return null;
    for (final catalog in catalogs) {
      if (catalog.id == selected.id) return catalog;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final catalogs = _controller.catalogs;
        final selected = _resolveSelected(catalogs);
        final multi = catalogs.length > 1;
        final showCatalogList = multi && selected == null;

        return PopScope(
          canPop: !(multi && selected != null),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              setState(() => _selectedCatalog = null);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                !multi
                    ? 'Select from catalog'
                    : showCatalogList
                        ? 'Choose a catalog'
                        : selected?.title ?? 'Select from catalog',
              ),
            ),
            body: _buildBody(catalogs, selected, showCatalogList),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    List<PdfCatalogModel> catalogs,
    PdfCatalogModel? selected,
    bool showCatalogList,
  ) {
    if (_controller.isLoading && catalogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error.isNotEmpty && catalogs.isEmpty) {
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

    if (catalogs.isEmpty) {
      return const Center(
        child: Text('No design catalogs available right now.'),
      );
    }

    if (showCatalogList) {
      return RefreshIndicator(
        onRefresh: _controller.fetchCatalogs,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Text(
                'Choose a catalog to browse its pages.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            for (final catalog in catalogs)
              _CatalogListTile(
                catalog: catalog,
                onTap: () => setState(() => _selectedCatalog = catalog),
              ),
          ],
        ),
      );
    }

    final active = selected ?? catalogs.first;
    return RefreshIndicator(
      onRefresh: _controller.fetchCatalogs,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.pages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No pages available in this catalog.'),
              ),
            )
          else ...[
            const Text(
              'Tap a page, then tap the design you want. Only one design can be selected.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _CatalogPagesGrid(
              catalog: active,
              onPageTap: (page) => _openPage(active, page),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatalogListTile extends StatelessWidget {
  final PdfCatalogModel catalog;
  final VoidCallback onTap;

  const _CatalogListTile({
    required this.catalog,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = catalog.pages.isNotEmpty ? catalog.pages.first.imageUrl : '';
    final pageCount = catalog.pages.length;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 72,
          child: coverUrl.isEmpty
              ? Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.menu_book_outlined),
                )
              : CachedNetworkImage(
                  imageUrl: coverUrl,
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
        ),
      ),
      title: Text(
        catalog.title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$pageCount ${pageCount == 1 ? 'page' : 'pages'}',
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      trailing: const Icon(Icons.chevron_right),
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
