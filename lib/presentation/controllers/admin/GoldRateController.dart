import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import 'package:ratnesh_gold_app/data/repositories/gold_rate_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/goldRateModel.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class GoldRateController extends GetxController {
  static GoldRateController get instance => Get.find();

  final _goldRateRepo = GoldRateRepository();

  final _currentRate = Rxn<GoldRateModel>();
  GoldRateModel? get currentRate => _currentRate.value;

  final _history = <GoldRateModel>[].obs;
  List<GoldRateModel> get history => _history;

  final _statistics = Rxn<GoldRateStatistics>();
  GoldRateStatistics? get statistics => _statistics.value;

  final _currentRateState = CurrentAppState.INITIAL.obs;
  CurrentAppState get currentRateState => _currentRateState.value;

  final _historyState = CurrentAppState.INITIAL.obs;
  CurrentAppState get historyState => _historyState.value;

  final _statisticsState = CurrentAppState.INITIAL.obs;
  CurrentAppState get statisticsState => _statisticsState.value;

  final _actionState = CurrentAppState.INITIAL.obs;
  CurrentAppState get actionState => _actionState.value;

  final _error = ''.obs;
  String get error => _error.value;

  final _selectedPeriod = 'month'.obs;
  String get selectedPeriod => _selectedPeriod.value;

  final _activeFilterType = 'period'.obs;
  String get activeFilterType => _activeFilterType.value;

  final _selectedDateRange = Rxn<DateTimeRange>();
  DateTimeRange? get selectedDateRange => _selectedDateRange.value;

  final _dateRangeLabel = ''.obs;
  String get dateRangeLabel => _dateRangeLabel.value;

  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
      fetchCurrentRate();
      fetchHistory();
    }
  }

  Future<void> fetchCurrentRate() async {
    try {
      _currentRateState.value = CurrentAppState.LOADING;

      final response = await _goldRateRepo.fetchCurrentRate();

      if (response['code'] != 'ERROR') {
        final data = response['data'];
        if (data != null) {
          _currentRate.value = GoldRateModel.fromJson(data);
        }
        _currentRateState.value = CurrentAppState.SUCCESS;
      } else {
        _currentRateState.value = CurrentAppState.ERROR;
        _error.value = response['message'] ?? 'Failed to load gold rate';
      }
    } on DioException catch (e, st) {
      Logger.error('GoldRateController', 'fetchCurrentRate Dio: $e\n$st');
      _currentRateState.value = CurrentAppState.ERROR;
      _error.value =
          e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e, st) {
      Logger.error('GoldRateController', 'fetchCurrentRate: $e\n$st');
      _currentRateState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<void> fetchHistory({
    String? period,
    String? month,
    String? year,
    String? startDate,
    String? endDate,
  }) async {
    if (_historyState.value == CurrentAppState.LOADING) return;

    if (period != null && _activeFilterType.value == 'period') {
      _selectedPeriod.value = period;
    }

    _historyState.value = CurrentAppState.LOADING;

    try {
      final queryParams = <String, String>{};

      if (startDate != null && endDate != null) {
        queryParams['startDate'] = startDate;
        queryParams['endDate'] = endDate;
      } else if (_activeFilterType.value == 'custom' &&
          _selectedDateRange.value != null) {
        final range = _selectedDateRange.value!;
        queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(range.start);
        queryParams['endDate'] = DateFormat('yyyy-MM-dd').format(range.end);
      } else if (month != null) {
        queryParams['month'] = month;
      } else if (year != null) {
        queryParams['year'] = year;
      } else {
        queryParams['period'] = _selectedPeriod.value;
      }

      final response = await _goldRateRepo.fetchHistory(
        queryParams: queryParams,
      );

      if (response['code'] != 'ERROR') {
        final rawData = response['data'];
        List<GoldRateModel> items = [];

        if (rawData is List) {
          items = rawData.map((e) => GoldRateModel.fromJson(e)).toList();
        } else if (rawData is Map<String, dynamic>) {
          final dailyTrend = rawData['dailyTrend'];
          if (dailyTrend is List) {
            items = dailyTrend.map<GoldRateModel>((e) {
              final dateStr = e['date'] ?? '';
              final closingRate = (e['closingRate'] ?? e['avg'] ?? 0)
                  .toDouble();
              return GoldRateModel(
                id: null,
                rate: closingRate,
                source: null,
                timestamp: DateTime.tryParse(dateStr) ?? DateTime.now(),
                metadata: null,
              );
            }).toList();
          }

          if (rawData['summary'] != null) {
            _statistics.value = GoldRateStatistics.fromJson(rawData['summary']);
            _statisticsState.value = CurrentAppState.SUCCESS;
          }
        }

        items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _history.assignAll(items);
        _historyState.value = CurrentAppState.SUCCESS;
      } else {
        _historyState.value = CurrentAppState.ERROR;
        _error.value = response['message'] ?? 'Failed to load history';
      }
    } on DioException catch (e, st) {
      Logger.error('GoldRateController', 'fetchHistory Dio: $e\n$st');
      _historyState.value = CurrentAppState.ERROR;
      _error.value =
          e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e, st) {
      Logger.error('GoldRateController', 'fetchHistory: $e\n$st');
      _historyState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<void> fetchStatistics({
    String? period,
    String? month,
    String? year,
    String? startDate,
    String? endDate,
  }) async {
    _statisticsState.value = CurrentAppState.LOADING;

    try {
      final queryParams = <String, String>{};

      if (startDate != null && endDate != null) {
        queryParams['startDate'] = startDate;
        queryParams['endDate'] = endDate;
      } else if (month != null) {
        queryParams['month'] = month;
      } else if (year != null) {
        queryParams['year'] = year;
      } else {
        queryParams['period'] = period ?? _selectedPeriod.value;
      }

      final response = await _goldRateRepo.fetchStatistics(
        queryParams: queryParams,
      );

      if (response['code'] != 'ERROR') {
        final data = response['data'];
        if (data != null && data['summary'] != null) {
          _statistics.value = GoldRateStatistics.fromJson(data['summary']);
        }
        _statisticsState.value = CurrentAppState.SUCCESS;
      } else {
        _statisticsState.value = CurrentAppState.ERROR;
      }
    } on DioException catch (e, st) {
      if (e.response?.statusCode == 404) {
        _statistics.value = null;
        _statisticsState.value = CurrentAppState.SUCCESS;
        return;
      }
      Logger.error('GoldRateController', 'fetchStatistics Dio: $e\n$st');
      _statisticsState.value = CurrentAppState.ERROR;
    } catch (e, st) {
      Logger.error('GoldRateController', 'fetchStatistics: $e\n$st');
      _statisticsState.value = CurrentAppState.ERROR;
    }
  }

  Future<bool> setRate({required double rate}) async {
    _actionState.value = CurrentAppState.LOADING;

    try {
      final currentRateValue = _currentRate.value?.rate;
      final change = currentRateValue != null
          ? (rate - currentRateValue).toStringAsFixed(2)
          : '0.00';

      final response = await _goldRateRepo.updateRate(
        rateData: {
          'rate': rate,
          'source': 'market',
          'metadata': {'change': change},
        },
      );

      if (response['code'] != 'ERROR') {
        final data = response['data'];
        if (data != null) {
          _currentRate.value = GoldRateModel.fromJson(data);
        }
        _actionState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess('Gold rate updated to ₹${rate.toStringAsFixed(0)}/10g');
        fetchHistory();
        return true;
      } else {
        _actionState.value = CurrentAppState.ERROR;
        ToastUtils.showError(response['message'] ?? 'Failed to update rate');
        return false;
      }
    } on DioException catch (e, st) {
      Logger.error('GoldRateController', 'setRate Dio: $e\n$st');
      _actionState.value = CurrentAppState.ERROR;
      ToastUtils.showError(e.response?.data?['message'] ?? e.message ?? 'Failed to update rate');
      return false;
    } catch (e, st) {
      Logger.error('GoldRateController', 'setRate: $e\n$st');
      _actionState.value = CurrentAppState.ERROR;
      ToastUtils.showError(e.toString());
      return false;
    }
  }

  Future<void> refresh_() async {
    if (_activeFilterType.value == 'custom' &&
        _selectedDateRange.value != null) {
      await Future.wait([fetchCurrentRate(), fetchHistory()]);
    } else {
      await Future.wait([fetchCurrentRate(), fetchHistory()]);
    }
  }

  void applyDateRange(DateTime start, DateTime end, String label) {
    _activeFilterType.value = 'custom';
    _selectedDateRange.value = DateTimeRange(start: start, end: end);
    _dateRangeLabel.value = label;
    fetchHistory();
  }

  void clearDateRange() {
    _activeFilterType.value = 'period';
    _selectedDateRange.value = null;
    _dateRangeLabel.value = '';
    fetchHistory(period: _selectedPeriod.value);
  }

  void selectPeriod(String period) {
    _activeFilterType.value = 'period';
    _selectedDateRange.value = null;
    _dateRangeLabel.value = '';
    fetchHistory(period: period);
  }

  static double? calculatePrice({
    required double fineWeight,
    required double ratePer10Gram,
  }) {
    final base = fineWeight * (ratePer10Gram / 10);
    final labour = base * 0.10;
    final subtotal = base + labour;
    final gst = subtotal * 0.03;
    return subtotal + gst;
  }
}
