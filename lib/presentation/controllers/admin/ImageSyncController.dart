import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/data/repositories/product_repository.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class MissingImageItem {
  final String id;
  final String? tagNo;
  final String name;
  final String? imageUrl;
  final String? sourceImage;
  final String? tagGenerateDate;

  MissingImageItem({
    required this.id,
    this.tagNo,
    required this.name,
    this.imageUrl,
    this.sourceImage,
    this.tagGenerateDate,
  });

  factory MissingImageItem.fromJson(Map<String, dynamic> json) {
    return MissingImageItem(
      id: json['id']?.toString() ?? '',
      tagNo: json['tagNo']?.toString(),
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      sourceImage: json['sourceImage']?.toString(),
      tagGenerateDate: json['tagGenerateDate']?.toString(),
    );
  }
}

class SyncResultItem {
  final String status;
  final String? reason;
  final String? url;

  SyncResultItem({required this.status, this.reason, this.url});

  factory SyncResultItem.fromJson(Map<String, dynamic> json) {
    return SyncResultItem(
      status: json['status']?.toString() ?? 'FAILED',
      reason: json['reason']?.toString(),
      url: json['url']?.toString(),
    );
  }
}

class ImageSyncController extends GetxController {
  static ImageSyncController get instance =>
      Get.isRegistered<ImageSyncController>()
          ? Get.find<ImageSyncController>()
          : Get.put(ImageSyncController());

  final _productRepo = ProductRepository();

  final _listState = CurrentAppState.INITIAL.obs;
  CurrentAppState get listState => _listState.value;

  final _items = <MissingImageItem>[].obs;
  List<MissingImageItem> get items => _items;

  final _total = 0.obs;
  int get total => _total.value;

  final _isSyncing = false.obs;
  bool get isSyncing => _isSyncing.value;

  final _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  final _syncedCount = 0.obs;
  int get syncedCount => _syncedCount.value;

  final _failedCount = 0.obs;
  int get failedCount => _failedCount.value;

  final _results = <String, SyncResultItem>{}.obs;
  Map<String, SyncResultItem> get results => _results;

  Rx<DateTime?> startDate = Rxn<DateTime>();
  Rx<DateTime?> endDate = Rxn<DateTime>();

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> findMissingImages() async {
    final start = startDate.value;
    final end = endDate.value;

    if (start == null || end == null) {
      ToastUtils.showWarning('Please select both start and end dates');
      return;
    }
    if (start.isAfter(end)) {
      ToastUtils.showWarning('Start date cannot be after end date');
      return;
    }

    _listState.value = CurrentAppState.LOADING;
    _results.clear();
    _syncedCount.value = 0;
    _failedCount.value = 0;

    try {
      final response = await _productRepo.fetchMissingImages(
        startDate: _formatDate(start),
        endDate: _formatDate(end),
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final rawList = data['data'] is List ? data['data'] as List : [];
        _items.value = rawList
            .map((e) => MissingImageItem.fromJson(
                e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e)))
            .toList();
        _total.value = data['total'] is int
            ? data['total'] as int
            : int.tryParse(data['total']?.toString() ?? '0') ?? 0;
      } else {
        _items.clear();
        _total.value = 0;
      }
      _listState.value = CurrentAppState.SUCCESS;
    } catch (e) {
      _items.clear();
      _total.value = 0;
      _listState.value = CurrentAppState.ERROR;
      ToastUtils.showError(_errorMessage(e));
    }
  }

  Future<void> syncMissingImages() async {
    if (_isSyncing.value) return;
    if (_items.isEmpty) {
      ToastUtils.showWarning('No products to sync. Run a search first.');
      return;
    }

    _isSyncing.value = true;
    _syncedCount.value = 0;
    _failedCount.value = 0;
    _results.clear();

    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      _currentIndex.value = i + 1;

      try {
        final response = await _productRepo.syncMissingImage(item.id);
        final result = SyncResultItem.fromJson(response['data'] ?? {});
        _results[item.id] = result;
        if (result.status == 'SUCCESS') {
          _syncedCount.value++;
        } else {
          _failedCount.value++;
        }
      } catch (e) {
        _results[item.id] = SyncResultItem(
          status: 'FAILED',
          reason: _errorMessage(e),
        );
        _failedCount.value++;
      }
    }

    _isSyncing.value = false;

    if (_failedCount.value == 0) {
      ToastUtils.showSuccess(
          'Synced ${_syncedCount.value} image(s) successfully');
    } else {
      ToastUtils.showWarning(
          '${_syncedCount.value} synced, ${_failedCount.value} failed');
    }
  }

  void reset() {
    _items.clear();
    _total.value = 0;
    _results.clear();
    _syncedCount.value = 0;
    _failedCount.value = 0;
    _currentIndex.value = 0;
    _listState.value = CurrentAppState.INITIAL;
    startDate.value = null;
    endDate.value = null;
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      return e.response?.data?['message']?.toString() ?? e.message ?? 'Something went wrong';
    }
    return e.toString();
  }
}
