import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class CategoryListingPage extends StatefulWidget {
  final List<Karat> karats;
  final String? title;

  const CategoryListingPage({super.key, required this.karats, this.title});

  @override
  State<CategoryListingPage> createState() => _CategoryListingPageState();
}

class _CategoryListingPageState extends State<CategoryListingPage> {
  final CategoryController controller = Get.find<CategoryController>();

  final _expandedKarats = <Karat>[].obs;
  final _isLoading = false.obs;
  final _hasError = false.obs;
  bool _initialExpandDone = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _isLoading.value = true;
    _hasError.value = false;

    bool anyError = false;

    for (final karat in widget.karats) {
      final state = _stateForKarat(karat);
      if (state == CurrentAppState.INITIAL) {
        await controller.fetchCategoriesForKarat(karat);
      }
      if (_stateForKarat(karat) == CurrentAppState.ERROR &&
          _listForKarat(karat).isEmpty) {
        anyError = true;
      }
    }

    if (!_initialExpandDone && widget.karats.length > 1) {
      _expandedKarats.add(widget.karats.first);
      _initialExpandDone = true;
    }

    _isLoading.value = false;
    _hasError.value = anyError;
  }

  CurrentAppState _stateForKarat(Karat karat) {
    switch (karat) {
      case Karat.k18:
        return controller.k18State;
      case Karat.k20:
        return controller.k20State;
      case Karat.k22:
        return controller.k22State;
    }
  }

  List<CategoryModel> _listForKarat(Karat karat) {
    switch (karat) {
      case Karat.k18:
        return controller.k18Categories;
      case Karat.k20:
        return controller.k20Categories;
      case Karat.k22:
        return controller.k22Categories;
    }
  }

  void _toggleKarat(Karat karat) {
    if (_expandedKarats.contains(karat)) {
      _expandedKarats.remove(karat);
    } else {
      _expandedKarats.add(karat);
    }
  }

  bool get _isMultiKarat => widget.karats.length > 1;

  Future<void> _showLevel3Sheet(CategoryModel parent, Karat karat) async {
    final children = await controller.fetchLevel3Categories(parentId: parent.id);

    if (!mounted) return;

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No styles available under ${parent.name.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _Level3Sheet(
        parent: parent,
        children: children,
        karat: karat,
        onSelect: (child) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductListingPage(
                categoryId: child.id,
                karat: karat.displayName,
                title: child.name
                    .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                    .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                    .trim(),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorPalette.cream,
      appBar: AppBar(
        title: Text(
          widget.title ??
              widget.karats.map((k) => k.displayName).join(' & ') +
                  ' Collection',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: context.colorPalette.goldDeep,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.colorPalette.cream,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: context.colorPalette.goldDeep),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Obx(() {
        if (_isLoading.value &&
            widget.karats.every(
                (k) => _listForKarat(k).isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_hasError.value &&
            widget.karats
                .every((k) => _listForKarat(k).isEmpty)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    color: context.colorPalette.goldDark, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Failed to load categories',
                  style: TextStyle(
                      color: context.colorPalette.goldDark, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colorPalette.gold,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (widget.karats.every((k) => _listForKarat(k).isEmpty)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond_outlined,
                    color: context.colorPalette.goldDark, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No categories found',
                  style: TextStyle(
                      color: context.colorPalette.goldDark, fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (_isMultiKarat) {
          return _buildMultiKaratView();
        }

        final categories = _listForKarat(widget.karats.first);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (_, index) {
              final cat = categories[index];
              return _CategoryCard(
                category: cat,
                onTap: () =>
                    _showLevel3Sheet(cat, widget.karats.first),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildMultiKaratView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final karat in widget.karats) ...[
          _KaratSectionHeader(
            karat: karat,
            isExpanded: _expandedKarats.contains(karat),
            onToggle: () => _toggleKarat(karat),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expandedKarats.contains(karat)
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _CategoryGrid(
                      categories: _listForKarat(karat),
                      onTap: (cat) => _showLevel3Sheet(cat, karat),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _KaratSectionHeader extends StatelessWidget {
  final Karat karat;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _KaratSectionHeader({
    required this.karat,
    required this.isExpanded,
    required this.onToggle,
  });

  Color _accentColor(BuildContext context) {
    switch (karat) {
      case Karat.k18:
        return context.colorPalette.k18Accent;
      case Karat.k20:
        return context.colorPalette.k20Accent;
      case Karat.k22:
        return context.colorPalette.k22Accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(context);
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isExpanded
              ? context.colorPalette.goldLight
              : context.colorPalette.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isExpanded
                ? context.colorPalette.gold
                : context.colorPalette.border,
            width: isExpanded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.85), accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                karat.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Gold',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colorPalette.goldDeep,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: context.colorPalette.goldDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final ValueChanged<CategoryModel> onTap;

  const _CategoryGrid({
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        final cat = categories[index];
        return _CategoryCard(
          category: cat,
          onTap: () => onTap(cat),
        );
      },
    );
  }
}

class _Level3Sheet extends StatelessWidget {
  final CategoryModel parent;
  final List<CategoryModel> children;
  final Karat karat;
  final ValueChanged<CategoryModel> onSelect;

  const _Level3Sheet({
    required this.parent,
    required this.children,
    required this.karat,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.52,
      decoration: BoxDecoration(
        color: context.colorPalette.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorPalette.goldDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(Icons.grid_view_rounded,
                    size: 20, color: context.colorPalette.goldDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parent.name
                        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                        .replaceAll(
                            RegExp(r'collection', caseSensitive: false), '')
                        .trim(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                Text(
                  karat.displayName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.goldDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colorPalette.border),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: children.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (_, index) {
                final cat = children[index];
                return GestureDetector(
                  onTap: () => onSelect(cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colorPalette.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colorPalette.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(13)),
                            child: CachedNetworkImage(
                              imageUrl: cat.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: context.colorPalette.goldLight,
                                child: Icon(Icons.diamond_outlined,
                                    color: context.colorPalette.goldDark),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            cat.name
                                .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                                .replaceAll(
                                    RegExp(r'collection', caseSensitive: false),
                                    '')
                                .trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colorPalette.goldDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colorPalette.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colorPalette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: CachedNetworkImage(
                  imageUrl: category.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: context.colorPalette.goldLight,
                    child: Icon(
                      Icons.diamond_outlined,
                      size: 36,
                      color: context.colorPalette.goldDark,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      category.name
                          .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                          .replaceAll(
                              RegExp(r'collection', caseSensitive: false), '')
                          .trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.goldDeep,
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
