import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:ratnesh_gold_app/domain/entities/carousel_model.dart';
import 'package:ratnesh_gold_app/domain/entities/productModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class CarouselsController extends GetxController {
  static CarouselsController get instance => Get.find();

  final _getCarouselState = CurrentAppState.INITIAL.obs;
  CurrentAppState get getCarouselState => _getCarouselState.value;

  final RxList<CarouselModel> _list = <CarouselModel>[].obs;
  List<CarouselModel> get list => _list;

  final _adminState = CurrentAppState.INITIAL.obs;
  CurrentAppState get adminState => _adminState.value;

  final RxList<CarouselModel> _adminList = <CarouselModel>[].obs;
  List<CarouselModel> get adminList => _adminList;

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

  final _error = ''.obs;
  String get error => _error.value;

  int _productPage = 1;
  final int _productLimit = 10;

  @override
  void onInit() {
    super.onInit();
    getAllCarousels();
    loadLatestProducts();
  }

  Future<void> getAllCarousels() async {
    try {
      _getCarouselState.value = CurrentAppState.LOADING;

      final response = await httpClient.get("/api/v1/carousel/get-All");

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];

        _list.value = (data as List)
            .map((e) => CarouselModel.fromJson(e))
            .toList();

        _getCarouselState.value = CurrentAppState.SUCCESS;
      } else {
        _getCarouselState.value = CurrentAppState.ERROR;
      }
    } catch (e) {
      _getCarouselState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "CarouselsController",
        "getAllCarousels: $e",
      );
    }
  }

  Future<void> fetchAdminCarousels() async {
    try {
      _adminState.value = CurrentAppState.LOADING;

      final response = await httpClient.get(
        "/api/v1/carousel/get-All",
        queryParameters: {
          "showAll": true,
        },
        options: Options(
          extra: {
            "requiresAuth": true,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];

        _adminList.value = (data as List)
            .map((e) => CarouselModel.fromJson(e))
            .toList();

        _adminState.value = CurrentAppState.SUCCESS;
      } else {
        _adminState.value = CurrentAppState.ERROR;
      }
    } catch (e) {
      _adminState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "CarouselsController",
        "fetchAdminCarousels: $e",
      );
    }
  }

  Future<void> fetchDeletedCarousels() async {
    try {
      _deletedState.value = CurrentAppState.LOADING;

      final response = await httpClient.get(
        "/api/v1/carousel/get-All",
        queryParameters: {
          "showDeleted": true,
        },
        options: Options(
          extra: {
            "requiresAuth": true,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];

        _deletedList.value = (data as List)
            .map((e) => CarouselModel.fromJson(e))
            .toList();

        _deletedState.value = CurrentAppState.SUCCESS;
      } else {
        _deletedState.value = CurrentAppState.ERROR;
      }
    } catch (e) {
      _deletedState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "CarouselsController",
        "fetchDeletedCarousels: $e",
      );
    }
  }

  Future<bool> createCarousel({
    String? title,
    String? description,
    String? descHtml,
    String? linkUrl,
    String? mobileImageUrl,
    required File imageFile,
  }) async {
    try {
      _createState.value = CurrentAppState.LOADING;
      _error.value = '';

      final Map<String, dynamic> map = {
        if (title != null) "title": title,
        if (description != null) "description": description,
        if (descHtml != null) "descHtml": descHtml,
        if (linkUrl != null) "linkUrl": linkUrl,
        if (mobileImageUrl != null)
          "mobileImageUrl": mobileImageUrl,
        "image": await MultipartFile.fromFile(imageFile.path),
      };

      final response = await httpClient.post(
        "/api/v1/carousel/create",
        data: FormData.fromMap(map),
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
          extra: {
            "requiresAuth": true,
          },
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final newItem = CarouselModel.fromJson(
          response.data['data'],
        );

        _adminList.insert(0, newItem);

        _createState.value = CurrentAppState.SUCCESS;

        return true;
      }

      _createState.value = CurrentAppState.ERROR;
      _error.value =
          response.data['message'] ?? 'Create failed';
    } catch (e) {
      _createState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "CarouselsController",
        "createCarousel: $e",
      );
    }

    return false;
  }

  Future<bool> editCarousel({
    required String id,
    String? title,
    String? description,
    String? descHtml,
    String? linkUrl,
    String? mobileImageUrl,
    int? position,
    bool? isActive,
    File? imageFile,
  }) async {
    try {
      _editState.value = CurrentAppState.LOADING;
      _error.value = '';

      final Map<String, dynamic> map = {
        if (title != null) "title": title,
        if (description != null) "description": description,
        if (descHtml != null) "descHtml": descHtml,
        if (linkUrl != null) "linkUrl": linkUrl,
        if (mobileImageUrl != null)
          "mobileImageUrl": mobileImageUrl,
        if (position != null) "position": position,
        if (isActive != null) "isActive": isActive,
      };

      if (imageFile != null) {
        map["image"] = await MultipartFile.fromFile(
          imageFile.path,
        );
      }

      final response = await httpClient.put(
        "/api/v1/carousel/edit/$id",
        data: FormData.fromMap(map),
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
          extra: {
            "requiresAuth": true,
          },
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final updated = CarouselModel.fromJson(
          response.data['data'],
        );

        final index = _adminList.indexWhere(
          (e) => e.id == id,
        );

        if (index != -1) {
          _adminList[index] = updated;
          _adminList.refresh();
        }

        _editState.value = CurrentAppState.SUCCESS;

        return true;
      }

      _editState.value = CurrentAppState.ERROR;
      _error.value =
          response.data['message'] ?? 'Edit failed';
    } catch (e) {
      _editState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "CarouselsController",
        "editCarousel: $e",
      );
    }

    return false;
  }

  Future<bool> deleteCarousel(String id) async {
    try {
      _deleteState.value = CurrentAppState.LOADING;
      _error.value = '';

      final response = await httpClient.delete(
        "/api/v1/carousel/delete/$id",
        options: Options(
          extra: {
            "requiresAuth": true,
          },
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final removed = _adminList.firstWhereOrNull(
          (e) => e.id == id,
        );

        _adminList.removeWhere((e) => e.id == id);

        if (removed != null) {
          _deletedList.insert(0, removed);
        }

        _deleteState.value = CurrentAppState.SUCCESS;

        return true;
      }

      _deleteState.value = CurrentAppState.ERROR;
      _error.value =
          response.data['message'] ?? 'Delete failed';
    } catch (e) {
      _deleteState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "CarouselsController",
        "deleteCarousel: $e",
      );
    }

    return false;
  }

  Future<bool> restoreCarousel(String id) async {
    try {
      _restoreState.value = CurrentAppState.LOADING;
      _error.value = '';

      final response = await httpClient.patch(
        "/api/v1/carousel/restore/$id",
        options: Options(
          extra: {
            "requiresAuth": true,
          },
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final restored = CarouselModel.fromJson(
          response.data['data'],
        );

        _deletedList.removeWhere((e) => e.id == id);

        _adminList.insert(0, restored);

        _restoreState.value = CurrentAppState.SUCCESS;

        return true;
      }

      _restoreState.value = CurrentAppState.ERROR;
      _error.value =
          response.data['message'] ?? 'Restore failed';
    } catch (e) {
      _restoreState.value = CurrentAppState.ERROR;
      _error.value = e.toString();

      Logger.error(
        "CarouselsController",
        "restoreCarousel: $e",
      );
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

    final item = _adminList.removeAt(oldIndex);

    _adminList.insert(
      (newPosition - 1).clamp(0, _adminList.length),
      item,
    );

    _adminList.refresh();

    await editCarousel(
      id: id,
      position: newPosition,
    );
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

      final response = await httpClient.get(
        "/api/v1/products/get-all",
        queryParameters: {
          "page": _productPage,
          "limit": _productLimit,
          "showReverse": true,
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        final responseData = response.data['data'];

        final List raw =
            responseData['data'] is List
                ? responseData['data']
                : [];

        final fetched = raw
            .map((e) => ProductModel.fromJson(e))
            .toList();

        if (isPagination) {
          _latestProducts.addAll(fetched);
        } else {
          _latestProducts.value = fetched;
        }

        final totalPages =
            responseData['totalPages'] ?? 1;

        if (_productPage >= totalPages ||
            fetched.length < _productLimit) {
          _productHasMore.value = false;
        } else {
          _productPage++;
        }

        _productState.value = CurrentAppState.SUCCESS;
      } else {
        _productState.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      _productState.value = CurrentAppState.ERROR;

      Logger.error(
        "CarouselsController",
        "loadLatestProducts error: $e\n$st",
      );
    } finally {
      _productLoadingMore.value = false;
    }
  }
}