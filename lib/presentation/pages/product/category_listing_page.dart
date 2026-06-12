import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import 'package:ratnesh_gold_app/core/widgets/custom_divider.dart';
import 'package:ratnesh_gold_app/core/widgets/logo_widget.dart';
import 'package:ratnesh_gold_app/core/widgets/ratnesh_fallback.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/pages/product/product_listing_page.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class CategoryListingPage extends StatefulWidget {
  final List<Karat> karats;
  final String? title;
  final bool showBothLogos;

  const CategoryListingPage({
    super.key,
    required this.karats,
    this.title,
    this.showBothLogos = false,
  });

  @override
  State<CategoryListingPage> createState() => _CategoryListingPageState();
}

class _CategoryListingPageState extends State<CategoryListingPage> {
  final CategoryController controller = Get.find<CategoryController>();

  final _expandedKarats = <Karat>[].obs;
  final _isLoading = false.obs;
  final _hasError = false.obs;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _isLoading.value = true;
    _hasError.value = false;

    final allHaveData = widget.karats.every((k) =>
        _stateForKarat(k) == CurrentAppState.SUCCESS &&
        _listForKarat(k).isNotEmpty);

    if (!allHaveData) {
      try {
        await controller.fetchAllKaratCategories().timeout(
              const Duration(seconds: 15),
            );
      } catch (e) {
        Logger.warning("CategoryListingPage", "Failed to fetch categories: $e");
      }
    }

    bool anyError = false;
    for (final karat in widget.karats) {
      if (_stateForKarat(karat) == CurrentAppState.ERROR &&
          _listForKarat(karat).isEmpty) {
        anyError = true;
      }
    }

