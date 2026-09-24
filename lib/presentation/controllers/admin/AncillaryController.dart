import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/data/repositories/ancillary_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/ancillary_page_model.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class AncillaryController extends GetxController {
  static AncillaryController get instance => Get.find();

  static const String _fallbackPhone = '+919408451986';
  static String get fallbackPhone => _fallbackPhone;

  final _ancillaryRepo = AncillaryRepository();

  static const List<String> pageKeys = [
    'TERMS',
    'ABOUT',
    'CONTACT',
    'PRIVACY',
    'REFUND',
    'CITY_POLICY',
    'ADMIN_CONTACT',
  ];

  static const Map<String, String> pageLabels = {
    'TERMS': 'Terms & Conditions',
    'ABOUT': 'About Us',
    'CONTACT': 'Contact',
    'PRIVACY': 'Privacy Policy',
    'REFUND': 'Refund Policy',
    'CITY_POLICY': 'City Policy',
    'ADMIN_CONTACT': 'Admin Contact',
  };

  final _pages = <String, AncillaryPageModel>{}.obs;
  Map<String, AncillaryPageModel> get pages => _pages;

  final adminPhone = _fallbackPhone.obs;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _updateState = CurrentAppState.INITIAL.obs;
  CurrentAppState get updateState => _updateState.value;

  final _error = ''.obs;
  String get error => _error.value;

  AncillaryPageModel? getPage(String key) => _pages[key];

  static String _sanitizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    String national;
    if (digits.length == 12 && digits.startsWith('91')) {
      national = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      national = digits.substring(1);
    } else if (digits.length == 10) {
      national = digits;
    } else {
      return '';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(national)) return '';
    return '+91$national';
  }

  Future<void>? _adminContactReady;

  Future<String> get adminPhoneAsync async {
    if (_adminContactReady != null) await _adminContactReady;
    return adminPhone.value;
  }

  @override
  void onInit() {
    super.onInit();
    _adminContactReady = fetchPage('ADMIN_CONTACT');
  }

  Future<void> fetchPage(String pageKey) async {
    try {
      _state.value = CurrentAppState.LOADING;

      final page = await _ancillaryRepo.fetchPage(pageKey: pageKey);
      if (page != null) {
        _pages[pageKey] = page;
        if (pageKey == 'ADMIN_CONTACT') {
          final sanitized = _sanitizePhone(page.content);
          if (sanitized.isNotEmpty) {
            adminPhone.value = sanitized;
          }
        }
      }
      _state.value = CurrentAppState.SUCCESS;
    } on DioException catch (e, st) {
      _state.value = CurrentAppState.ERROR;
      _error.value = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e, st) {
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
      final response = await _ancillaryRepo.updatePage(
        pageKey: pageKey,
        data: {
          'title': title,
          'content': content,
        },
      );

      if (response['success'] != false) {
        _pages[pageKey] = AncillaryPageModel(title: title, content: content);
        _updateState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess('${pageLabels[pageKey] ?? pageKey} updated');
        return true;
      } else {
        _updateState.value = CurrentAppState.ERROR;
        _error.value = response['message'] ?? 'Failed to update page';
        ToastUtils.showError(_error.value);
        return false;
      }
    } on DioException catch (e, st) {
      _updateState.value = CurrentAppState.ERROR;
      _error.value = e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
      ToastUtils.showError(_error.value);
      return false;
    } catch (e, st) {
      _updateState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      ToastUtils.showError(_error.value);
      return false;
    }
  }

  void resetUpdateState() {
    _updateState.value = CurrentAppState.INITIAL;
  }
}
