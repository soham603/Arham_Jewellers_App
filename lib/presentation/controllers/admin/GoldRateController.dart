import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/domain/entities/admin/goldRateModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoldRateController extends GetxController {
  static GoldRateController get instance => Get.find();

  static const String _localRateKey = 'gold_rate_per_gram';
  static const String _localRateDateKey = 'gold_rate_date';

  final _currentRate = Rxn<GoldRateModel>();
  GoldRateModel? get currentRate => _currentRate.value;

  final _history = <GoldRateModel>[].obs;
  List<GoldRateModel> get history => _history;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _actionState = CurrentAppState.INITIAL.obs;
  CurrentAppState get actionState => _actionState.value;

  final _error = ''.obs;
  String get error => _error.value;

  int _page = 1;
  static const int _pageLimit = 20;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  void onInit() {
    super.onInit();
    _loadLocalRate();
    fetchCurrentRate();
    fetchHistory();
  }

  Future<void> _loadLocalRate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rate = prefs.getDouble(_localRateKey);
      final dateStr = prefs.getString(_localRateDateKey);
      if (rate != null) {
        _currentRate.value = GoldRateModel(
          id: 'local',
          ratePerGram: rate,
          setBy: 'Admin (local)',
          createdAt: dateStr != null
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now(),
        );
      }
    } catch (e) {
      Logger.error('GoldRateController', '_loadLocalRate: $e');
    }
  }

  Future<void> _saveLocalRate(double rate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_localRateKey, rate);
      await prefs.setString(_localRateDateKey, DateTime.now().toIso8601String());
    } catch (e) {
      Logger.error('GoldRateController', '_saveLocalRate: $e');
    }
  }

  Future<void> fetchCurrentRate() async {
    try {
      if (_currentRate.value == null) {
        _state.value = CurrentAppState.LOADING;
      }

      final response = await httpClient.get(
        '/api/v1/gold-rate/current',
        options: Options(
          extra: {'requiresAuth': true},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] != false) {
        final data = response.data['data'];
        if (data != null) {
          _currentRate.value = GoldRateModel.fromJson(data);
        }
        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
        _error.value = response.data?['message'] ?? 'Failed to load gold rate';
      }
    } on DioException catch (e, st) {
      Logger.error('GoldRateController', 'fetchCurrentRate Dio: $e\n$st');
      _state.value = CurrentAppState.ERROR;
      _error.value = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e, st) {
      Logger.error('GoldRateController', 'fetchCurrentRate: $e\n$st');
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<void> fetchHistory({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;
    if (_state.value == CurrentAppState.LOADING && !isPagination) return;

    if (!isPagination) {
      _page = 1;
      _hasMore = true;
      _history.clear();
    }

    try {
      if (!isPagination) _state.value = CurrentAppState.LOADING;

      final response = await httpClient.get(
        '/api/v1/gold-rate/history',
        queryParameters: {'page': _page, 'limit': _pageLimit},
        options: Options(
          extra: {'requiresAuth': true},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] != false) {
        final List<dynamic> data = response.data['data'] ?? [];
        final items = data.map((e) => GoldRateModel.fromJson(e)).toList();

        if (isPagination) {
          _history.addAll(items);
        } else {
          _history.assignAll(items);
        }

        _hasMore = items.length >= _pageLimit;
        _page++;
        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
        _error.value = response.data?['message'] ?? 'Failed to load history';
      }
    } on DioException catch (e, st) {
      Logger.error('GoldRateController', 'fetchHistory Dio: $e\n$st');
      _state.value = CurrentAppState.ERROR;
      _error.value = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e, st) {
      Logger.error('GoldRateController', 'fetchHistory: $e\n$st');
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<bool> setRate({required double ratePerGram}) async {
    _actionState.value = CurrentAppState.LOADING;

    final localRate = GoldRateModel(
      id: 'local',
      ratePerGram: ratePerGram,
      setBy: 'Admin (local)',
      createdAt: DateTime.now(),
    );

    _currentRate.value = localRate;
    _saveLocalRate(ratePerGram);
    _history.insert(0, localRate);
    _state.value = CurrentAppState.SUCCESS;

    _actionState.value = CurrentAppState.SUCCESS;
    Get.snackbar('Success', 'Gold rate updated to ₹${ratePerGram.toStringAsFixed(0)}/g');

    _trySyncToBackend(ratePerGram);

    return true;
  }

  Future<void> _trySyncToBackend(double ratePerGram) async {
    try {
      final response = await httpClient.post(
        '/api/v1/gold-rate/set',
        data: {'ratePerGram': ratePerGram},
        options: Options(
          extra: {'requiresAuth': true},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] != false) {
        Logger.info('GoldRateController', 'Rate synced to backend');
      }
    } catch (_) {
      Logger.info('GoldRateController', 'Backend sync skipped (not available)');
    }
  }

  Future<void> loadMore() async {
    await fetchHistory(isPagination: true);
  }

  Future<void> refresh_() async {
    await fetchCurrentRate();
    await fetchHistory();
  }
}
