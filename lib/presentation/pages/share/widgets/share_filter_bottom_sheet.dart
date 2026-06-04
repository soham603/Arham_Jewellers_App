import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/share_controller.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class ShareFilterBottomSheet extends StatefulWidget {
  const ShareFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ShareFilterBottomSheet(),
    );
  }

  @override
  State<ShareFilterBottomSheet> createState() => _ShareFilterBottomSheetState();
}

class _ShareFilterBottomSheetState extends State<ShareFilterBottomSheet> {
  final ShareController _shareController = Get.find<ShareController>();
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
    _tempSelectedKarats = List.from(_shareController.selectedKarats);
    _tempSelectedCategoryIds = List.from(_shareController.selectedCategoryIds);
    _tempSelectedCategoryNames = List.from(_shareController.selectedCategoryNames);
    _tempShowAll = _shareController.showAllStock;
    _tempWeightMin = _shareController.weightMin;
    _tempWeightMax = _shareController.weightMax;
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
    _shareController.applyFilters(
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
              padding: const EdgeInsets.all(20),
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
        SizedBox(height: context.getScreenHeight(1)),
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
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        SizedBox(height: context.getScreenHeight(1)),
        GestureDetector(
          onTap: () => _showCategoryPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: context.colorPalette.goldDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tempSelectedCategoryNames.isEmpty
                        ? 'All Categories'
                        : _tempSelectedCategoryNames.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _tempSelectedCategoryNames.isEmpty
                          ? context.colorPalette.goldDark
                          : context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                if (_tempSelectedCategoryIds.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _tempSelectedCategoryIds.clear();
                        _tempSelectedCategoryNames.clear();
                      });
                    },
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: context.colorPalette.goldDark,
                    ),
                  )
                else
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: context.colorPalette.goldDark,
                  ),
              ],
            ),
          ),
        ),
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.colorPalette.goldDeep,
          ),
        ),
        SizedBox(height: context.getScreenHeight(1)),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
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
              '${_tempWeightMin.round()}g – ${_tempWeightMax.round()}g',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.colorPalette.goldDark,
              ),
            ),
          ],
        ),
        SizedBox(height: context.getScreenHeight(1)),
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
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
