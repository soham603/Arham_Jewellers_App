import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData, Response;
import 'package:ratnesh_gold_app/data/repositories/carousel_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/carousel_model.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class CarouselsController extends GetxController {
  static CarouselsController get instance => Get.find();

  final _carouselRepo = CarouselRepository();

  final _getCarouselState = CurrentAppState.INITIAL.obs;
  CurrentAppState get getCarouselState => _getCarouselState.value;

  final RxList<CarouselModel> _list = <CarouselModel>[].obs;
  List<CarouselModel> get list => _list;

  final _adminState = CurrentAppState.INITIAL.obs;
  CurrentAppState get adminState => _adminState.value;

  final RxList<CarouselModel> _adminList = <CarouselModel>[].obs;
  List<CarouselModel> get adminList => _adminList;
  RxList<CarouselModel> get adminListRx => _adminList;

  final _deletedState = CurrentAppState.INITIAL.obs;
  CurrentAppState get deletedState => _deletedState.value;

  final RxList<CarouselModel> _deletedList = <CarouselModel>[].obs;
  List<CarouselModel> get deletedList => _deletedList;

  final _createState = CurrentAppState.INITIAL.obs;
  CurrentAppState get createState => _createState.value;

  final _editState = CurrentAppState.INITIAL.obs;
  CurrentAppState get editState => _editState.value;

  final _deleteState = CurrentAppState.INITIAL.obs;
  CurrentAppState get deleteState => _deleteState.value;

  final _restoreState = CurrentAppState.INITIAL.obs;
  CurrentAppState get restoreState => _restoreState.value;

  final _productState = CurrentAppState.INITIAL.obs;
  CurrentAppState get productState => _productState.value;

  final RxBool _productLoadingMore = false.obs;
  bool get productLoadingMore => _productLoadingMore.value;

  final RxBool _productHasMore = true.obs;
  bool get productHasMore => _productHasMore.value;

  final RxList<ProductModel> _latestProducts = <ProductModel>[].obs;
  List<ProductModel> get latestProducts => _latestProducts;

  final _editLoadingId = RxString('');
  String get editLoadingId => _editLoadingId.value;

  final _deleteLoadingId = RxString('');
  String get deleteLoadingId => _deleteLoadingId.value;

  final _restoreLoadingId = RxString('');
  String get restoreLoadingId => _restoreLoadingId.value;

  final _error = ''.obs;
  String get error => _error.value;

  int _productPage = 1;
  final int _productLimit = 10;
  
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
      getAllCarousels();
      loadLatestProducts();
    }
  }

  @override
  void onClose() {
    _list.clear();
    _adminList.clear();
    _deletedList.clear();
    _latestProducts.clear();
    super.onClose();
  }

  Future<void> getAllCarousels() async {
    try {
      _getCarouselState.value = CurrentAppState.LOADING;

      _list.value = await _carouselRepo.fetchCarousels();

      _getCarouselState.value = CurrentAppState.SUCCESS;
    } catch (e) {
      _getCarouselState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

    }
  }

  Future<void> fetchAdminCarousels() async {
    try {
      _adminState.value = CurrentAppState.LOADING;

      _adminList.value = await _carouselRepo.fetchCarousels(
        queryParams: {"showAll": true},
      );

      _adminState.value = CurrentAppState.SUCCESS;
    } catch (e) {
      _adminState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

    }
  }

  Future<void> fetchDeletedCarousels() async {
    try {
      _deletedState.value = CurrentAppState.LOADING;

      _deletedList.value = await _carouselRepo.fetchCarousels(
        queryParams: {"showDeleted": true},
      );

      _deletedState.value = CurrentAppState.SUCCESS;
    } catch (e) {
      _deletedState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

    }
  }

  Future<bool> createCarousel({
    String? title,
    String? description,
    String? linkUrl,
    String? mobileImageUrl,
    bool? isActive,
    required File imageFile,
  }) async {
    try {
      _createState.value = CurrentAppState.LOADING;
      _error.value = '';

      final Map<String, dynamic> map = {
        "title": ?title,
        "description": ?description,
        "linkUrl": ?linkUrl,
        "mobileImageUrl": ?mobileImageUrl,
        "image": await MultipartFile.fromFile(imageFile.path),
      };

      final responseData = await _carouselRepo.createCarousel(
        data: FormData.fromMap(map),
      );

      final newItem = CarouselModel.fromJson(responseData['data']);

      _adminList.insert(0, newItem);

      _createState.value = CurrentAppState.SUCCESS;

      return true;
    } catch (e) {
      _createState.value = CurrentAppState.ERROR;
      if (e is DioException) {
        _error.value =
            e.response?.data?['message']?.toString() ??
            e.error?.toString() ??
            e.message ??
            'Create failed';
      } else {
        _error.value = 'Create failed';
      }

    }

    return false;
  }

  Future<bool> editCarousel({
    required String id,
    String? title,
    String? description,
    String? linkUrl,
    String? mobileImageUrl,
    int? position,
    bool? isActive,
    File? imageFile,
    bool deleteImage = false,
  }) async {
    try {
      _editLoadingId.value = id;
      _editState.value = CurrentAppState.LOADING;
      _error.value = '';

      final Map<String, dynamic> map = {
        "title": ?title,
        "description": ?description,
        "linkUrl": ?linkUrl,
        "mobileImageUrl": ?mobileImageUrl,
        "position": ?position,
        "isActive": ?isActive,
        if (deleteImage) "deleteImage": "true",
      };

      if (imageFile != null) {
        map["image"] = await MultipartFile.fromFile(
          imageFile.path,
        );
      }

      final responseData = await _carouselRepo.editCarousel(
        id: id,
        data: FormData.fromMap(map),
      );

      if (responseData != null && responseData['data'] != null) {
        final updated = CarouselModel.fromJson(responseData['data']);

        var index = _adminList.indexWhere(
          (e) => e.id == id,
        );

        if (index != -1) {
          _adminList[index] = updated;
          _adminList.refresh();
        } else {
          index = _deletedList.indexWhere(
            (e) => e.id == id,
          );
          if (index != -1) {
            _deletedList[index] = updated;
            _deletedList.refresh();
          }
        }
      } else if (isActive != null) {
        var index = _adminList.indexWhere(
          (e) => e.id == id,
        );
        if (index != -1) {
          _adminList[index] = _adminList[index].copyWith(
            isActive: isActive,
          );
          _adminList.refresh();
        } else {
          index = _deletedList.indexWhere(
            (e) => e.id == id,
          );
          if (index != -1) {
            _deletedList[index] = _deletedList[index].copyWith(
              isActive: isActive,
            );
            _deletedList.refresh();
          }
        }
      }

      _editLoadingId.value = '';
      _editState.value = CurrentAppState.SUCCESS;

      return true;
    } catch (e) {
      _editLoadingId.value = '';
      _editState.value = CurrentAppState.ERROR;
      if (e is DioException) {
        _error.value =
            e.response?.data?['message']?.toString() ??
            e.error?.toString() ??
            e.message ??
            'Edit failed';
      } else {
        _error.value = 'Edit failed';
      }

    }

    return false;
  }

  Future<bool> deleteCarousel(String id) async {
    try {
      _deleteLoadingId.value = id;
      _deleteState.value = CurrentAppState.LOADING;
      _error.value = '';

      await _carouselRepo.deleteCarousel(id: id);

      final removed = _adminList.firstWhereOrNull(
        (e) => e.id == id,
      );

      _adminList.removeWhere((e) => e.id == id);

      if (removed != null) {
        _deletedList.insert(0, removed);
      }

      _deleteLoadingId.value = '';
      _deleteState.value = CurrentAppState.SUCCESS;

      return true;
    } catch (e) {
      _deleteLoadingId.value = '';
      _deleteState.value = CurrentAppState.ERROR;
      if (e is DioException) {
        _error.value =
            e.response?.data?['message']?.toString() ??
            e.error?.toString() ??
            e.message ??
            'Delete failed';
      } else {
        _error.value = 'Delete failed';
      }

    }

    return false;
  }

  Future<bool> restoreCarousel(String id) async {
    try {
      _restoreLoadingId.value = id;
      _restoreState.value = CurrentAppState.LOADING;
      _error.value = '';

      final responseData = await _carouselRepo.restoreCarousel(id: id);

      final restored = CarouselModel.fromJson(responseData['data']);

      _deletedList.removeWhere((e) => e.id == id);

      _adminList.insert(0, restored);

      _restoreLoadingId.value = '';
      _restoreState.value = CurrentAppState.SUCCESS;

      return true;
    } catch (e) {
      _restoreLoadingId.value = '';
      _restoreState.value = CurrentAppState.ERROR;
      if (e is DioException) {
        _error.value =
            e.response?.data?['message']?.toString() ??
            e.error?.toString() ??
            e.message ??
            'Restore failed';
      } else {
        _error.value = 'Restore failed';
      }

    }

    return false;
  }

  Future<void> reorderCarousel({
    required String id,
    required int newPosition,
  }) async {
    final oldIndex = _adminList.indexWhere(
      (e) => e.id == id,
    );

    if (oldIndex == -1) return;

    final snapshot = List<CarouselModel>.from(_adminList);
    final item = _adminList.removeAt(oldIndex);

    _adminList.insert(
      (newPosition - 1).clamp(0, _adminList.length),
      item,
    );

    _adminList.refresh();

    final ok = await editCarousel(
      id: id,
      position: newPosition,
    );

    if (!ok) {
      _adminList.value = snapshot;
      _adminList.refresh();
      _error.value = 'Reordering failed. Changes reverted.';
    }
  }

  Future<void> loadLatestProducts({
    bool isPagination = false,
  }) async {
    try {
      if (isPagination) {
        if (!_productHasMore.value) return;
        if (_productLoadingMore.value) return;

        _productLoadingMore.value = true;
      } else {
        _productState.value = CurrentAppState.LOADING;
        _productPage = 1;
        _productHasMore.value = true;
      }

      final result = await _carouselRepo.fetchLatestProducts(
        queryParams: {
          "page": _productPage,
          "limit": _productLimit,
          "showReverse": true,
        },
      );

      if (isPagination) {
        _latestProducts.addAll(result.items);
      } else {
        _latestProducts.value = result.items;
      }

      if (_productPage >= result.totalPages ||
          result.items.length < _productLimit) {
        _productHasMore.value = false;
      } else {
        _productPage++;
      }

      _productState.value = CurrentAppState.SUCCESS;
    } catch (e, st) {
      if (!isPagination) {
        _productState.value = CurrentAppState.ERROR;
      }

    } finally {
      _productLoadingMore.value = false;
    }
  }
}