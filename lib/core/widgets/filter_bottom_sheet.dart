import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

typedef FilterApplyCallback = void Function({
  required List<String> karats,
  required List<String> categoryIds,
  required List<String> categoryNames,
  required String stockFilter,
  required double wMin,
  required double wMax,
  required double pMin,
  required double pMax,
  required List<String> sizes,
});

class FilterBottomSheet extends StatefulWidget {
  final List<String> initialSelectedKarats;
  final String initialStockFilter;
  final double initialWeightMin;
  final double initialWeightMax;
  final FilterApplyCallback onApply;
  final bool showKaratFilter;
  final bool showStockFilter;
  final bool showWeightFilter;
  final bool showPriceFilter;
  final double initialPriceMin;
  final double initialPriceMax;
  final double priceSliderMax;
  final double weightSliderMax;
  final List<ProductModel> products;
  final bool showCategoryFilter;
  final List<CategoryModel> categories;
  final List<String> initialSelectedCategoryIds;

  const FilterBottomSheet({
    super.key,
    required this.initialSelectedKarats,
    required this.initialStockFilter,
    required this.initialWeightMin,
    required this.initialWeightMax,
    required this.onApply,
    this.showKaratFilter = true,
    this.showStockFilter = true,
    this.showWeightFilter = true,
    this.showPriceFilter = false,
    this.showCategoryFilter = false,
    this.initialPriceMin = 0,
    this.initialPriceMax = 5000000,
    this.priceSliderMax = 5000000,
    this.weightSliderMax = 200,
    this.products = const [],
    this.categories = const [],
    this.initialSelectedCategoryIds = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> initialSelectedKarats,
    required String initialStockFilter,
    required double initialWeightMin,
    required double initialWeightMax,
    required FilterApplyCallback onApply,
    bool showKaratFilter = true,
    bool showStockFilter = true,
    bool showWeightFilter = true,
    bool showPriceFilter = false,
    bool showCategoryFilter = false,
    double initialPriceMin = 0,
    double initialPriceMax = 5000000,
    double priceSliderMax = 5000000,
    double weightSliderMax = 200,
    List<ProductModel> products = const [],
    List<CategoryModel> categories = const [],
    List<String> initialSelectedCategoryIds = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        initialSelectedKarats: initialSelectedKarats,
        initialStockFilter: initialStockFilter,
        initialWeightMin: initialWeightMin,
        initialWeightMax: initialWeightMax,
        onApply: onApply,
        showKaratFilter: showKaratFilter,
        showStockFilter: showStockFilter,
        showWeightFilter: showWeightFilter,
        showPriceFilter: showPriceFilter,
        showCategoryFilter: showCategoryFilter,
        initialPriceMin: initialPriceMin,
        initialPriceMax: initialPriceMax,
        priceSliderMax: priceSliderMax,
        weightSliderMax: weightSliderMax,
        products: products,
        categories: categories,
        initialSelectedCategoryIds: initialSelectedCategoryIds,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  static const List<String> _karatOptions = ['18K', '20K', '22K'];
  static const double _minWeightSliderMax = 1.0;
  static const double _minPriceSliderMax = 1.0;

  late List<String> _tempSelectedKarats;
  late String _tempStockFilter;
  late double _tempWeightMin;
  late double _tempWeightMax;
  late double _tempPriceMin;
  late double _tempPriceMax;
  late double _effectiveWeightSliderMax;
  late Set<String> _tempSelectedCategoryIds;
  bool _categoriesExpanded = false;

  @override
  void initState() {
    super.initState();

    _tempSelectedKarats = List<String>.from(widget.initialSelectedKarats);

    _tempStockFilter = widget.initialStockFilter;

    _tempSelectedCategoryIds = Set<String>.from(widget.initialSelectedCategoryIds);

    _effectiveWeightSliderMax =
        widget.weightSliderMax.clamp(_minWeightSliderMax, double.infinity);
    _tempWeightMin =
        widget.initialWeightMin.clamp(0.0, _effectiveWeightSliderMax);
    _tempWeightMax =
        widget.initialWeightMax.clamp(0.0, _effectiveWeightSliderMax);
    if (_tempWeightMin > _tempWeightMax) {
      _tempWeightMax = _effectiveWeightSliderMax;
    }

    final effectivePriceMax =
        widget.priceSliderMax.clamp(_minPriceSliderMax, double.infinity);
    _tempPriceMin = widget.initialPriceMin.clamp(0.0, effectivePriceMax);
    _tempPriceMax = widget.initialPriceMax.clamp(0.0, effectivePriceMax);
    if (_tempPriceMin > _tempPriceMax) {
      _tempPriceMax = effectivePriceMax;
    }
  }

  // ──────────────────────── Helpers ────────────────────────

  void _recomputeWeightSliderMax() {
    final products = widget.products;
    if (products.isEmpty) {
      setState(() {
        _effectiveWeightSliderMax = widget.weightSliderMax
            .clamp(_minWeightSliderMax, double.infinity);
        _clampWeightValues();
      });
      return;
    }

    var filtered = products.toList();

    if (_tempSelectedKarats.isNotEmpty) {
      filtered = filtered.where((p) {
        final k = p.karat;
        return k != null && _tempSelectedKarats.contains(k);
      }).toList();
    }

    var maxWeight = 0.0;
    for (final p in filtered) {
      final gw = p.grossWeight;
      if (gw != null && gw > maxWeight) maxWeight = gw;
    }

    setState(() {
      _effectiveWeightSliderMax = maxWeight > 0
          ? maxWeight.ceilToDouble()
          : widget.weightSliderMax
              .clamp(_minWeightSliderMax, double.infinity);
      _clampWeightValues();
    });
  }

  void _clampWeightValues() {
    _tempWeightMax = _tempWeightMax.clamp(0.0, _effectiveWeightSliderMax);
    _tempWeightMin = _tempWeightMin.clamp(0.0, _tempWeightMax);
  }

  int get _activeFilterCount {
    var count = 0;
    if (widget.showKaratFilter && _tempSelectedKarats.isNotEmpty) {
      count += _tempSelectedKarats.length;
    }
    if (widget.showStockFilter && _tempStockFilter != 'ready') {
      count++;
    }
    if (widget.showWeightFilter &&
        (_tempWeightMin > 0 ||
            _tempWeightMax < _effectiveWeightSliderMax)) {
      count++;
    }
    if (widget.showPriceFilter &&
        (_tempPriceMin > 0 || _tempPriceMax < widget.priceSliderMax)) {
      count++;
    }
    if (widget.showCategoryFilter && _tempSelectedCategoryIds.isNotEmpty) {
      count += _tempSelectedCategoryIds.length;
    }
    return count;
  }

  // ──────────────────────── Actions ────────────────────────

  void _toggleKarat(String karat) {
    setState(() {
      if (_tempSelectedKarats.contains(karat)) {
        _tempSelectedKarats.remove(karat);
      } else {
        _tempSelectedKarats.add(karat);
      }
    });
    _recomputeWeightSliderMax();
  }

  void _clearAll() {
    setState(() {
      if (widget.showKaratFilter) _tempSelectedKarats.clear();
      if (widget.showStockFilter) _tempStockFilter = 'ready';
      if (widget.showWeightFilter) {
        _tempWeightMin = 0;
        _tempWeightMax = _effectiveWeightSliderMax;
      }
      if (widget.showPriceFilter) {
        _tempPriceMin = 0;
        _tempPriceMax = widget.priceSliderMax;
      }
      if (widget.showCategoryFilter) _tempSelectedCategoryIds.clear();
    });
  }

  void _apply() {
    final selectedIds = _tempSelectedCategoryIds.toList();
    final selectedNames = widget.categories
        .where((c) => selectedIds.contains(c.id))
        .map((c) => c.name
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim())
        .toList();
    widget.onApply(
      karats: List<String>.from(_tempSelectedKarats),
      categoryIds: selectedIds,
      categoryNames: selectedNames,
      stockFilter: _tempStockFilter,
      wMin: _tempWeightMin,
      wMax: _tempWeightMax,
      pMin: _tempPriceMin,
      pMax: _tempPriceMax,
      sizes: const [],
    );
    Navigator.pop(context);
  }

  // ──────────────────────── Build ────────────────────────

  @override
  Widget build(BuildContext context) {
    final filterCount = _activeFilterCount;

    return Container(
      height: context.isTablet
          ? MediaQuery.of(context).size.height * 0.45
          : MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        color: context.colorPalette.cream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            context.responsiveWidth(14, tabletVal: 16),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          _buildHeader(context, filterCount),
          Divider(height: 1, color: context.colorPalette.border),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                context.responsiveWidth(10, tabletVal: 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showKaratFilter) ...[
                    _buildKaratSection(context),
                    const SizedBox(height: 14),
                  ],
                  if (widget.showCategoryFilter &&
                      widget.categories.isNotEmpty) ...[
                    _buildCategorySection(context),
                    const SizedBox(height: 14),
                  ],
                  if (widget.showStockFilter) ...[
                    _buildStockSection(context),
                    const SizedBox(height: 14),
                  ],
                  if (widget.showWeightFilter) ...[
                    _buildWeightSection(context),
                    const SizedBox(height: 14),
                  ],
                  if (widget.showPriceFilter) _buildPriceSection(context),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: context.colorPalette.border),
          _buildActions(context, filterCount),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      width: 32,
      height: 3,
      decoration: BoxDecoration(
        color: context.colorPalette.goldDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: 16,
            color: context.colorPalette.goldDark,
          ),
          const SizedBox(width: 6),
          Text(
            'Filter Products',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colorPalette.goldDeep,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: context.colorPalette.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKaratSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Karat',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: _karatOptions.map((karat) {
            final isSelected = _tempSelectedKarats.contains(karat);
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _toggleKarat(karat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colorPalette.gold
                        : context.colorPalette.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? context.colorPalette.gold
                          : context.colorPalette.border,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    karat,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : context.colorPalette.goldDeep,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    const collapsedCount = 10;
    final allCategories = widget.categories;
    final showExpand = allCategories.length > collapsedCount;
    final visibleCategories =
        _categoriesExpanded || !showExpand
            ? allCategories
            : allCategories.sublist(0, collapsedCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colorPalette.goldDeep,
              ),
            ),
            if (_tempSelectedCategoryIds.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _tempSelectedCategoryIds.clear()),
                child: Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: context.colorPalette.goldDark,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: visibleCategories.map((cat) {
            final isSelected = _tempSelectedCategoryIds.contains(cat.id);
            final cleanedName = cat.name
                .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                .trim();
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _tempSelectedCategoryIds.remove(cat.id);
                  } else {
                    _tempSelectedCategoryIds.add(cat.id);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.colorPalette.gold
                      : context.colorPalette.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? context.colorPalette.gold
                        : context.colorPalette.border,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  cleanedName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : context.colorPalette.goldDeep,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (showExpand) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: context.colorPalette.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.colorPalette.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoriesExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 14,
                    color: context.colorPalette.goldDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _categoriesExpanded
                        ? 'Show less'
                        : 'Show all ${allCategories.length} collections',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.goldDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Status',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            _buildStockOption(
              context,
              label: 'Ready',
              isSelected: _tempStockFilter == 'ready',
              onTap: () => setState(() => _tempStockFilter = 'ready'),
            ),
            const SizedBox(width: 5),
            _buildStockOption(
              context,
              label: 'Out',
              isSelected: _tempStockFilter == 'out',
              onTap: () => setState(() => _tempStockFilter = 'out'),
            ),
            const SizedBox(width: 5),
            _buildStockOption(
              context,
              label: 'All',
              isSelected: _tempStockFilter == 'all',
              onTap: () => setState(() => _tempStockFilter = 'all'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colorPalette.gold
                : context.colorPalette.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? context.colorPalette.gold
                  : context.colorPalette.border,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : context.colorPalette.goldDeep,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightSection(BuildContext context) {
    final sliderMax = _effectiveWeightSliderMax;
    final divisions = sliderMax.round().clamp(1, 10000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weight Range (g)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colorPalette.goldDeep,
              ),
            ),
            Text(
              '${_tempWeightMin.round()}g – ${_tempWeightMax.round()}g',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.colorPalette.goldDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 32,
          child: RangeSlider(
            values: RangeValues(
              _tempWeightMin.clamp(0, sliderMax),
              _tempWeightMax.clamp(0, sliderMax),
            ),
            min: 0,
            max: sliderMax,
            divisions: divisions,
            activeColor: context.colorPalette.gold,
            inactiveColor: context.colorPalette.border,
            labels: RangeLabels(
              '${_tempWeightMin.round()}g',
              '${_tempWeightMax.round()}g',
            ),
            onChanged: (values) {
              setState(() {
                _tempWeightMin = values.start;
                _tempWeightMax = values.end;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final sliderMax =
        widget.priceSliderMax.clamp(_minPriceSliderMax, double.infinity);
    final divisions = (sliderMax / 100000).round().clamp(1, 1000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Price Range (\u20B9)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colorPalette.goldDeep,
              ),
            ),
            Text(
              '${_formatPriceLabel(_tempPriceMin)} \u2013 ${_formatPriceLabel(_tempPriceMax)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.colorPalette.goldDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 32,
          child: RangeSlider(
            values: RangeValues(
              _tempPriceMin.clamp(0, sliderMax),
              _tempPriceMax.clamp(0, sliderMax),
            ),
            min: 0,
            max: sliderMax,
            divisions: divisions,
            activeColor: context.colorPalette.gold,
            inactiveColor: context.colorPalette.border,
            labels: RangeLabels(
              _formatPriceLabel(_tempPriceMin),
              _formatPriceLabel(_tempPriceMax),
            ),
            onChanged: (values) {
              setState(() {
                _tempPriceMin = values.start;
                _tempPriceMax = values.end;
              });
            },
          ),
        ),
      ],
    );
  }

  String _formatPriceLabel(double value) {
    if (value >= 10000000) {
      return '\u20B9${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '\u20B9${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '\u20B9${(value / 1000).toStringAsFixed(1)}K';
    }
    return '\u20B9${value.round()}';
  }

  Widget _buildActions(BuildContext context, int count) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        6,
        10,
        6 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                side: BorderSide(color: context.colorPalette.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.goldDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                backgroundColor: context.colorPalette.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply${count > 0 ? ' ($count)' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

