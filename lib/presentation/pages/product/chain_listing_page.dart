import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import 'package:ratnesh_gold_app/core/widgets/custom_divider.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class ChainListingPage extends StatefulWidget {
  const ChainListingPage({super.key});

  @override
  State<ChainListingPage> createState() => _ChainListingPageState();
}

class _ChainListingPageState extends State<ChainListingPage> {
  final CategoryController controller = Get.find<CategoryController>();

  final _expandedKarats = <Karat>[].obs;
  final _isLoading = false.obs;
  final _hasError = false.obs;

  static const _allKarats = [Karat.k18, Karat.k20, Karat.k22];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _isLoading.value = true;
    _hasError.value = false;

    final allHaveData = _allKarats.every((k) =>
        _stateForKarat(k) == CurrentAppState.SUCCESS &&
        _filteredCategories(k).isNotEmpty);

    // CategoryController fetches tree eagerly in onInit()
    // Only fetch if data is not yet available
    if (!allHaveData) {
      try {
        await controller.fetchCategoryTree().timeout(
              const Duration(seconds: 15),
            );
      } catch (e) {
        Logger.warning("ChainListingPage", "Failed to fetch categories: $e");
      }
    }

    bool anyError = false;
    for (final karat in _allKarats) {
      if (_stateForKarat(karat) == CurrentAppState.ERROR &&
          _filteredCategories(karat).isEmpty) {
        anyError = true;
      }
    }

    if (!anyError && !allHaveData) {
      anyError = _allKarats.every((k) =>
          _stateForKarat(k) != CurrentAppState.SUCCESS &&
          _filteredCategories(k).isEmpty);
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

  List<CategoryModel> _rawListForKarat(Karat karat) {
    switch (karat) {
      case Karat.k18:
        return controller.k18Categories;
      case Karat.k20:
        return controller.k20Categories;
      case Karat.k22:
        return controller.k22Categories;
    }
  }

  List<CategoryModel> _filteredCategories(Karat karat) {
    return _rawListForKarat(karat)
        .where((cat) => cat.name.toUpperCase().contains('CHAIN'))
        .toList();
  }

  List<CategoryModel> _filteredLevel3(CategoryModel parent) {
    return controller.level3Cache[parent.id] ?? [];
  }

  void _toggleKarat(Karat karat) {
    if (_expandedKarats.contains(karat)) {
      _expandedKarats.remove(karat);
    } else {
      _expandedKarats.add(karat);
    }
  }

  Future<void> _showLevel3Sheet(CategoryModel parent, Karat karat) async {
    final children = _filteredLevel3(parent);

    if (!mounted) return;

    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No styles available under ${parent.name.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim()}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ChainLevel3Sheet(
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
                    .replaceAll(
                      RegExp(r'collection', caseSensitive: false),
                      '',
                    )
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_rounded,
                      color: context.colorPalette.goldDeep),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 4),
              JewelleryDivider(vertical: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Chain Collection',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.colorPalette.goldDeep,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Explore our exquisite chain collection across all karats',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colorPalette.goldDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (_isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_hasError.value &&
                    _allKarats.every((k) => _filteredCategories(k).isEmpty)) {
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
                            color: context.colorPalette.goldDark,
                            fontSize: 16,
                          ),
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

                if (_allKarats.every((k) => _filteredCategories(k).isEmpty)) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diamond_outlined,
                            color: context.colorPalette.goldDark, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No chain categories found',
                          style: TextStyle(
                            color: context.colorPalette.goldDark,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMultiKaratView();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiKaratView() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        for (final karat in _allKarats) ...[
          _ChainKaratSectionHeader(
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
                    child: _ChainCategoryGrid(
                      categories: _filteredCategories(karat),
                      karat: karat,
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

// ── _ChainCategoryGrid ────────────────────────────────────────────────────────
class _ChainCategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final Karat karat;
  final ValueChanged<CategoryModel> onTap;

  const _ChainCategoryGrid({
    required this.categories,
    required this.karat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No chain categories in ${karat.displayName}',
            style: TextStyle(
              fontSize: 13,
              color: context.colorPalette.goldDark,
            ),
          ),
        ),
      );
    }

    final controller = Get.find<CategoryController>();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: context.isTablet ? 0.72 : 0.85,
      ),
      itemBuilder: (_, index) {
        final cat = categories[index];
        return _ChainCategoryCard(
          category: cat,
          karat: karat,
          controller: controller,
          onTap: () => onTap(cat),
        );
      },
    );
  }
}

// ── _ChainCategoryCard ────────────────────────────────────────────────────────
class _ChainCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final Karat karat;
  final CategoryController controller;
  final VoidCallback onTap;

