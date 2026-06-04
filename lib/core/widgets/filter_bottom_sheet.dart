import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

typedef FilterApplyCallback = void Function({
  required List<String> karats,
  required List<String> categoryIds,
  required List<String> categoryNames,
  required bool showAll,
  required double wMin,
  required double wMax,
});

class FilterBottomSheet extends StatefulWidget {
  final List<String> initialSelectedKarats;
  final List<String> initialSelectedCategoryIds;
  final List<String> initialSelectedCategoryNames;
  final bool initialShowAllStock;
  final double initialWeightMin;
  final double initialWeightMax;
  final FilterApplyCallback onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialSelectedKarats,
    required this.initialSelectedCategoryIds,
    required this.initialSelectedCategoryNames,
    required this.initialShowAllStock,
    required this.initialWeightMin,
    required this.initialWeightMax,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> initialSelectedKarats,
    required List<String> initialSelectedCategoryIds,
    required List<String> initialSelectedCategoryNames,
    required bool initialShowAllStock,
    required double initialWeightMin,
    required double initialWeightMax,
    required FilterApplyCallback onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        initialSelectedKarats: initialSelectedKarats,
        initialSelectedCategoryIds: initialSelectedCategoryIds,
        initialSelectedCategoryNames: initialSelectedCategoryNames,
        initialShowAllStock: initialShowAllStock,
        initialWeightMin: initialWeightMin,
        initialWeightMax: initialWeightMax,
        onApply: onApply,
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
  late bool _tempShowAll;
  late double _tempWeightMin;
  late double _tempWeightMax;
  List<CategoryModel> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedKarats = List.from(widget.initialSelectedKarats);
    _tempSelectedCategoryIds = List.from(widget.initialSelectedCategoryIds);
    _tempSelectedCategoryNames = List.from(widget.initialSelectedCategoryNames);
    _tempShowAll = widget.initialShowAllStock;
    _tempWeightMin = widget.initialWeightMin;
    _tempWeightMax = widget.initialWeightMax;
    _loadCategories();
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
      final seen = <String>{};
      _allCategories = [];
      for (final cat in all) {
        if (seen.add(cat.name.toLowerCase())) {
          _allCategories.add(cat);
        }
      }
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
      _tempSelectedKarats.clear();
      _tempSelectedCategoryIds.clear();
      _tempSelectedCategoryNames.clear();
      _tempShowAll = false;
      _tempWeightMin = 0;
      _tempWeightMax = 500;
    });
  }

  void _apply() {
    widget.onApply(
      karats: _tempSelectedKarats,
      categoryIds: _tempSelectedCategoryIds,
      categoryNames: _tempSelectedCategoryNames,
      showAll: _tempShowAll,
      wMin: _tempWeightMin,
      wMax: _tempWeightMax,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _tempSelectedKarats.length +
        (_tempSelectedCategoryIds.isNotEmpty ? 1 : 0) +
        (_tempShowAll ? 1 : 0) +
        (_tempWeightMin > 0 || _tempWeightMax < 500 ? 1 : 0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.colorPalette.cream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(context, selectedCount),
          Divider(height: 1, color: context.colorPalette.border),
          Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKaratSection(context),
                    SizedBox(height: context.getScreenHeight(2.5)),
                    _buildCategorySection(context),
                    SizedBox(height: context.getScreenHeight(2.5)),
                    _buildStockSection(context),
                    SizedBox(height: context.getScreenHeight(2.5)),
                    _buildWeightSection(context),
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
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.colorPalette.goldDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: 20,
            color: context.colorPalette.goldDark,
          ),
          const SizedBox(width: 8),
          Text(
            'Filter Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.colorPalette.goldDeep,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: context.colorPalette.gold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
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
                      width: isSelected ? 2 : 1,
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
    final level3Cache = _categoryController.level3Cache;
    final groupedParents = <String>{};
    final accountedChildren = <String>{};

    for (final entry in level3Cache.entries) {
      final children = entry.value;
      if (children.isNotEmpty &&
          children.every((child) => _tempSelectedCategoryIds.contains(child.id))) {
        groupedParents.add(entry.key);
        for (final child in children) {
          accountedChildren.add(child.id);
        }
      }
    }

    final items = <Widget>[];

    for (final parentId in groupedParents) {
      final parent = _allCategories.where((c) => c.id == parentId).firstOrNull;
      if (parent != null) {
        final cleanedName = parent.name
            .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
            .replaceAll(RegExp(r'collection', caseSensitive: false), '')
            .trim();
        items.add(_buildCategoryChip(
          context,
          name: cleanedName,
          onRemove: () {
            setState(() {
              final children = level3Cache[parentId] ?? [];
              for (final child in children) {
                final ci = _tempSelectedCategoryIds.indexOf(child.id);
                if (ci != -1) {
                  _tempSelectedCategoryIds.removeAt(ci);
                  _tempSelectedCategoryNames.removeAt(ci);
                }
              }
            });
          },
        ));
      }
    }

    for (var i = 0; i < _tempSelectedCategoryIds.length; i++) {
      final id = _tempSelectedCategoryIds[i];
      if (!accountedChildren.contains(id)) {
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
              label: 'Active Only',
              isSelected: !_tempShowAll,
              onTap: () => setState(() => _tempShowAll = false),
            ),
            const SizedBox(width: 10),
            _buildStockOption(
              context,
              label: 'Show All',
              isSelected: _tempShowAll,
              onTap: () => setState(() => _tempShowAll = true),
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colorPalette.gold
                : context.colorPalette.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? context.colorPalette.gold
                  : context.colorPalette.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
            Text(
              '${_tempWeightMin.round()}g \u2013 ${_tempWeightMax.round()}g',
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
          values: RangeValues(_tempWeightMin, _tempWeightMax),
          min: 0,
          max: 500,
          divisions: 50,
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

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        categories: _allCategories,
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
  final List<String> selectedIds;
  final List<String> selectedNames;
  final ValueChanged<CategoryModel> onToggle;
  final VoidCallback onClear;

  const _CategoryPickerSheet({
    required this.categories,
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

  bool _isSubSelected(CategoryModel sub) {
    final cleanedName = sub.name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'collection', caseSensitive: false), '')
        .trim();
    return _localIds.contains(sub.id) || _localNames.contains(cleanedName);
  }

  void _toggle(CategoryModel cat) {
    final cleanedName = cat.name
        .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
        .replaceAll(RegExp(r'collection', caseSensitive: false), '')
        .trim();
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
    final categoryController = Get.isRegistered<CategoryController>()
        ? Get.find<CategoryController>()
        : Get.put(CategoryController());

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: context.colorPalette.goldDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Categories',
                    style: TextStyle(
                      fontSize: 18,
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
                        fontSize: 14,
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
                          size: 48,
                          color: context.colorPalette.goldDark,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No categories found',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.colorPalette.goldDark,
                          ),
                        ),
                      ],
                    ),
                  )
                : Obx(() {
                    final expandedId = categoryController.expandedCategoryId;
                    final level3Cache = categoryController.level3Cache;
                    final loadingIds = <String>{};
                    for (final cat in widget.categories) {
                      if (categoryController.isLevel3Loading(cat.id)) {
                        loadingIds.add(cat.id);
                      }
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.categories.length,
                      itemBuilder: (_, index) {
                        final cat = widget.categories[index];
                        final isExpanded = expandedId == cat.id;
                        final level3 = level3Cache[cat.id];
                        final isLoading = loadingIds.contains(cat.id);

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
                                            BorderRadius.circular(8),
                                        child: Image.network(
                                          cat.imageUrl,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (ctx, err, stack) =>
                                                  Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: context
                                                  .colorPalette.goldLight,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.diamond_outlined,
                                              color: context
                                                  .colorPalette.goldDark,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: context
                                              .colorPalette.goldDeep,
                                        ),
                                      ),
                                    ),
                                    if (level3 != null)
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
                                        width: 18,
                                        height: 18,
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
                            if (isExpanded && level3 != null) ...[
                              GestureDetector(
                                onTap: () {
                                  for (final sub in level3) {
                                    if (!_isSubSelected(sub)) {
                                      _toggle(sub);
                                    }
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(
                                      left: 24, top: 4, bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colorPalette.cardBg,
                                    borderRadius: BorderRadius.circular(10),
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
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: context
                                                .colorPalette.goldDeep,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.select_all_rounded,
                                        size: 18,
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
                                final cleanedName = sub.name
                                    .replaceAll(
                                        RegExp(r'[^a-zA-Z\s]'), '')
                                    .replaceAll(
                                      RegExp(r'collection',
                                          caseSensitive: false),
                                      '',
                                    )
                                    .trim();
                                return GestureDetector(
                                  onTap: () => _toggle(sub),
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        left: 24, top: 4, bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSubSelected
                                          ? context.colorPalette.goldLight
                                          : context
                                              .colorPalette.backgroundColor,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSubSelected
                                            ? context.colorPalette.gold
                                            : context
                                                .colorPalette.border,
                                        width: isSubSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cleanedName,
                                            style: TextStyle(
                                              fontSize: 13,
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
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: context
                                                  .colorPalette.gold,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              size: 12,
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
