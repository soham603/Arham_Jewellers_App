import 'dart:async';
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

  Timer? _pollTimer;

  @override
  void onClose() {
    _stopPolling();
    super.onClose();
  }

  Future<void> fetchCatalogs({bool silent = false}) async {
    if (_isLoading.value) return;

    try {
      _isLoading.value = true;
      final result = await _repo.fetchAdminCatalogs();
      _catalogs.assignAll(result);
      _syncPolling();
    } catch (_) {
      if (!silent) {
        ToastUtils.showError('Failed to load PDF catalogs');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void _syncPolling() {
    if (_catalogs.any((c) => c.isProcessing)) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(
      const Duration(seconds: 4),
      (_) => fetchCatalogs(silent: true),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
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
        response['message']?.toString() ??
            'Upload received — processing in background',
      );

      await fetchCatalogs();
      return true;
    } catch (e) {
      ToastUtils.showError(_describeUploadError(e));
      return false;
    } finally {
      _isUploading.value = false;
    }
  }

  String _describeUploadError(Object e) {
    const fallback = 'Failed to upload PDF catalog';

    if (e is! DioException) return fallback;

    final data = e.response?.data;
    if (data is Map) {
      final nested = data['error'];
      final candidates = <dynamic>[
        nested is Map ? nested['message'] : null,
        data['message'],
      ];

      for (final candidate in candidates) {
        final text = candidate?.toString().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }

    switch (e.response?.statusCode) {
      case 408:
        return 'Upload timed out. Please check your connection and try again.';
      case 413:
        return 'The PDF is too large to upload.';
      case 401:
        return 'Your session expired. Please log in again.';
      case 403:
        return 'You do not have permission to upload catalogs.';
      case 502:
      case 503:
      case 504:
        return 'Server is temporarily unavailable. Please try again.';
    }

    final error = e.error;
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    final message = e.message?.trim();
    if (message != null && message.isNotEmpty) return message;

    return fallback;
  }

  Future<void> deleteCatalog(String id) async {
    if (_deletingIds.contains(id)) return;

    try {
      _deletingIds.add(id);
      await _repo.deleteCatalog(id: id);
      _catalogs.removeWhere((c) => c.id == id);
      _syncPolling();
      ToastUtils.showSuccess('PDF catalog deleted');
    } catch (_) {
      ToastUtils.showError('Failed to delete PDF catalog');
    } finally {
      _deletingIds.remove(id);
    }
  }

  Future<bool> renameCatalog({
    required String id,
    required String title,
  }) async {
    final index = _catalogs.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    final previous = _catalogs[index];
    _catalogs[index] = previous.copyWith(title: title);

    try {
      await _repo.editCatalog(id: id, title: title);
      ToastUtils.showSuccess('Catalog renamed');
      return true;
    } catch (_) {
      final rollbackIndex = _catalogs.indexWhere((c) => c.id == id);
      if (rollbackIndex != -1) {
        _catalogs[rollbackIndex] =
            _catalogs[rollbackIndex].copyWith(title: previous.title);
      }
      ToastUtils.showError('Failed to rename catalog');
      return false;
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
      final rollbackIndex = _catalogs.indexWhere((c) => c.id == catalogId);
      if (rollbackIndex == -1) return;
      final rollbackPages =
          List<PdfCatalogPageModel>.from(_catalogs[rollbackIndex].pages);
      final rollbackPageIndex =
          rollbackPages.indexWhere((p) => p.id == page.id);
      if (rollbackPageIndex == -1) return;
      rollbackPages[rollbackPageIndex] =
          rollbackPages[rollbackPageIndex].copyWith(isActive: !isActive);
      _catalogs[rollbackIndex] =
          _catalogs[rollbackIndex].copyWith(pages: rollbackPages);
      ToastUtils.showError('Failed to update page');
    }
  }
}
