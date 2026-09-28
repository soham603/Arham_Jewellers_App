import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ratnesh_gold_app/data/repositories/pdf_catalog_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/pdf_catalog_model.dart';

class PdfCatalogController extends GetxController {
  static PdfCatalogController get instance => Get.find();

  static const _selectionPrefKey = 'pdf_catalog_design_selection';

  final _repo = PdfCatalogRepository();

  final _catalogs = <PdfCatalogModel>[].obs;
  List<PdfCatalogModel> get catalogs => _catalogs;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _error = ''.obs;
  String get error => _error.value;

  final _selection = Rxn<CatalogDesignSelection>();
  CatalogDesignSelection? get selection => _selection.value;

  @override
  void onInit() {
    super.onInit();
    loadSavedSelection();
  }

  Future<bool> fetchCatalogs() async {
    if (_isLoading.value) return false;

    try {
      _isLoading.value = true;
      _error.value = '';
      final result = await _repo.fetchActiveCatalogs();
      _catalogs.assignAll(result);
      return true;
    } catch (e) {
      _error.value = 'Could not load catalogs. Please try again.';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> isSelectionStillAvailable() async {
    final current = _selection.value;
    if (current == null) return true;

    final loaded = await fetchCatalogs();
    if (!loaded) return true;

    return _catalogs.any(
      (catalog) =>
          catalog.id == current.catalogId &&
          catalog.pages.any(
            (page) => current.pageId.isNotEmpty
                ? page.id == current.pageId
                : page.pageNumber == current.pageNumber,
          ),
    );
  }

  Future<void> loadSavedSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_selectionPrefKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _selection.value = CatalogDesignSelection.fromJson(decoded);
      }
    } catch (_) {}
  }

  Future<void> saveSelection(CatalogDesignSelection selection) async {
    _selection.value = selection;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionPrefKey, jsonEncode(selection.toJson()));
  }

  Future<void> clearSelection() async {
    _selection.value = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectionPrefKey);
  }
}
