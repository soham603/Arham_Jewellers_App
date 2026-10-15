import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/data/repositories/product_repository.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

enum StockSyncKind { full, backfill }

class StockSyncSummary {
  final int? totalFromApi;
  final int? created;
  final int? updated;
  final int? imagesQueued;
  final int? imagesSuccess;
  final int? imagesFailed;
  final int? dbFailed;
  final String? duration;
  final String? syncRunAt;
  final String? lastSyncDate;
  final int failedImages;
  final int failedDbInserts;

  StockSyncSummary({
    this.totalFromApi,
    this.created,
    this.updated,
    this.imagesQueued,
    this.imagesSuccess,
    this.imagesFailed,
    this.dbFailed,
    this.duration,
    this.syncRunAt,
    this.lastSyncDate,
    this.failedImages = 0,
    this.failedDbInserts = 0,
  });

  factory StockSyncSummary.fromResponse(Map<String, dynamic> data) {
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};
    final products = summary['products'] is Map
        ? Map<String, dynamic>.from(summary['products'] as Map)
        : <String, dynamic>{};
    final images = summary['images'] is Map
        ? Map<String, dynamic>.from(summary['images'] as Map)
        : <String, dynamic>{};
    final failures = summary['failures'] is Map
        ? Map<String, dynamic>.from(summary['failures'] as Map)
        : <String, dynamic>{};
    final meta = summary['meta'] is Map
        ? Map<String, dynamic>.from(summary['meta'] as Map)
        : <String, dynamic>{};

    return StockSyncSummary(
      totalFromApi: _asInt(summary['totalFromApi']),
      created: _asInt(products['created']),
      updated: _asInt(products['updated']),
      imagesQueued: _asInt(images['queued']),
      imagesSuccess: _asInt(images['success']),
      imagesFailed: _asInt(images['failed']),
      dbFailed: _asInt(failures['db']),
      duration: meta['duration']?.toString(),
      syncRunAt: meta['syncRunAt']?.toString(),
      lastSyncDate: meta['lastSyncDate']?.toString(),
      failedImages: data['failedImages'] is List
          ? (data['failedImages'] as List).length
          : 0,
      failedDbInserts: data['failedDbInserts'] is List
          ? (data['failedDbInserts'] as List).length
          : 0,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class StockSyncResult {
  final StockSyncKind kind;
  final DateTime ranAt;
  final String message;
  final StockSyncSummary summary;

  StockSyncResult({
    required this.kind,
    required this.ranAt,
    required this.message,
    required this.summary,
  });
}

class StockSyncController extends GetxController {
  static StockSyncController get instance =>
      Get.isRegistered<StockSyncController>()
      ? Get.find<StockSyncController>()
      : Get.put(StockSyncController());

  final _productRepo = ProductRepository();

  final _runningKind = Rxn<StockSyncKind>();
  StockSyncKind? get runningKind => _runningKind.value;
  bool get isRunning => _runningKind.value != null;

  final _elapsed = 0.obs;
  int get elapsed => _elapsed.value;

  final _result = Rxn<StockSyncResult>();
  StockSyncResult? get result => _result.value;

  Rx<DateTime?> overrideDate = Rxn<DateTime>();

  Timer? _timer;
  DateTime? _startedAt;

  Future<void> runFull() {
    return _run(StockSyncKind.full, () => _productRepo.triggerFullStockSync());
  }

  Future<void> runBackfill() {
    final date = overrideDate.value;
    if (date == null) {
      ToastUtils.showWarning('Please select a backfill date');
      return Future.value();
    }
    return _run(
      StockSyncKind.backfill,
      () => _productRepo.triggerStockSync(
        overrideLastSyncDate: formatBackendDate(date),
      ),
    );
  }

  Future<void> _run(
    StockSyncKind kind,
    Future<Map<String, dynamic>> Function() call,
  ) async {
    if (isRunning) return;

    _runningKind.value = kind;
    _startedAt = DateTime.now();
    _elapsed.value = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _startedAt;
      if (startedAt != null) {
        _elapsed.value = DateTime.now().difference(startedAt).inSeconds;
      }
    });

    try {
      final response = await call();
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'] as Map)
          : <String, dynamic>{};
      final summary = StockSyncSummary.fromResponse(data);
      final message = response['message']?.toString() ?? 'Sync completed.';
      _result.value = StockSyncResult(
        kind: kind,
        ranAt: DateTime.now(),
        message: message,
        summary: summary,
      );

      final failed = (summary.imagesFailed ?? 0) + (summary.dbFailed ?? 0);
      if (failed > 0) {
        ToastUtils.showWarning(message);
      } else {
        ToastUtils.showSuccess(message);
      }
    } catch (e) {
      ToastUtils.showError(_errorMessage(e));
    } finally {
      _timer?.cancel();
      _timer = null;
      _startedAt = null;
      _runningKind.value = null;
    }
  }

  static String formatBackendDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:00';
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      return e.response?.data?['message']?.toString() ??
          e.message ??
          'Something went wrong';
    }
    return e.toString();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
