import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
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
});

class FilterBottomSheet extends StatefulWidget {
  final List<String> initialSelectedKarats;
  final List<String> initialSelectedCategoryIds;
  final List<String> initialSelectedCategoryNames;
  final String initialStockFilter;
  final double initialWeightMin;
  final double initialWeightMax;
  final FilterApplyCallback onApply;
  final bool showKaratFilter;
  final bool showCategoryFilter;
  final bool showStockFilter;
  final bool showWeightFilter;
  final bool showPriceFilter;
  final double initialPriceMin;
  final double initialPriceMax;
  final double priceSliderMax;
  final double weightSliderMax;

  const FilterBottomSheet({
    super.key,
    required this.initialSelectedKarats,
    required this.initialSelectedCategoryIds,
    required this.initialSelectedCategoryNames,
    required this.initialStockFilter,
    required this.initialWeightMin,
    required this.initialWeightMax,
    required this.onApply,
    this.showKaratFilter = true,
    this.showCategoryFilter = true,
    this.showStockFilter = true,
    this.showWeightFilter = true,
    this.showPriceFilter = false,
    this.initialPriceMin = 0,
    this.initialPriceMax = 5000000,
    this.priceSliderMax = 5000000,
    this.weightSliderMax = 100,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> initialSelectedKarats,
    required List<String> initialSelectedCategoryIds,
    required List<String> initialSelectedCategoryNames,
    required String initialStockFilter,
    required double initialWeightMin,
    required double initialWeightMax,
    required FilterApplyCallback onApply,
    bool showKaratFilter = true,
    bool showCategoryFilter = true,
    bool showStockFilter = true,
    bool showWeightFilter = true,
    bool showPriceFilter = false,
    double initialPriceMin = 0,
    double initialPriceMax = 5000000,
    double priceSliderMax = 5000000,
    double weightSliderMax = 100,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        initialSelectedKarats: initialSelectedKarats,
        initialSelectedCategoryIds: initialSelectedCategoryIds,
        initialSelectedCategoryNames: initialSelectedCategoryNames,
        initialStockFilter: initialStockFilter,
        initialWeightMin: initialWeightMin,
        initialWeightMax: initialWeightMax,
        onApply: onApply,
        showKaratFilter: showKaratFilter,
        showCategoryFilter: showCategoryFilter,
        showStockFilter: showStockFilter,
        showWeightFilter: showWeightFilter,
        showPriceFilter: showPriceFilter,
        initialPriceMin: initialPriceMin,
        initialPriceMax: initialPriceMax,
        priceSliderMax: priceSliderMax,
        weightSliderMax: weightSliderMax,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final CategoryController _categoryController =
      Get.isRegistered<CategoryController>()
          ? Get.find<CategoryController>()
          : Get.put(CategoryController());

  final List<String> _karatOptions = ['18K', '20K', '22K'];
  late List<String> _tempSelectedKarats;
  late List<String> _tempSelectedCategoryIds;
  late List<String> _tempSelectedCategoryNames;
  late String _tempStockFilter;
  late double _tempWeightMin;
  late double _tempWeightMax;
  late double _tempPriceMin;
  late double _tempPriceMax;
  late TextEditingController _weightMaxController;
  double _editableWeightMax = 100;
  List<CategoryModel> _allCategories = [];
  Map<String, List<CategoryModel>> _categoryVariants = {};

  @override
  void initState() {
    super.initState();
    _tempSelectedKarats = List.from(widget.initialSelectedKarats);
    _tempSelectedCategoryIds = List.from(widget.initialSelectedCategoryIds);
    _tempSelectedCategoryNames = List.from(widget.initialSelectedCategoryNames);
    _tempStockFilter = widget.initialStockFilter;
    _tempWeightMin = widget.initialWeightMin.clamp(0.0, widget.weightSliderMax);
    _tempWeightMax = widget.initialWeightMax.clamp(0.0, widget.weightSliderMax);
    _tempPriceMin = widget.initialPriceMin.clamp(0.0, widget.priceSliderMax);
    _tempPriceMax = widget.initialPriceMax.clamp(0.0, widget.priceSliderMax);
    if (_tempWeightMin > _tempWeightMax) _tempWeightMax = widget.weightSliderMax;
    if (_tempPriceMin > _tempPriceMax) _tempPriceMax = widget.priceSliderMax;
    _editableWeightMax = widget.weightSliderMax;
    _weightMaxController = TextEditingController(text: _editableWeightMax.round().toString());
    _loadCategories();
  }

  @override
  void dispose() {
    _weightMaxController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (_categoryController.k18Categories.isEmpty &&
        _categoryController.k20Categories.isEmpty &&
        _categoryController.k22Categories.isEmpty) {
      await _categoryController.fetchAllKaratCategories();
    }
    setState(() {
      final all = [
        ..._categoryController.k18Categories,
        ..._categoryController.k20Categories,
        ..._categoryController.k22Categories,
      ];
      _categoryVariants = {};
      for (final cat in all) {
        final key = cat.name.toLowerCase();
        _categoryVariants.putIfAbsent(key, () => []).add(cat);
      }
      _allCategories = _categoryVariants.values
          .map((variants) => variants.first)
          .toList();
    });
  }

  void _toggleKarat(String karat) {
    setState(() {
      if (_tempSelectedKarats.contains(karat)) {
        _tempSelectedKarats.remove(karat);
      } else {
        _tempSelectedKarats.add(karat);
      }
    });
  }

  void _clearAll() {
    setState(() {
      if (widget.showKaratFilter) _tempSelectedKarats.clear();
      if (widget.showCategoryFilter) {
        _tempSelectedCategoryIds.clear();
        _tempSelectedCategoryNames.clear();
      }
      if (widget.showStockFilter) _tempStockFilter = 'ready';
      if (widget.showWeightFilter) {
        _tempWeightMin = 0;
        _tempWeightMax = _editableWeightMax;
      }
      if (widget.showPriceFilter) {
        _tempPriceMin = 0;
        _tempPriceMax = widget.priceSliderMax;
      }
    });
  }

  void _apply() {
    widget.onApply(
      karats: _tempSelectedKarats,
      categoryIds: _tempSelectedCategoryIds,
      categoryNames: _tempSelectedCategoryNames,
      stockFilter: _tempStockFilter,
      wMin: _tempWeightMin,
      wMax: _tempWeightMax,
      pMin: _tempPriceMin,
      pMax: _tempPriceMax,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        (widget.showKaratFilter ? _tempSelectedKarats.length : 0) +
        (widget.showCategoryFilter && _tempSelectedCategoryIds.isNotEmpty ? 1 : 0) +
        (widget.showStockFilter && _tempStockFilter != 'ready' ? 1 : 0) +
        (widget.showWeightFilter && (_tempWeightMin > 0 || _tempWeightMax < widget.weightSliderMax) ? 1 : 0) +
        (widget.showPriceFilter && (_tempPriceMin > 0 || _tempPriceMax < widget.priceSliderMax) ? 1 : 0);

    return Container(
      height: context.isTablet
          ? MediaQuery.of(context).size.height * 0.55
          : MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.colorPalette.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.responsiveWidth(20, tabletVal: 24))),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(context, selectedCount),
          Divider(height: 1, color: context.colorPalette.border),
          Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.responsiveWidth(16, tabletVal: 20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showKaratFilter) ...[
                      _buildKaratSection(context),
                      SizedBox(height: context.getScreenHeight(2.5)),
                    ],
                    if (widget.showCategoryFilter) ...[
                      _buildCategorySection(context),
                      SizedBox(height: context.getScreenHeight(2.5)),
                    ],
                    if (widget.showStockFilter) ...[
                      _buildStockSection(context),
                      SizedBox(height: context.getScreenHeight(2.5)),
                    ],
                    if (widget.showWeightFilter) ...[
                      _buildWeightSection(context),
                      SizedBox(height: context.getScreenHeight(2.5)),
                    ],
                    if (widget.showPriceFilter) _buildPriceSection(context),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: context.colorPalette.border),
          _buildActions(context, selectedCount),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    final handleWidth = context.responsiveWidth(40, tabletVal: 48);
    final handleHeight = context.responsiveWidth(4, tabletVal: 5);
    return Container(
      margin: EdgeInsets.only(top: context.responsiveWidth(10, tabletVal: 12)),
      width: handleWidth,
      height: handleHeight,
      decoration: BoxDecoration(
        color: context.colorPalette.goldDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(handleHeight * 0.5),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    final hPad = context.responsiveWidth(20, tabletVal: 24);
    final vPad = context.responsiveWidth(12, tabletVal: 14);
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: context.responsiveWidth(20, tabletVal: 24),
            color: context.colorPalette.goldDark,
          ),
          SizedBox(width: context.responsiveWidth(8, tabletVal: 10)),
          Text(
            'Filter Products',
            style: TextStyle(
              fontSize: context.responsiveWidth(18, tabletVal: 22),
              fontWeight: FontWeight.w700,
              color: context.colorPalette.goldDeep,
            ),
          ),
          if (count > 0) ...[
            SizedBox(width: context.responsiveWidth(8, tabletVal: 10)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveWidth(8, tabletVal: 10),
                vertical: context.responsiveWidth(2, tabletVal: 3),
              ),
              decoration: BoxDecoration(
                color: context.colorPalette.gold,
                borderRadius: BorderRadius.circular(context.responsiveWidth(10, tabletVal: 12)),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: context.responsiveWidth(12, tabletVal: 14),
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
        ),
          SizedBox(height: context.getScreenHeight(0.5)),
        Row(
          children: _karatOptions.map((karat) {
            final isSelected = _tempSelectedKarats.contains(karat);
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => _toggleKarat(karat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colorPalette.gold
                        : context.colorPalette.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? context.colorPalette.gold
                          : context.colorPalette.border,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    karat,
                    style: TextStyle(
                      fontSize: 14,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
        ),
        SizedBox(height: context.getScreenHeight(0.5)),
        GestureDetector(
          onTap: () => _showCategoryPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.colorPalette.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.colorPalette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: context.colorPalette.goldDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tempSelectedCategoryNames.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'All Categories',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.colorPalette.goldDark,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ..._buildCategoryDisplayItems(context),
                            GestureDetector(
                              onTap: () => _showCategoryPicker(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colorPalette.gold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 4),
                if (_tempSelectedCategoryIds.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _tempSelectedCategoryIds.clear();
                        _tempSelectedCategoryNames.clear();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: context.colorPalette.goldDark,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: context.colorPalette.goldDark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryDisplayItems(BuildContext context) {
    final items = <Widget>[];

    for (final cat in _allCategories) {
      final variants = _categoryVariants[cat.name.toLowerCase()] ?? [cat];
      final allChildren = <CategoryModel>[];
      for (final variant in variants) {
        final children = _categoryController.level3Cache[variant.id] ?? [];
        allChildren.addAll(children);
      }
      if (allChildren.isEmpty) continue;

      final allSelected = allChildren.every((child) {
        final cleanedName = child.name
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim();
        return _tempSelectedCategoryIds.contains(child.id) ||
            _tempSelectedCategoryNames.contains(cleanedName);
      });

      if (allSelected) {
        final cleanedName = cat.name
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim();
        items.add(_buildCategoryChip(
          context,
          name: cleanedName,
          onRemove: () {
            setState(() {
              for (final child in allChildren) {
                final ci = _tempSelectedCategoryIds.indexOf(child.id);
                if (ci != -1) {
                  _tempSelectedCategoryIds.removeAt(ci);
                  final childCleaned = child.name
                      .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                      .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                      .trim();
                  _tempSelectedCategoryNames.removeWhere((n) => n == childCleaned);
                }
              }
            });
          },
        ));
      }
    }

    final accountedIds = <String>{};
    for (final cat in _allCategories) {
      final variants = _categoryVariants[cat.name.toLowerCase()] ?? [cat];
      for (final variant in variants) {
        final children = _categoryController.level3Cache[variant.id] ?? [];
        for (final child in children) {
          accountedIds.add(child.id);
        }
      }
    }

    for (var i = 0; i < _tempSelectedCategoryIds.length; i++) {
      final id = _tempSelectedCategoryIds[i];
      if (!accountedIds.contains(id)) {
        final name = _tempSelectedCategoryNames[i];
        items.add(_buildCategoryChip(
          context,
          name: name,
          onRemove: () {
            setState(() {
              final idx = _tempSelectedCategoryIds.indexOf(id);
              if (idx != -1) {
                _tempSelectedCategoryIds.removeAt(idx);
                _tempSelectedCategoryNames.removeAt(idx);
              }
            });
          },
        ));
      }
    }

    return items;
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String name,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.colorPalette.gold,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStockSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Status',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
        ),
        SizedBox(height: context.getScreenHeight(0.5)),
        Row(
          children: [
            _buildStockOption(
              context,
              label: 'Ready Stock',
              isSelected: _tempStockFilter == 'ready',
              onTap: () => setState(() => _tempStockFilter = 'ready'),
            ),
            const SizedBox(width: 8),
            _buildStockOption(
              context,
              label: 'Out of Stock',
              isSelected: _tempStockFilter == 'out',
              onTap: () => setState(() => _tempStockFilter = 'out'),
            ),
            const SizedBox(width: 8),
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
          padding: const EdgeInsets.symmetric(vertical: 6),
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
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weight Range (g)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colorPalette.goldDeep,
              ),
            ),
            Row(
              children: [
                Text(
                  '${_tempWeightMin.round()}g \u2013 ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.colorPalette.goldDark,
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 28,
                  child: TextField(
                    controller: _weightMaxController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colorPalette.goldDeep,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: context.colorPalette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: context.colorPalette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: context.colorPalette.gold, width: 1.5),
                      ),
                    ),
                    onSubmitted: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _editableWeightMax = parsed;
                          if (_tempWeightMax > _editableWeightMax) {
                            _tempWeightMax = _editableWeightMax;
                          }
                          if (_tempWeightMin > _tempWeightMax) {
                            _tempWeightMin = 0;
                          }
                        });
                      } else {
                        _weightMaxController.text = _editableWeightMax.round().toString();
                      }
                    },
                  ),
                ),
                Text(
                  'g',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.colorPalette.goldDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: context.getScreenHeight(0.5)),
        RangeSlider(
          values: RangeValues(_tempWeightMin, _tempWeightMax),
          min: 0,
          max: _editableWeightMax,
          divisions: _editableWeightMax.round(),
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
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Price Range (\u20B9)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colorPalette.goldDeep,
              ),
            ),
            Text(
              '${_formatPriceLabel(_tempPriceMin)} \u2013 ${_formatPriceLabel(_tempPriceMax)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colorPalette.goldDark,
              ),
            ),
          ],
        ),
        SizedBox(height: context.getScreenHeight(0.5)),
        RangeSlider(
          values: RangeValues(_tempPriceMin, _tempPriceMax),
          min: 0,
          max: widget.priceSliderMax,
          divisions: 50,
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

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        categories: _allCategories,
        categoryVariants: _categoryVariants,
        level3Cache: _categoryController.level3Cache,
        selectedIds: _tempSelectedCategoryIds,
        selectedNames: _tempSelectedCategoryNames,
        onToggle: (cat) {
          setState(() {
            final idx = _tempSelectedCategoryIds.indexOf(cat.id);
            if (idx != -1) {
              _tempSelectedCategoryIds.removeAt(idx);
              final cleanedName = cat.name
                  .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                  .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                  .trim();
              _tempSelectedCategoryNames.removeWhere((n) => n == cleanedName);
            } else {
              _tempSelectedCategoryIds.add(cat.id);
              final cleanedName = cat.name
                  .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                  .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                  .trim();
              _tempSelectedCategoryNames.add(cleanedName);
            }
          });
        },
        onClear: () {
          setState(() {
            _tempSelectedCategoryIds.clear();
            _tempSelectedCategoryNames.clear();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildActions(BuildContext context, int count) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: context.colorPalette.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colorPalette.goldDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                backgroundColor: context.colorPalette.gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply${count > 0 ? ' ($count)' : ''}',
                style: const TextStyle(
                  fontSize: 15,
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

class _CategoryPickerSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final Map<String, List<CategoryModel>> categoryVariants;
  final Map<String, List<CategoryModel>> level3Cache;
  final List<String> selectedIds;
  final List<String> selectedNames;
  final ValueChanged<CategoryModel> onToggle;
  final VoidCallback onClear;

  const _CategoryPickerSheet({
    required this.categories,
    required this.categoryVariants,
    required this.level3Cache,
    required this.selectedIds,
    required this.selectedNames,
    required this.onToggle,
    required this.onClear,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late List<String> _localIds;
  late List<String> _localNames;

  @override
  void initState() {
    super.initState();
    _localIds = List.from(widget.selectedIds);
    _localNames = List.from(widget.selectedNames);
  }

  List<CategoryModel> _mergedLevel3(CategoryModel cat) {
    final variants = widget.categoryVariants[cat.name.toLowerCase()] ?? [cat];
    final seen = <String>{};
    final merged = <CategoryModel>[];
    for (final variant in variants) {
      final children = widget.level3Cache[variant.id] ?? [];
      for (final child in children) {
        if (seen.add(child.id)) {
          merged.add(child);
        }
      }
    }
    return merged;
  }

  List<CategoryModel> _allVariantLevel3(CategoryModel cat) {
    final variants = widget.categoryVariants[cat.name.toLowerCase()] ?? [cat];
    final result = <CategoryModel>[];
    for (final variant in variants) {
      result.addAll(widget.level3Cache[variant.id] ?? []);
    }
    return result;
  }

  String _cleanName(String name) {
    return name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'collection', caseSensitive: false), '')
        .trim();
  }

  bool _isSubSelected(CategoryModel sub) {
    final cleanedName = _cleanName(sub.name);
    return _localIds.contains(sub.id) || _localNames.contains(cleanedName);
  }

  void _toggle(CategoryModel cat) {
    final cleanedName = _cleanName(cat.name);
    setState(() {
      final idx = _localIds.indexOf(cat.id);
      if (idx != -1) {
        _localIds.removeAt(idx);
        _localNames.removeWhere((n) => n == cleanedName);
      } else {
        _localIds.add(cat.id);
        _localNames.add(cleanedName);
      }
    });
    widget.onToggle(cat);
  }

  void _toggleAllForParent(CategoryModel parent) {
    final allChildren = _allVariantLevel3(parent);
    final allSelected = allChildren.every((sub) => _isSubSelected(sub));
    setState(() {
      for (final sub in allChildren) {
        final subCleaned = _cleanName(sub.name);
        if (allSelected) {
          final idx = _localIds.indexOf(sub.id);
          if (idx != -1) {
            _localIds.removeAt(idx);
            _localNames.removeWhere((n) => n == subCleaned);
          }
        } else {
          if (!_localIds.contains(sub.id) && !_localNames.contains(subCleaned)) {
            _localIds.add(sub.id);
            _localNames.add(subCleaned);
          }
        }
      }
    });
    for (final sub in allChildren) {
      widget.onToggle(sub);
    }
  }

  Widget _selectedCountBadge(
    BuildContext context, {
    required int selected,
    required int total,
  }) {
    if (selected == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: context.colorPalette.gold,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$selected',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.isTablet
          ? MediaQuery.of(context).size.height * 0.5
          : MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: context.colorPalette.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.responsiveWidth(20, tabletVal: 24))),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: context.responsiveWidth(10, tabletVal: 12)),
            width: context.responsiveWidth(40, tabletVal: 48),
            height: context.responsiveWidth(4, tabletVal: 5),
            decoration: BoxDecoration(
              color: context.colorPalette.goldDark.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
      padding: EdgeInsets.fromLTRB(
        context.responsiveWidth(16, tabletVal: 20),
        context.responsiveWidth(10, tabletVal: 12),
        context.responsiveWidth(16, tabletVal: 20),
        context.responsiveWidth(10, tabletVal: 12),
      ),
      child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: context.responsiveWidth(20, tabletVal: 24),
                  color: context.colorPalette.goldDark,
                ),
                SizedBox(width: context.responsiveWidth(8, tabletVal: 10)),
                Expanded(
                  child: Text(
                    'Select Categories',
                    style: TextStyle(
                      fontSize: context.responsiveWidth(18, tabletVal: 22),
                      fontWeight: FontWeight.w700,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                if (_localIds.isNotEmpty)
                  TextButton(
                    onPressed: widget.onClear,
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: context.responsiveWidth(14, tabletVal: 16),
                        color: context.colorPalette.goldDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colorPalette.border),
          Expanded(
            child: widget.categories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: context.responsiveWidth(48, tabletVal: 56),
                          color: context.colorPalette.goldDark,
                        ),
                        SizedBox(height: context.responsiveWidth(12, tabletVal: 14)),
                        Text(
                          'No categories found',
                          style: TextStyle(
                            fontSize: context.responsiveWidth(14, tabletVal: 16),
                            color: context.colorPalette.goldDark,
                          ),
                        ),
                      ],
                    ),
                  )
                : Obx(() {
                    final categoryController = Get.isRegistered<CategoryController>()
                        ? Get.find<CategoryController>()
                        : Get.put(CategoryController());
                    final expandedId = categoryController.expandedCategoryId;
                    return ListView.builder(
                      padding: EdgeInsets.all(context.responsiveWidth(16, tabletVal: 20)),
                      itemCount: widget.categories.length,
                      itemBuilder: (_, index) {
                        final cat = widget.categories[index];
                        final isExpanded = expandedId == cat.id;
                        final level3 = _mergedLevel3(cat);
                        final isLoading = categoryController.isLevel3Loading(cat.id);

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  categoryController.toggleExpand(cat),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colorPalette.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isExpanded
                                        ? context.colorPalette.gold
                                        : context.colorPalette.border,
                                    width: isExpanded ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    if (cat.imageUrl.isNotEmpty) ...[
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(context.responsiveWidth(8, tabletVal: 10)),
                                        child: Image.network(
                                          cat.imageUrl,
                                          width: context.responsiveWidth(36, tabletVal: 44),
                                          height: context.responsiveWidth(36, tabletVal: 44),
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (ctx, err, stack) =>
                                                  Container(
                                            width: context.responsiveWidth(36, tabletVal: 44),
                                            height: context.responsiveWidth(36, tabletVal: 44),
                                            decoration: BoxDecoration(
                                              color: context
                                                  .colorPalette.goldLight,
                                              borderRadius:
                                                  BorderRadius.circular(context.responsiveWidth(8, tabletVal: 10)),
                                            ),
                                            child: Icon(
                                              Icons.diamond_outlined,
                                              color: context
                                                  .colorPalette.goldDark,
                                              size: context.responsiveWidth(18, tabletVal: 22),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: context.responsiveWidth(12, tabletVal: 14)),
                                    ],
                                    Expanded(
                                      child: Text(
                                        cat.name
                                            .replaceAll(
                                                RegExp(r'[^a-zA-Z\s]'),
                                                '')
                                            .replaceAll(
                                              RegExp(r'collection',
                                                  caseSensitive: false),
                                              '',
                                            )
                                            .trim(),
                                        style: TextStyle(
                                          fontSize: context.responsiveWidth(14, tabletVal: 16),
                                          fontWeight: FontWeight.w600,
                                          color: context
                                              .colorPalette.goldDeep,
                                        ),
                                      ),
                                    ),
                                    if (level3.isNotEmpty)
                                      _selectedCountBadge(
                                        context,
                                        selected: level3
                                            .where((sub) =>
                                                _isSubSelected(sub))
                                            .length,
                                        total: level3.length,
                                      ),
                                    if (isLoading)
                                      SizedBox(
                                        width: context.responsiveWidth(18, tabletVal: 22),
                                        height: context.responsiveWidth(18, tabletVal: 22),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color:
                                              context.colorPalette.gold,
                                        ),
                                      )
                                    else
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0,
                                        duration: const Duration(
                                            milliseconds: 200),
                                        child: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: context
                                              .colorPalette.goldDark,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded && level3.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () => _toggleAllForParent(cat),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      left: context.responsiveWidth(24, tabletVal: 28),
                                      top: context.responsiveWidth(4, tabletVal: 5),
                                      bottom: context.responsiveWidth(4, tabletVal: 5)),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsiveWidth(12, tabletVal: 14),
                                    vertical: context.responsiveWidth(6, tabletVal: 8),
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colorPalette.cardBg,
                                    borderRadius: BorderRadius.circular(context.responsiveWidth(10, tabletVal: 12)),
                                    border: Border.all(
                                      color: context.colorPalette.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'All',
                                          style: TextStyle(
                                            fontSize: context.responsiveWidth(12, tabletVal: 14),
                                            fontWeight: FontWeight.w700,
                                            color: context
                                                .colorPalette.goldDeep,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.select_all_rounded,
                                        size: context.responsiveWidth(16, tabletVal: 20),
                                        color:
                                            context.colorPalette.goldDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ...level3.map((sub) {
                                final isSubSelected =
                                    _isSubSelected(sub);
                                final cleanedName = _cleanName(sub.name);
                                return GestureDetector(
                                  onTap: () => _toggle(sub),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                        left: context.responsiveWidth(24, tabletVal: 28),
                                        top: context.responsiveWidth(4, tabletVal: 5),
                                        bottom: context.responsiveWidth(4, tabletVal: 5)),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.responsiveWidth(14, tabletVal: 18),
                                      vertical: context.responsiveWidth(10, tabletVal: 12),
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSubSelected
                                          ? context.colorPalette.goldLight
                                          : context
                                              .colorPalette.backgroundColor,
                                      borderRadius:
                                          BorderRadius.circular(context.responsiveWidth(10, tabletVal: 12)),
                                      border: Border.all(
                                        color: isSubSelected
                                            ? context.colorPalette.gold
                                            : context
                                                .colorPalette.border,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cleanedName,
                                            style: TextStyle(
                                              fontSize: context.responsiveWidth(13, tabletVal: 15),
                                              fontWeight: isSubSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSubSelected
                                                  ? context.colorPalette
                                                      .goldDeep
                                                  : context.colorPalette
                                                      .textColor,
                                            ),
                                          ),
                                        ),
                                        if (isSubSelected)
                                          Container(
                                            width: context.responsiveWidth(20, tabletVal: 24),
                                            height: context.responsiveWidth(20, tabletVal: 24),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: context
                                                  .colorPalette.gold,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              size: context.responsiveWidth(12, tabletVal: 14),
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
                        );
                      },
                    );
                  }),
          ),
        ],
      ),
    );
  }
}
