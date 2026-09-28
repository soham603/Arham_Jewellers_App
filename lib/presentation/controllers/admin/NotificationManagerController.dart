import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/data/repositories/notification_repository.dart';
import 'package:ratnesh_gold_app/data/repositories/product_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/userSearchModel.dart';
import 'package:ratnesh_gold_app/domain/entities/category_model.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/domain/entities/sent_notification_model.dart';
import 'package:ratnesh_gold_app/presentation/controllers/CategoryController.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class NotificationManagerController extends GetxController {
  static NotificationManagerController get instance => Get.find();

  final _notificationRepo = NotificationRepository();
  final _productRepo = ProductRepository();

  final _title = ''.obs;
  String get title => _title.value;

  final _body = ''.obs;
  String get body => _body.value;

  final _imagePath = RxnString();
  String? get imagePath => _imagePath.value;

  bool get hasImage => _imagePath.value != null;

  final _targetType = 'all'.obs;
  String get targetType => _targetType.value;

  final _linkType = 'none'.obs;
  String get linkType => _linkType.value;

  final _linkProduct = Rxn<ProductModel>();
  ProductModel? get linkProduct => _linkProduct.value;

  final _linkCategory = Rxn<CategoryModel>();
  CategoryModel? get linkCategory => _linkCategory.value;

  final _productResults = <ProductModel>[].obs;
  List<ProductModel> get productResults => _productResults;

  final _productSearchState = CurrentAppState.INITIAL.obs;
  CurrentAppState get productSearchState => _productSearchState.value;

  final _selectedUsers = <UserSearchModel>[].obs;
  List<UserSearchModel> get selectedUsers => _selectedUsers;
  List<String> get selectedUserIds =>
      _selectedUsers.map((user) => user.id).toList();

  final _searchQuery = ''.obs;
  String get searchQuery => _searchQuery.value;

  final _searchResults = <UserSearchModel>[].obs;
  List<UserSearchModel> get searchResults => _searchResults;

  final _searchState = CurrentAppState.INITIAL.obs;
  CurrentAppState get searchState => _searchState.value;

  final _searchError = ''.obs;
  String get searchError => _searchError.value;

  final _sendState = CurrentAppState.INITIAL.obs;
  CurrentAppState get sendState => _sendState.value;

  final _history = <SentNotification>[].obs;
  List<SentNotification> get history => _history;

  final _historyState = CurrentAppState.INITIAL.obs;
  CurrentAppState get historyState => _historyState.value;

  final _error = ''.obs;
  String get error => _error.value;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  static const int _pageLimit = 20;

  Timer? _debounce;
  Timer? _productDebounce;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _productDebounce?.cancel();
    super.onClose();
  }

  void setTitle(String value) => _title.value = value;
  void setBody(String value) => _body.value = value;

  void setImage(String? path) => _imagePath.value = path;
  void clearImage() => _imagePath.value = null;

  void setTargetType(String value) {
    if (_targetType.value == value) return;
    _targetType.value = value;
    if (value == 'all') {
      _selectedUsers.clear();
    }
    _searchQuery.value = '';
    _searchResults.clear();
    _searchState.value = CurrentAppState.INITIAL;
  }

  void setLinkType(String value) {
    if (_linkType.value == value) return;
    _linkType.value = value;

    if (value != 'product') {
      _productResults.clear();
      _productSearchState.value = CurrentAppState.INITIAL;
      _linkProduct.value = null;
    }
    if (value != 'category') {
      _linkCategory.value = null;
    }
  }

  void selectLinkProduct(ProductModel product) {
    _linkProduct.value = product;
    _linkCategory.value = null;
  }

  bool isLinkProductSelected(String productId) =>
      _linkProduct.value?.id == productId;

  void selectLinkCategory(CategoryModel category) {
    _linkCategory.value = category;
    _linkProduct.value = null;
  }

  void clearLinkProduct() => _linkProduct.value = null;
  void clearLinkCategory() => _linkCategory.value = null;

  void onProductSearchChanged(String query) {
    _productDebounce?.cancel();

    if (query.trim().isEmpty) {
      _productResults.clear();
      _productSearchState.value = CurrentAppState.INITIAL;
      return;
    }

    _productDebounce = Timer(const Duration(milliseconds: 350), () {
      searchLinkProducts(query.trim());
    });
  }

  Future<void> searchLinkProducts(String query) async {
    _productSearchState.value = CurrentAppState.LOADING;
    try {
      final result = await _productRepo.searchProducts(query: query);
      if (_linkType.value != 'product') return;
      _productResults.value = result.items;
      _productSearchState.value = CurrentAppState.SUCCESS;
    } catch (e) {
      if (_linkType.value != 'product') return;
      _productResults.clear();
      _productSearchState.value = CurrentAppState.ERROR;
    }
  }

  Future<List<CategoryModel>> loadLevel3Categories() async {
    if (!Get.isRegistered<CategoryController>()) return const [];
    final categoryController = Get.find<CategoryController>();
    if (categoryController.allLevel3Categories.isNotEmpty) {
      return categoryController.allLevel3Categories;
    }
    try {
      await categoryController.fetchCategoryTree();
    } catch (_) {}
    return categoryController.allLevel3Categories;
  }

  String? get selectedLinkId {
    if (_linkType.value == 'product') return _linkProduct.value?.id;
    if (_linkType.value == 'category') return _linkCategory.value?.id;
    return null;
  }

  bool isUserSelected(String userId) =>
      _selectedUsers.any((user) => user.id == userId);

  void toggleUser(UserSearchModel user) {
    final index = _selectedUsers.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      _selectedUsers.add(user);
    } else {
      _selectedUsers.removeAt(index);
    }
  }

  void removeUser(String userId) {
    _selectedUsers.removeWhere((user) => user.id == userId);
  }

  void onSearchChanged(String query) {
    _searchQuery.value = query;
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _searchResults.clear();
      _searchState.value = CurrentAppState.INITIAL;
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      searchUsers(query.trim());
    });
  }

  Future<void> searchUsers(String query) async {
    _searchState.value = CurrentAppState.LOADING;
    _searchError.value = '';

    try {
      final hasDigits = RegExp(r'\d').hasMatch(query);
      final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(query);
      final queryParams = <String, dynamic>{
        if (hasDigits && !hasLetters) 'phoneNumber': query else 'name': query,
        'limit': 20,
      };

      final result = await _notificationRepo.searchEligibleUsers(
        queryParams: queryParams,
      );

      _searchResults.value = result.items;
      _searchState.value = CurrentAppState.SUCCESS;
    } on ApiException catch (e) {
      _searchState.value = CurrentAppState.ERROR;
      _searchError.value = e.message;
      _searchResults.clear();
    } catch (e) {
      _searchState.value = CurrentAppState.ERROR;
      _searchError.value = e.toString();
      _searchResults.clear();
    }
  }

  Future<bool> sendNotification() async {
    if (_title.value.trim().isEmpty) {
      ToastUtils.showWarning('Please enter a notification title');
      return false;
    }
    if (_body.value.trim().isEmpty) {
      ToastUtils.showWarning('Please enter a notification body');
      return false;
    }
    if (_targetType.value == 'users' && _selectedUsers.isEmpty) {
      ToastUtils.showWarning('Please select at least one user');
      return false;
    }
    if (_linkType.value != 'none' &&
        (selectedLinkId == null || selectedLinkId!.isEmpty)) {
      ToastUtils.showWarning(
        _linkType.value == 'product'
            ? 'Please select a product to link'
            : 'Please select a category to link',
      );
      return false;
    }

    _sendState.value = CurrentAppState.LOADING;

    try {
      String? imageUrl;
      if (_imagePath.value != null) {
        imageUrl = await _notificationRepo.uploadNotificationImage(
          filePath: _imagePath.value!,
        );
        if (imageUrl == null || imageUrl.isEmpty) {
          _sendState.value = CurrentAppState.ERROR;
          ToastUtils.showError('Failed to upload image');
          return false;
        }
      }

      final data = <String, dynamic>{
        'title': _title.value.trim(),
        'message': _body.value.trim(),
        'targetType': _targetType.value,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      };

      if (_targetType.value == 'users') {
        data['userIds'] = selectedUserIds;
      }

      if (_linkType.value != 'none' && selectedLinkId != null) {
        data['linkType'] = _linkType.value;
        data['linkId'] = selectedLinkId;
      }

      final response = await _notificationRepo.sendNotification(data: data);

      if (response['code'] != 'ERROR' && response['success'] != false) {
        _sendState.value = CurrentAppState.SUCCESS;

        final resultMessage =
            response['message']?.toString() ?? 'Notification sent successfully';
        final rawData = response['data'];
        final push = rawData is Map ? rawData['push'] : null;
        final pushMode = push is Map ? push['mode']?.toString() : null;
        final failureCount = push is Map && push['failureCount'] is num
            ? (push['failureCount'] as num).toInt()
            : 0;

        if (pushMode == 'failed') {
          ToastUtils.showError(resultMessage);
        } else if (pushMode == 'multicast' && failureCount > 0) {
          ToastUtils.showWarning(resultMessage);
        } else {
          ToastUtils.showSuccess(resultMessage);
        }

        _clearForm();
        _page = 1;
        _hasMore = true;
        await fetchHistory();
        return true;
      }

      final message =
          response['error']?['message'] ??
          response['message'] ??
          'Failed to send notification';

      _sendState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } on ApiException catch (e) {
      _sendState.value = CurrentAppState.ERROR;
      _error.value = e.message;
      ToastUtils.showError(e.message);
      return false;
    } on DioException catch (e) {
      String message = 'Something went wrong';
      if (e.response?.data is Map) {
        final data = e.response!.data;
        message =
            data['error']?['message'] ??
            data['message'] ??
            e.message ??
            'Something went wrong';
      } else {
        message = e.message ?? 'Something went wrong';
      }

      _sendState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } catch (e) {
      _sendState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      ToastUtils.showError(e.toString());
      return false;
    }
  }

  Future<void> fetchHistory({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;

    _historyState.value = CurrentAppState.LOADING;
    if (!isPagination) {
      _page = 1;
      _hasMore = true;
    }

    try {
      final queryParams = <String, dynamic>{'page': _page, 'limit': _pageLimit};

      final result = await _notificationRepo.getNotificationHistory(
        queryParams: queryParams,
      );

      if (isPagination) {
        _history.addAll(result.items);
      } else {
        _history.assignAll(result.items);
      }

      if (result.items.length < _pageLimit) {
        _hasMore = false;
      } else {
        _page++;
      }

      _historyState.value = CurrentAppState.SUCCESS;
    } on ApiException catch (e) {
      _historyState.value = CurrentAppState.ERROR;
      _error.value = e.message;
    } on DioException catch (e) {
      _historyState.value = CurrentAppState.ERROR;
      _error.value =
          e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e) {
      _historyState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _historyState.value == CurrentAppState.LOADING) return;
    await fetchHistory(isPagination: true);
  }

  Future<void> refreshHistory() async {
    _page = 1;
    _hasMore = true;
    await fetchHistory();
  }

  void _clearForm() {
    _title.value = '';
    _body.value = '';
    _imagePath.value = null;
    _targetType.value = 'all';
    _selectedUsers.clear();
    _searchQuery.value = '';
    _searchResults.clear();
    _searchState.value = CurrentAppState.INITIAL;
    _linkType.value = 'none';
    _linkProduct.value = null;
    _linkCategory.value = null;
    _productResults.clear();
    _productSearchState.value = CurrentAppState.INITIAL;
  }
}