  const _ChainCategoryCard({
    required this.category,
    required this.karat,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colorPalette.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colorPalette.border),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(13),
                        ),
                        child: _ChainCategoryImage(cat: category),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colorPalette.gold,
                          ),
                          child: Center(
                            child: Text(
                              karat.displayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: Text(
                      category.name
                          .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                          .replaceAll(
                            RegExp(r'collection', caseSensitive: false),
                            '',
                          )
                          .trim(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.goldDeep,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ChainCategoryImage ───────────────────────────────────────────────────────
class _ChainCategoryImage extends StatelessWidget {
  final CategoryModel cat;

  const _ChainCategoryImage({required this.cat});

  @override
  Widget build(BuildContext context) {
    if (cat.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cat.imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => const RatneshFallback.s(),
      );
    }

    return const RatneshFallback.s();
  }
}

// ── _ChainKaratSectionHeader ──────────────────────────────────────────────────
class _ChainKaratSectionHeader extends StatelessWidget {
  final Karat karat;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _ChainKaratSectionHeader({
    required this.karat,
    required this.isExpanded,
    required this.onToggle,
  });

  String _purity(Karat k) {
    switch (k) {
      case Karat.k18:
        return '76%';
      case Karat.k20:
        return '84%';
      case Karat.k22:
        return '92%';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.responsiveWidth(38, tabletVal: 46),
              height: context.responsiveWidth(38, tabletVal: 46),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorPalette.gold,
                  width: 2,
                ),
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.colorPalette.gold,
                      context.colorPalette.goldDeep,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    karat.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${karat.displayName} Chains',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.goldDeep,
                  ),
                ),
                Text(
                  '${_purity(karat)} Pure Gold',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colorPalette.goldDark,
                  ),
                ),
              ],
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

// ── _ChainLevel3Sheet ─────────────────────────────────────────────────────────
class _ChainLevel3Sheet extends StatelessWidget {
  final CategoryModel parent;
  final List<CategoryModel> children;
  final Karat karat;
  final ValueChanged<CategoryModel> onSelect;

  const _ChainLevel3Sheet({
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
            margin: EdgeInsets.only(
                top: context.responsiveWidth(10, tabletVal: 12)),
            width: context.responsiveWidth(40, tabletVal: 48),
            height: context.responsiveWidth(4, tabletVal: 5),
            decoration: BoxDecoration(
              color: context.colorPalette.goldDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.responsiveWidth(20, tabletVal: 24),
              context.responsiveWidth(16, tabletVal: 18),
              context.responsiveWidth(20, tabletVal: 24),
              context.responsiveWidth(12, tabletVal: 14),
            ),
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
                          RegExp(r'collection', caseSensitive: false),
                          '',
                        )
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: context.gridColumns(phone: 3, tablet: 4),
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
                          color: Colors.black.withValues(alpha: 0.06),
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
                              top: Radius.circular(13),
                            ),
                            child: _ChainCategoryImage(cat: cat),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            cat.name
                                .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                                .replaceAll(
                                  RegExp(r'collection', caseSensitive: false),
                                  '',
                                )
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