    if (!anyError && !allHaveData) {
      anyError = widget.karats.every((k) =>
          _stateForKarat(k) != CurrentAppState.SUCCESS &&
          _listForKarat(k).isEmpty);
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
      if (karat == Karat.k18) _expandedKarats.remove(Karat.k20);
      if (karat == Karat.k20) _expandedKarats.remove(Karat.k18);
      _expandedKarats.add(karat);
    }
  }

  bool get _isMultiKarat => widget.karats.length > 1;

  bool get _is22kOnly => !_isMultiKarat && widget.karats.first == Karat.k22;

  double _gridAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 1.0;
    if (width >= 900) return 0.92;
    if (width >= 600) return 0.82;
    return 0.85;
  }

  double _gridSpacing(BuildContext context) {
    return context.responsiveWidth(12, tabletVal: 16);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showBothLogos
        ? 'Shree Arham Gold & Ratnesh Gold Design Catalog'
        : (widget.title ??
            '${widget.karats.map((k) => k.displayName).join(' & ')} Collection');

    return Scaffold(
      backgroundColor: context.colorPalette.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Align(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: context.responsiveWidth(16, tabletVal: 24),
                            ),
                            child: widget.showBothLogos
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LogoWidget(
                                        showIcon: true,
                                        showName: false,
                                        showSubtitle: false,
                                        logoSize: context.responsiveWidth(60, tabletVal: 80),
                                        logoAsset: 'assets/images/arham-logo.png',
                                        iconColor: context.colorPalette.goldDark,
                                      ),
                                      SizedBox(width: context.responsiveWidth(16, tabletVal: 24)),
                                      LogoWidget(
                                        showIcon: true,
                                        showName: false,
                                        showSubtitle: false,
                                        logoSize: context.responsiveWidth(60, tabletVal: 80),
                                        logoAsset: 'assets/images/ratnesh-logo.png',
                                        iconColor: context.colorPalette.goldDark,
                                      ),
                                    ],
                                  )
                                : _is22kOnly
                                    ? LogoWidget(
                                        showIcon: true,
                                        showName: false,
                                        showSubtitle: false,
                                        logoSize: context.responsiveWidth(80, tabletVal: 110),
                                        logoAsset: 'assets/images/arham-logo.png',
                                        iconColor: context.colorPalette.goldDark,
                                      )
                                    : LogoWidget(
                                        showIcon: true,
                                        showName: true,
                                        showSubtitle: false,
                                        logoSize: context.responsiveWidth(80, tabletVal: 110),
                                      ),
                          ),
                        ),
                        Positioned(
                          left: context.responsiveWidth(4, tabletVal: 12),
                          top: context.responsiveWidth(8, tabletVal: 16),
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_rounded,
                                color: context.colorPalette.goldDeep),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: context.responsiveWidth(
                        _is22kOnly ? 16 : 20,
                        tabletVal: 28,
                      ),
                    ),
                    JewelleryDivider(vertical: _is22kOnly ? 0 : 4),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.responsiveWidth(20, tabletVal: 32),
                        context.responsiveWidth(16, tabletVal: 24),
                        context.responsiveWidth(20, tabletVal: 32),
                        context.responsiveWidth(4, tabletVal: 6),
                      ),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: context.responsiveFont(20),
                          fontWeight: FontWeight.w800,
                          color: context.colorPalette.goldDeep,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsiveWidth(20, tabletVal: 32),
                      ),
                      child: Text(
                        'Explore our exquisite collection of handcrafted jewellery',
                        style: TextStyle(
                          fontSize: context.responsiveFont(13),
                          color: context.colorPalette.goldDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: context.responsiveWidth(12, tabletVal: 20)),
                    Obx(() {
                      if (_isLoading.value) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(
                              context.responsiveWidth(32, tabletVal: 48),
                            ),
                            child: const CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (_hasError.value &&
                          widget.karats.every((k) => _listForKarat(k).isEmpty)) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(
                              context.responsiveWidth(32, tabletVal: 48),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    color: context.colorPalette.goldDark,
                                    size: context.responsiveWidth(48, tabletVal: 64)),
                                SizedBox(
                                  height: context.responsiveWidth(12, tabletVal: 16),
                                ),
                                Text(
                                  'Failed to load categories',
                                  style: TextStyle(
                                    color: context.colorPalette.goldDark,
                                    fontSize: context.responsiveFont(16),
                                  ),
                                ),
                                SizedBox(
                                  height: context.responsiveWidth(16, tabletVal: 24),
                                ),
                                ElevatedButton(
                                  onPressed: _loadAll,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colorPalette.gold,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.responsiveWidth(24, tabletVal: 36),
                                      vertical: context.responsiveWidth(12, tabletVal: 16),
                                    ),
                                  ),
                                  child: Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontSize: context.responsiveFont(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (widget.karats.every((k) => _listForKarat(k).isEmpty)) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.all(
                              context.responsiveWidth(32, tabletVal: 48),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.diamond_outlined,
                                    color: context.colorPalette.goldDark,
                                    size: context.responsiveWidth(48, tabletVal: 64)),
                                SizedBox(
                                  height: context.responsiveWidth(12, tabletVal: 16),
                                ),
                                Text(
                                  'No categories found',
                                  style: TextStyle(
                                    color: context.colorPalette.goldDark,
                                    fontSize: context.responsiveFont(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (_isMultiKarat) {
                        return _buildMultiKaratView();
                      }

                      final categories = _listForKarat(widget.karats.first);
                      final spacing = _gridSpacing(context);
                      return Padding(
                        padding: EdgeInsets.all(
                          context.responsiveWidth(16, tabletVal: 24),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            childAspectRatio: _gridAspectRatio(context),
                          ),
                          itemBuilder: (_, index) {
                            final cat = categories[index];
                            return _CategoryCard(
                              category: cat,
                              karat: widget.karats.first,
                              controller: controller,
                              onTap: () {
                                _showLevel3Sheet(cat, widget.karats.first);
                              },
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLevel3Sheet(CategoryModel parent, Karat karat) async {
    final children = controller.level3Cache[parent.id] ?? [];

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

  Widget _buildMultiKaratView() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(context.responsiveWidth(16, tabletVal: 24)),
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
                    padding: EdgeInsets.only(
                      bottom: context.responsiveWidth(16, tabletVal: 24),
                    ),
                    child: _CategoryGrid(
                      categories: _listForKarat(karat),
                      karat: karat,
                      onTap: (cat) {
                        _showLevel3Sheet(cat, karat);
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

// ── _CategoryListingImage 
class _CategoryListingImage extends StatelessWidget {
  final CategoryModel cat;

  const _CategoryListingImage({
    required this.cat,
  });

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

// ── _KaratSectionHeader 
class _KaratSectionHeader extends StatelessWidget {
  final Karat karat;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _KaratSectionHeader({
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
        margin: EdgeInsets.only(
          bottom: context.responsiveWidth(8, tabletVal: 12),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveWidth(16, tabletVal: 24),
          vertical: context.responsiveWidth(14, tabletVal: 20),
        ),
        decoration: BoxDecoration(
          color: isExpanded
              ? context.colorPalette.goldLight
              : context.colorPalette.cardBg,
          borderRadius: BorderRadius.circular(
            context.responsiveWidth(14, tabletVal: 18),
          ),
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
              width: context.responsiveWidth(38, tabletVal: 52),
              height: context.responsiveWidth(38, tabletVal: 52),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorPalette.gold,
                  width: context.responsiveWidth(2, tabletVal: 3),
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
                    style: TextStyle(
                      fontSize: context.responsiveFont(12),
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: context.responsiveWidth(10, tabletVal: 14)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${karat.displayName} Collection',
                  style: TextStyle(
                    fontSize: context.responsiveFont(16),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.goldDeep,
                  ),
                ),
                Text(
                  '${_purity(karat)} Pure Gold',
                  style: TextStyle(
                    fontSize: context.responsiveFont(10),
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
                size: context.responsiveWidth(24, tabletVal: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _CategoryGrid 
class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final Karat karat;
  final ValueChanged<CategoryModel> onTap;

  const _CategoryGrid({
    required this.categories,
    required this.karat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();
    final width = MediaQuery.of(context).size.width;
    final spacing = width >= 600 ? 16.0 : 12.0;

    double aspectRatio;
    if (width >= 1200) {
      aspectRatio = 1.0;
    } else if (width >= 900) {
      aspectRatio = 0.92;
    } else if (width >= 600) {
      aspectRatio = 0.82;
    } else {
      aspectRatio = 0.85;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns(phone: 2, tablet: 3),
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      itemBuilder: (_, index) {
        final cat = categories[index];
        return _CategoryCard(
          category: cat,
          karat: karat,
          controller: controller,
          onTap: () => onTap(cat),
        );
      },
    );
  }
}

// ── _Level3Sheet 
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Container(
      decoration: BoxDecoration(
        color: context.colorPalette.cream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.responsiveWidth(20, tabletVal: 24)),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 200,
          maxHeight: screenHeight * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(
                top: context.responsiveWidth(10, tabletVal: 14),
              ),
              width: context.responsiveWidth(40, tabletVal: 56),
              height: context.responsiveWidth(4, tabletVal: 6),
              decoration: BoxDecoration(
                color: context.colorPalette.goldDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                context.responsiveWidth(20, tabletVal: 28),
                context.responsiveWidth(16, tabletVal: 22),
                context.responsiveWidth(20, tabletVal: 28),
                context.responsiveWidth(12, tabletVal: 16),
              ),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded,
                      size: context.responsiveWidth(20, tabletVal: 26),
                      color: context.colorPalette.goldDark),
                  SizedBox(width: context.responsiveWidth(8, tabletVal: 12)),
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
                        fontSize: context.responsiveFont(18),
                        fontWeight: FontWeight.w700,
                        color: context.colorPalette.goldDeep,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveWidth(10, tabletVal: 14),
                      vertical: context.responsiveWidth(4, tabletVal: 6),
                    ),
                    decoration: BoxDecoration(
                      color: context.colorPalette.goldLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      karat.displayName,
                      style: TextStyle(
                        fontSize: context.responsiveFont(13),
                        fontWeight: FontWeight.w600,
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.colorPalette.border),
            Flexible(
              child: GridView.builder(
                padding: EdgeInsets.all(
                  context.responsiveWidth(16, tabletVal: 20),
                ),
                itemCount: children.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.gridColumns(phone: 3, tablet: 4),
                  mainAxisSpacing: isTablet ? 16 : 12,
                  crossAxisSpacing: isTablet ? 16 : 12,
                  childAspectRatio: isTablet ? 0.85 : 0.78,
                ),
                itemBuilder: (_, index) {
                  final cat = children[index];
                  return GestureDetector(
                    onTap: () => onSelect(cat),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colorPalette.cardBg,
                        borderRadius: BorderRadius.circular(
                          context.responsiveWidth(14, tabletVal: 16),
                        ),
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
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(
                                  context.responsiveWidth(13, tabletVal: 15),
                                ),
                              ),
                              child: _CategoryListingImage(
                                cat: cat,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(
                              context.responsiveWidth(6, tabletVal: 10),
                            ),
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
                                fontSize: context.responsiveFont(11),
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
      ),
    );
  }
}

// ── _CategoryCard 
class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final Karat karat;
  final CategoryController controller;
  final VoidCallback onTap;

  const _CategoryCard({
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
          borderRadius: BorderRadius.circular(
            context.responsiveWidth(14, tabletVal: 18),
          ),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 7,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        context.responsiveWidth(13, tabletVal: 17),
                      ),
                    ),
                    child: _CategoryListingImage(
                      cat: category,
                    ),
                  ),
                  Positioned(
                    top: context.responsiveWidth(6, tabletVal: 10),
                    right: context.responsiveWidth(6, tabletVal: 10),
                    child: Container(
                      width: context.responsiveWidth(24, tabletVal: 32),
                      height: context.responsiveWidth(24, tabletVal: 32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colorPalette.gold,
                      ),
                      child: Center(
                        child: Text(
                          karat.displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: context.responsiveFont(9, tabletMultiplier: 1.5),
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
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveWidth(10, tabletVal: 14),
                  vertical: context.responsiveWidth(2, tabletVal: 6),
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
                    fontSize: context.responsiveFont(11),
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.goldDeep,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
