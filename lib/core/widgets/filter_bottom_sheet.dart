import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/presentation/controllers/searchProductController.dart';
import 'package:ratnesh_gold_app/utils/ContextExtensions.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final SearchProductController _searchController =
      Get.find<SearchProductController>();
  final CategoryController _categoryController =
      Get.isRegistered<CategoryController>()
          ? Get.find<CategoryController>()
          : Get.put(CategoryController());

  final List<String> _karatOptions = ['18K', '20K', '22K'];
  String? _tempSelectedKarat;
  String? _tempSelectedCategoryId;
  String _tempSelectedCategoryName = '';
  List<CategoryModel> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedKarat = _searchController.selectedKarats.isNotEmpty
        ? _searchController.selectedKarats.first
        : null;
    _tempSelectedCategoryId = _searchController.selectedCategoryId;
    _tempSelectedCategoryName = _searchController.selectedCategoryName;
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
      _tempSelectedKarat =
          _tempSelectedKarat == karat ? null : karat;
    });
  }

  void _clearAll() {
    setState(() {
      _tempSelectedKarat = null;
      _tempSelectedCategoryId = null;
      _tempSelectedCategoryName = '';
    });
  }

  void _apply() {
    _searchController.clearAllFilters();
    if (_tempSelectedKarat != null) {
      _searchController.toggleKaratFilter(_tempSelectedKarat!);
    }
    _searchController.setCategoryFilter(
      _tempSelectedCategoryId,
      _tempSelectedCategoryName,
    );
    _searchController.loadFilteredProducts();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = (_tempSelectedKarat != null ? 1 : 0) +
        (_tempSelectedCategoryId != null ? 1 : 0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
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
                  SizedBox(height: context.getScreenHeight(3)),
                  _buildCategorySection(context),
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
            final isSelected = _tempSelectedKarat == karat;
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        karat,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : context.colorPalette.goldDeep,
                        ),
                      ),
                    ],
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
                    _tempSelectedCategoryName.isEmpty
                        ? 'All Categories'
                        : _tempSelectedCategoryName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _tempSelectedCategoryName.isEmpty
                          ? context.colorPalette.goldDark
                          : context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                if (_tempSelectedCategoryId != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _tempSelectedCategoryId = null;
                        _tempSelectedCategoryName = '';
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

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        categories: _allCategories,
        selectedId: _tempSelectedCategoryId,
        onSelect: (cat) {
          setState(() {
            _tempSelectedCategoryId = cat.id;
            _tempSelectedCategoryName = cat.name
                .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                .replaceAll(RegExp(r'collection', caseSensitive: false), '')
                .trim();
          });
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _tempSelectedCategoryId = null;
            _tempSelectedCategoryName = '';
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

class _CategoryPickerSheet extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<CategoryModel> onSelect;
  final VoidCallback onClear;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onClear,
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
                Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: context.colorPalette.goldDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colorPalette.goldDeep,
                    ),
                  ),
                ),
                if (selectedId != null)
                  TextButton(
                    onPressed: onClear,
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
            child: categories.isEmpty
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
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categories.length,
                    itemBuilder: (_, index) {
                      final cat = categories[index];
                      final isSelected = cat.id == selectedId;
                      return GestureDetector(
                        onTap: () => onSelect(cat),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colorPalette.goldLight
                                : context.colorPalette.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? context.colorPalette.gold
                                  : context.colorPalette.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (cat.imageUrl.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    cat.imageUrl,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: context.colorPalette.goldLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.diamond_outlined,
                                        color: context.colorPalette.goldDark,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat.name
                                          .replaceAll(RegExp(r'[^a-zA-Z\s]'), '')
                                          .replaceAll(
                                            RegExp(r'collection',
                                                caseSensitive: false),
                                            '',
                                          )
                                          .trim(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.colorPalette.goldDeep,
                                      ),
                                    ),
                                    if (cat.level != null)
                                      Text(
                                        'Level ${cat.level}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.colorPalette.goldDark,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.colorPalette.gold,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
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