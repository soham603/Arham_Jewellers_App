import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:ratnesh_gold_app/core/utils/dio_error_helper.dart';
import 'package:ratnesh_gold_app/data/repositories/craftsman_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/craftsmanModel.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:ratnesh_gold_app/utils/fuzzy_match.dart';

class AdminCraftsmanController extends GetxController {
  static AdminCraftsmanController get instance => Get.find();
  final _craftsmanRepo = CraftsmanRepository();

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _craftsmen = <CraftsmanModel>[].obs;
  List<CraftsmanModel> get craftsmen => _craftsmen;

  final _searchQuery = ''.obs;

  List<CraftsmanModel> get filteredCraftsmen {
    final q = _searchQuery.value;
    if (q.trim().isEmpty) return _craftsmen;
    return fuzzyFilter(q, _craftsmen, (c) {
      final parts = <String>[
        c.name,
        c.phoneNumber,
        c.accountName ?? '',
        c.areaName ?? '',
        c.cityName ?? '',
        c.emailId ?? '',
        c.whatsAppNo ?? '',
      ];
      return parts.where((s) => s.isNotEmpty).join(' ');
    });
  }

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _actionLoadingId = ''.obs;
  String get actionLoadingId => _actionLoadingId.value;

  final _error = RxnString();
  String? get error => _error.value;

  final _totalCount = 0.obs;
  int get totalCount => _totalCount.value;

  @override
  void onInit() {
    super.onInit();
    if (_craftsmen.isEmpty) {
      fetchCraftsmen();
    }
  }

  Future<void> fetchCraftsmen() async {
    if (_isLoading.value) return;

    final isInitialLoad = _craftsmen.isEmpty;
    if (isInitialLoad) {
      _isLoading.value = true;
      _state.value = CurrentAppState.LOADING;
    }

    try {
      final result = await _craftsmanRepo.fetchCraftsmen(
        includeDeleted: true,
      );

      _craftsmen.value = result.items;
      _totalCount.value = result.total;
      _error.value = null;
      _state.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      _error.value = DioErrorHelper.getMessage(e);
      _state.value = CurrentAppState.ERROR;
      if (isInitialLoad) {
        ToastUtils.showError(_error.value ?? 'Unknown error');
      }
    } finally {
      _isLoading.value = false;
    }
  }

  Future<(String? error, String? successMessage)> importCraftsmen(
    File file,
  ) async {
    _isLoading.value = true;
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await _craftsmanRepo.importCraftsmen(
        formData: formData,
      );

      final data = response['data'] as Map<String, dynamic>?;
      final created = data?['created'] ?? 0;
      final updated = data?['updated'] ?? 0;
      final skipped = data?['skipped'] ?? 0;
      final failed = data?['failed'] ?? 0;

      final summary = 'Created: $created, Updated: $updated, Skipped: $skipped, Failed: $failed';
      final message = response['message']?.toString() ?? summary;

      ToastUtils.showSuccess(message);

      await fetchCraftsmen();

      return (null, message);
    } catch (e, st) {
      final errorMsg = DioErrorHelper.getMessage(e);
      ToastUtils.showError(errorMsg);
      return (errorMsg, null);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<(String? error, String? successMessage)> deleteCraftsman(
    String id,
  ) async {
    _actionLoadingId.value = id;
    try {
      final response = await _craftsmanRepo.deleteCraftsman(id: id);

      final idx = _craftsmen.indexWhere((c) => c.id == id);
      if (idx != -1) {
        final c = _craftsmen[idx];
        _craftsmen[idx] = c.copyWith(
          deletedAt: DateTime.now(),
          isActive: false,
        );
      }

      final msg = response['message']?.toString();
      if (msg != null) ToastUtils.showSuccess(msg);
      await fetchCraftsmen();
      return (null, msg);
    } catch (e, st) {
      final errorMsg = DioErrorHelper.getMessage(e);
      ToastUtils.showError(errorMsg);
      return (errorMsg, null);
    } finally {
      _actionLoadingId.value = '';
    }
  }

  Future<(String? error, String? successMessage)> restoreCraftsman(
    String id,
  ) async {
    _actionLoadingId.value = id;
    try {
      final response = await _craftsmanRepo.restoreCraftsman(id: id);

      final restored = CraftsmanModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
      final idx = _craftsmen.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _craftsmen[idx] = restored;
      }

      final msg = response['message']?.toString();
      if (msg != null) ToastUtils.showSuccess(msg);
      await fetchCraftsmen();
      return (null, msg);
    } catch (e, st) {
      final errorMsg = DioErrorHelper.getMessage(e);
      ToastUtils.showError(errorMsg);
      return (errorMsg, null);
    } finally {
      _actionLoadingId.value = '';
    }
  }

  void search(String query) {
    _searchQuery.value = query;
    update();
  }



}
