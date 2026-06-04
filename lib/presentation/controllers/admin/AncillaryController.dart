import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/domain/entities/ancillary_page_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class AncillaryController extends GetxController {
  static AncillaryController get instance => Get.find();

  static const List<String> pageKeys = [
    'TERMS',
    'ABOUT',
    'CONTACT',
    'PRIVACY',
    'REFUND',
    'CITY_POLICY',
  ];

  static const Map<String, String> pageLabels = {
    'TERMS': 'Terms & Conditions',
    'ABOUT': 'About Us',
    'CONTACT': 'Contact',
    'PRIVACY': 'Privacy Policy',
    'REFUND': 'Refund Policy',
    'CITY_POLICY': 'City Policy',
  };

  final _pages = <String, AncillaryPageModel>{}.obs;
  Map<String, AncillaryPageModel> get pages => _pages;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _updateState = CurrentAppState.INITIAL.obs;
  CurrentAppState get updateState => _updateState.value;

  final _error = ''.obs;
  String get error => _error.value;

  AncillaryPageModel? getPage(String key) => _pages[key];

  Future<void> fetchPage(String pageKey) async {
    try {
      _state.value = CurrentAppState.LOADING;

      final response = await httpClient.get(
        '/api/v1/ancillary/get-page/$pageKey',
        options: Options(
          extra: {'requiresAuth': false},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] != false) {
        final data = response.data['data'];
        if (data != null) {
          _pages[pageKey] = AncillaryPageModel.fromJson(data);
        }
        _state.value = CurrentAppState.SUCCESS;
      } else {
        _state.value = CurrentAppState.ERROR;
        _error.value = response.data?['message'] ?? 'Failed to load page';
      }
    } on DioException catch (e, st) {
      Logger.error('AncillaryController', 'fetchPage Dio: $e\n$st');
      _state.value = CurrentAppState.ERROR;
      _error.value = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e, st) {
      Logger.error('AncillaryController', 'fetchPage: $e\n$st');
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<void> fetchAllPages() async {
    _state.value = CurrentAppState.LOADING;
    _error.value = '';

    try {
      for (final key in pageKeys) {
        await fetchPage(key);
      }
      _state.value = CurrentAppState.SUCCESS;
    } catch (e) {
      _state.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<bool> updatePage({
    required String pageKey,
    required String title,
    required String content,
  }) async {
    _updateState.value = CurrentAppState.LOADING;

    try {
      final response = await httpClient.put(
        '/api/v1/ancillary/update-page/$pageKey',
        data: {
          'title': title,
          'content': content,
        },
        options: Options(
          extra: {'requiresAuth': true},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data['success'] != false) {
        _pages[pageKey] = AncillaryPageModel(title: title, content: content);
        _updateState.value = CurrentAppState.SUCCESS;
        Get.snackbar('Success', '${pageLabels[pageKey] ?? pageKey} updated');
        return true;
      } else {
        _updateState.value = CurrentAppState.ERROR;
        _error.value = response.data?['message'] ?? 'Failed to update page';
        Get.snackbar('Error', _error.value);
        return false;
      }
    } on DioException catch (e, st) {
      Logger.error('AncillaryController', 'updatePage Dio: $e\n$st');
      _updateState.value = CurrentAppState.ERROR;
      _error.value = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
      Get.snackbar('Error', _error.value);
      return false;
    } catch (e, st) {
      Logger.error('AncillaryController', 'updatePage: $e\n$st');
      _updateState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      Get.snackbar('Error', _error.value);
      return false;
    }
  }

  void resetUpdateState() {
    _updateState.value = CurrentAppState.INITIAL;
  }
}
