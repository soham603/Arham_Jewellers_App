import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:ratnesh_gold_app/data/repositories/pdf_catalog_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/pdf_catalog_model.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class AdminPdfCatalogController extends GetxController {
  static AdminPdfCatalogController get instance => Get.find();

  final _repo = PdfCatalogRepository();

  final _catalogs = <PdfCatalogModel>[].obs;
  List<PdfCatalogModel> get catalogs => _catalogs;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _isUploading = false.obs;
  bool get isUploading => _isUploading.value;

  final _deletingIds = <String>{}.obs;
  bool isDeleting(String id) => _deletingIds.contains(id);

  Future<void> fetchCatalogs() async {
    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      final result = await _repo.fetchAdminCatalogs();
      _catalogs.assignAll(result);
    } catch (_) {
      ToastUtils.showError('Failed to load PDF catalogs');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> uploadCatalog({
    required File file,
    required String title,
  }) async {
    if (_isUploading.value) return false;

    try {
      _isUploading.value = true;

      final formData = FormData.fromMap({
        'title': title,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _repo.createCatalog(data: formData);

      ToastUtils.showSuccess(
        response['message']?.toString() ?? 'PDF catalog uploaded',
      );

      await fetchCatalogs();
      return true;
    } catch (e) {
      String message = 'Failed to upload PDF catalog';
      if (e is DioException) {
        message =
            e.response?.data?['message']?.toString() ?? e.message ?? message;
      }
      ToastUtils.showError(message);
      return false;
    } finally {
      _isUploading.value = false;
    }
  }

  Future<void> deleteCatalog(String id) async {
    if (_deletingIds.contains(id)) return;

    try {
      _deletingIds.add(id);
      await _repo.deleteCatalog(id: id);
      _catalogs.removeWhere((c) => c.id == id);
      ToastUtils.showSuccess('PDF catalog deleted');
    } catch (_) {
      ToastUtils.showError('Failed to delete PDF catalog');
    } finally {
      _deletingIds.remove(id);
    }
  }

  Future<void> togglePage({
    required String catalogId,
    required PdfCatalogPageModel page,
    required bool isActive,
  }) async {
    final catalogIndex = _catalogs.indexWhere((c) => c.id == catalogId);
    if (catalogIndex == -1) return;

    final pages = List<PdfCatalogPageModel>.from(_catalogs[catalogIndex].pages);
    final pageIndex = pages.indexWhere((p) => p.id == page.id);
    if (pageIndex == -1) return;

    pages[pageIndex] = pages[pageIndex].copyWith(isActive: isActive);
    _catalogs[catalogIndex] = _catalogs[catalogIndex].copyWith(pages: pages);

    try {
      await _repo.toggleCatalogPage(pageId: page.id, isActive: isActive);
    } catch (_) {
      pages[pageIndex] = pages[pageIndex].copyWith(isActive: !isActive);
      _catalogs[catalogIndex] = _catalogs[catalogIndex].copyWith(pages: pages);
      ToastUtils.showError('Failed to update page');
    }
  }
}
