import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/domain/entities/admin/goldRateModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class GoldRateController extends GetxController {
  static GoldRateController get instance => Get.find();

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

  final _selectedPeriod = 'month'.obs;
  String get selectedPeriod => _selectedPeriod.value;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentRate();
    fetchHistory();
  }

  Future<void> fetchCurrentRate() async {
    try {
      if (_currentRate.value == null) {
        _state.value = CurrentAppState.LOADING;
      }

      final response = await httpClient.get(
        '/api/v1/live-rate/current',
        options: Options(
          extra: {'requiresAuth': false},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['code'] != 'ERROR') {
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

  Future<void> fetchHistory({String? period}) async {
    if (_state.value == CurrentAppState.LOADING) return;

    if (period != null) {
      _selectedPeriod.value = period;
    }

    _state.value = CurrentAppState.LOADING;

    try {
      final response = await httpClient.get(
        '/api/v1/live-rate/history',
        queryParameters: {'period': _selectedPeriod.value},
        options: Options(
          extra: {'requiresAuth': false},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['code'] != 'ERROR') {
        final List<dynamic> data = response.data['data'] ?? [];
        final items = data.map((e) => GoldRateModel.fromJson(e)).toList();
        _history.assignAll(items);
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

  Future<bool> setRate({required double rate}) async {
    _actionState.value = CurrentAppState.LOADING;

    try {
      final currentRateValue = _currentRate.value?.rate;
      final change = currentRateValue != null
          ? (rate - currentRateValue).toStringAsFixed(2)
          : '0.00';

      final response = await httpClient.post(
        '/api/v1/live-rate/update',
        data: {
          'rate': rate,
          'source': 'market',
          'metadata': {
            'change': change,
          },
        },
        options: Options(
          extra: {'requiresAuth': true},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['code'] != 'ERROR') {
        final data = response.data['data'];
        if (data != null) {
          _currentRate.value = GoldRateModel.fromJson(data);
        }
        _actionState.value = CurrentAppState.SUCCESS;
        Get.snackbar('Success', 'Gold rate updated to ₹${rate.toStringAsFixed(0)}/10g');
        fetchHistory();
        return true;
      } else {
        _actionState.value = CurrentAppState.ERROR;
        Get.snackbar('Error', response.data?['message'] ?? 'Failed to update rate');
        return false;
      }
    } on DioException catch (e, st) {
      Logger.error('GoldRateController', 'setRate Dio: $e\n$st');
      _actionState.value = CurrentAppState.ERROR;
      Get.snackbar('Error', e.response?.data?['message'] ?? e.message ?? 'Failed to update rate');
      return false;
    } catch (e, st) {
      Logger.error('GoldRateController', 'setRate: $e\n$st');
      _actionState.value = CurrentAppState.ERROR;
      Get.snackbar('Error', e.toString());
      return false;
    }
  }

  Future<void> refresh_() async {
    await fetchCurrentRate();
    await fetchHistory();
  }
}
