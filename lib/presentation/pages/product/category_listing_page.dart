import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ratnesh_gold_app/core/widgets/custom_divider.dart';
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

  Future<void> _showLevel3Sheet(CategoryModel parent, Karat karat) async {
    final children =
        await controller.fetchLevel3Categories(parentId: parent.id);

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
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ??
        '${widget.karats.map((k) => k.displayName).join(' & ')} Collection';

    return Scaffold(
      backgroundColor: context.colorPalette.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Align(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Image.asset(
                        _is22kOnly
                            ? 'assets/images/arham-logo.png'
                            : 'assets/images/ratnesh-logo.png',
                        height: _is22kOnly ? 110 : 80,
                        fit: BoxFit.contain,
                        color: context.colorPalette.goldDeep,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 8,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded,
                          color: context.colorPalette.goldDeep),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              if (!_is22kOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'RATNESHGOLD',
                    style: GoogleFonts.bodoniModa(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ),
              SizedBox(height: _is22kOnly ? 0 : 20),
              JewelleryDivider(vertical: _is22kOnly ? 0 : 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  title,
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
                  'Explore our exquisite collection of handcrafted jewellery',
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
            widget.karats.every((k) => _listForKarat(k).isEmpty)) {
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
                    color: context.colorPalette.goldDark,
                    fontSize: 16,
                  ),
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
                karat: widget.karats.first,
                onTap: () => _showLevel3Sheet(cat, widget.karats.first),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildMultiKaratView() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

class _CategoryListingImage extends StatelessWidget {
  final CategoryModel cat;
  final CategoryController controller;

  const _CategoryListingImage({
    required this.cat,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (cat.imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cat.imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _onImageError(context),
      );
    }

    return _fallbackOrPlaceholder(context);
  }

  Widget _onImageError(BuildContext context) {
    final fallback = controller.fallbackImages[cat.id];
    if (fallback != null && fallback.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: fallback,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _diamondPlaceholder(context),
      );
    }
    return _diamondPlaceholder(context);
  }

  Widget _fallbackOrPlaceholder(BuildContext context) {
    final fallback = controller.fallbackImages[cat.id];
    if (fallback != null && fallback.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: fallback,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _diamondPlaceholder(context),
      );
    }
    return _diamondPlaceholder(context);
  }

  Widget _diamondPlaceholder(BuildContext context) {
    if (!controller.isFallbackAttempted(cat.id) &&
        !controller.isFallbackLoading(cat.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchFallbackImage(cat.id, categoryName: cat.name);
      });
      return const SizedBox();
    }

    if (controller.isFallbackLoading(cat.id)) {
      return const SizedBox();
    }

    return Container(
      color: context.colorPalette.goldLight,
      child: Icon(
        Icons.diamond_outlined,
        size: 24,
        color: context.colorPalette.goldDark,
      ),
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

  String _purity(Karat k) {
    switch (k) {
      case Karat.k18:
        return '75%';
      case Karat.k20:
        return '83%';
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    context.colorPalette.gold,
                    context.colorPalette.goldDark,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isExpanded
                      ? context.colorPalette.goldLight
                      : context.colorPalette.cardBg,
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
                      ),
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
                  '${karat.displayName} Collection',
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
          karat: karat,
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
    // ✅ Get controller locally instead of as a field
    final controller = Get.find<CategoryController>();

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
                      border:
                          Border.all(color: context.colorPalette.border),
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
                              top: Radius.circular(13),
                            ),
                            // ✅ Fixed: use 'cat' and local 'controller'
                            child: _CategoryListingImage(
                              cat: cat,
                              controller: controller,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            cat.name
                                .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                                .replaceAll(
                                  RegExp(r'collection',
                                      caseSensitive: false),
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

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final Karat karat;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.karat,
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
                        child: CachedNetworkImage(
                          imageUrl: category.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: context.colorPalette.goldLight,
                            child: Icon(
                              Icons.diamond_outlined,
                              size: 24,
                              color: context.colorPalette.goldDark,
                            ),
                          ),
                        ),
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