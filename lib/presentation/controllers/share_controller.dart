import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/core/services/share_service.dart';
import 'package:ratnesh_gold_app/core/constants/karat_constants.dart';

class SelectedLevel3Category {
  final String id;
  final String name;
  final String level2Name;
  final String karatName;
  final int touchValue;

  const SelectedLevel3Category({
    required this.id,
    required this.name,
    required this.level2Name,
    required this.karatName,
    required this.touchValue,
  });

  String get displayName => '$touchValue $name';
}

class ShareController extends GetxController {
  static ShareController get instance => Get.find();

  final _categoryController = Get.find<CategoryController>();

  // ── Karat selection 
  final _selectedKarat = RxnString();
  String? get selectedKarat => _selectedKarat.value;

  // ── Drill-down level: 2 = collections, 3 = styles 
  final _drillLevel = 2.obs;
  int get drillLevel => _drillLevel.value;

  // ── Current level-2 being drilled into 
  final _currentLevel2 = Rxn<CategoryModel>();
  CategoryModel? get currentLevel2 => _currentLevel2.value;


  // ── Selected level-3 categories (persist across navigation) ─
  // Key format: "${karatName}_${level3Id}" to avoid cross-karat collisions
  final _selectedLevel3 = <String, SelectedLevel3Category>{}.obs;
  Map<String, SelectedLevel3Category> get selectedLevel3 => _selectedLevel3;
  int get selectedCount => _selectedLevel3.length;
  bool get hasSelection => _selectedLevel3.isNotEmpty;

  String _selectionKey(String karatName, String level3Id) => '${karatName}_$level3Id';

  bool isLevel3Selected(String id) {
    final karat = _selectedKarat.value;
    if (karat == null) return false;
    return _selectedLevel3.containsKey(_selectionKey(karat, id));
  }

  // ── Current level-2 list based on selected karat 
  List<CategoryModel> get currentLevel2Categories {
    final karat = _selectedKarat.value;
    if (karat == null) return [];
    switch (karat) {
      case '18K':
        return _categoryController.k18Categories;
      case '20K':
        return _categoryController.k20Categories;
      case '22K':
        return _categoryController.k22Categories;
      default:
        return [];
    }
  }

  // ── Current level-3 list from cache 
  List<CategoryModel> get currentLevel3Categories {
    final level2 = _currentLevel2.value;
    if (level2 == null) return [];
    return _categoryController.level3Cache[level2.id] ?? [];
  }

  // ── Selected categories info for share message 
  String get selectedCategoriesInfo {
    if (_selectedLevel3.isEmpty) return '';
    return _selectedLevel3.values.map((s) => s.displayName).join('\n');
  }

  // ── Product count for selected categories 
  final _productCount = 0.obs;
  int get productCount => _productCount.value;

  Future<void> fetchProductCount() async {
    final ids = selectedCategoryIds;
    if (ids.isEmpty) {
      _productCount.value = 0;
      return;
    }
    _productCount.value = await ShareService.fetchProductCount(ids);
  }

  // ── Touch value mapping ──
  static int _touchValueForKarat(String karat) => KaratConstants.touchValueFor(karat);

  // ── Actions ─

  Future<void> selectKarat(String karat) async {
    if (_selectedKarat.value == karat) return;
    _selectedKarat.value = karat;
    _drillLevel.value = 2;
    _currentLevel2.value = null;

    // Ensure category tree is loaded
    if (_categoryController.k18Categories.isEmpty) {
      await _categoryController.fetchCategoryTree();
    }
  }

  void drillIntoLevel2(CategoryModel level2) {
    _currentLevel2.value = level2;
    _drillLevel.value = 3;
  }

  void goBackToLevel2() {
    _drillLevel.value = 2;
    _currentLevel2.value = null;
  }

  void goBackToKarat() {
    _selectedKarat.value = null;
    _drillLevel.value = 2;
    _currentLevel2.value = null;
  }

  void toggleLevel3Selection(CategoryModel level3) {
    final karatName = _selectedKarat.value ?? '';
    final key = _selectionKey(karatName, level3.id);
    if (_selectedLevel3.containsKey(key)) {
      _selectedLevel3.remove(key);
    } else {
      _selectedLevel3[key] = SelectedLevel3Category(
        id: level3.id,
        name: level3.name,
        level2Name: _currentLevel2.value?.name ?? '',
        karatName: karatName,
        touchValue: _touchValueForKarat(karatName),
      );
    }
  }

  void selectAllLevel3() {
    for (final cat in currentLevel3Categories) {
      final karatName = _selectedKarat.value ?? '';
      final key = _selectionKey(karatName, cat.id);
      if (!_selectedLevel3.containsKey(key)) {
        _selectedLevel3[key] = SelectedLevel3Category(
          id: cat.id,
          name: cat.name,
          level2Name: _currentLevel2.value?.name ?? '',
          karatName: karatName,
          touchValue: _touchValueForKarat(karatName),
        );
      }
    }
  }

  void deselectAllLevel3() {
    final karatName = _selectedKarat.value ?? '';
    final currentIds = currentLevel3Categories
        .map((c) => _selectionKey(karatName, c.id))
        .toSet();
    _selectedLevel3.removeWhere((key, _) => currentIds.contains(key));
  }

  bool get areAllCurrentLevel3Selected {
    final cats = currentLevel3Categories;
    if (cats.isEmpty) return false;
    final karatName = _selectedKarat.value ?? '';
    return cats.every((c) => _selectedLevel3.containsKey(_selectionKey(karatName, c.id)));
  }

  void clearSelection() => _selectedLevel3.clear();

  List<String> get selectedCategoryIds => _selectedLevel3.values.map((s) => s.id).toList();

  @override
  void onClose() {
    _selectedLevel3.clear();
    _selectedKarat.value = null;
    _currentLevel2.value = null;
    super.onClose();
  }
}
