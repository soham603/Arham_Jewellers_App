import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/domain/entities/customOrderModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class CustomOrderController extends GetxController {
  static CustomOrderController get instance => Get.find();

  static const int _pageLimit = 10;

  // ── Create state ──
  final _createState = CurrentAppState.INITIAL.obs;
  CurrentAppState get createState => _createState.value;

  final _isCreating = false.obs;
  bool get isCreating => _isCreating.value;

  final _createdOrderId = ''.obs;
  String get createdOrderId => _createdOrderId.value;

  // ── Modify state ──
  final _modifyState = CurrentAppState.INITIAL.obs;
  CurrentAppState get modifyState => _modifyState.value;

  final _isModifying = false.obs;
  bool get isModifying => _isModifying.value;

  // ── Delete state ──
  final _isDeleting = false.obs;
  bool get isDeleting => _isDeleting.value;

  // ── Fetch state ──
  final _fetchState = CurrentAppState.INITIAL.obs;
  CurrentAppState get fetchState => _fetchState.value;

  final _isFetching = false.obs;
  bool get isFetching => _isFetching.value;

  final _userCustomOrders = <CustomOrderModel>[].obs;
  List<CustomOrderModel> get userCustomOrders => _userCustomOrders;

  final _hasMore = true.obs;
  bool get hasMore => _hasMore.value;

  final _totalOrders = 0.obs;
  int get totalOrders => _totalOrders.value;

  int _page = 1;

  // ── Selected order for detail view ──
  final _selectedOrder = Rxn<CustomOrderModel>();
  CustomOrderModel? get selectedOrder => _selectedOrder.value;

  @override
  void onInit() {
    super.onInit();
    fetchUserCustomOrders();
  }

  // =====================================================
  // CREATE CUSTOM ORDER
  // =====================================================

  Future<bool> createCustomOrder({
    required String partyCode,
    required String partyName,
    String? area,
    required String contactNumber,
    required String itemName,
    String? weight,
    String? noOfPieces,
    String? size,
    String? lengthBroadness,
    String? productDescription,
    required String purity,
    required String style,
    required String marking,
    List<File>? images,
  }) async {
    if (_isCreating.value) return false;

    try {
      _isCreating.value = true;
      _createState.value = CurrentAppState.LOADING;

      final formData = FormData.fromMap({
        'partyCode': partyCode,
        'partyName': partyName,
        if (area != null && area.isNotEmpty) 'area': area,
        'contactNumber': contactNumber,
        'itemName': itemName,
        if (weight != null && weight.isNotEmpty) 'weight': weight,
        if (noOfPieces != null && noOfPieces.isNotEmpty)
          'noOfPieces': noOfPieces,
        if (size != null && size.isNotEmpty) 'size': size,
        if (lengthBroadness != null && lengthBroadness.isNotEmpty)
          'lengthBroadness': lengthBroadness,
        if (productDescription != null && productDescription.isNotEmpty)
          'productDescription': productDescription,
        'purity': purity,
        'style': style,
        'marking': marking,
          if (images != null && images.isNotEmpty)
          'referenceImages': [
            for (final img in images)
              await MultipartFile.fromFile(img.path,
                  filename: img.path.split('/').last),
          ],
      });

      Logger.info("CustomOrderController", "Creating custom order...");

      final response = await httpClient.post(
        ApiUrlConstants.CUSTOM_ORDER_CREATE,
        data: formData,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? {};
        _createdOrderId.value = data['orderId']?.toString() ?? '';
        _createState.value = CurrentAppState.SUCCESS;

        Logger.info("CustomOrderController",
            "Custom order created: ${_createdOrderId.value}");

        await fetchUserCustomOrders();

        return true;
      }

      _createState.value = CurrentAppState.ERROR;
      Get.snackbar(
        "Failed",
        response.data?['message'] ?? "Failed to create custom order",
      );
      return false;
    } catch (e, st) {
      _createState.value = CurrentAppState.ERROR;
      Logger.error("CustomOrderController", "createCustomOrder error: $e\n$st");

      String errorMessage = "Failed to create custom order";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.message ?? errorMessage;
      }

      Get.snackbar("Failed", errorMessage);
      return false;
    } finally {
      _isCreating.value = false;
    }
  }

  // =====================================================
  // MODIFY CUSTOM ORDER
  // =====================================================

  Future<bool> modifyCustomOrder({
    required String orderId,
    String? partyCode,
    String? partyName,
    String? area,
    String? contactNumber,
    String? itemName,
    String? weight,
    String? noOfPieces,
    String? size,
    String? lengthBroadness,
    String? productDescription,
    String? purity,
    String? style,
    String? marking,
    List<File>? newImages,
    bool removeOldImages = false,
  }) async {
    if (_isModifying.value) return false;

    try {
      _isModifying.value = true;
      _modifyState.value = CurrentAppState.LOADING;

      final map = <String, dynamic>{
        if (partyCode != null) 'partyCode': partyCode,
        if (partyName != null) 'partyName': partyName,
        if (area != null) 'area': area,
        if (contactNumber != null) 'contactNumber': contactNumber,
        if (itemName != null) 'itemName': itemName,
        if (weight != null) 'weight': weight,
        if (noOfPieces != null) 'noOfPieces': noOfPieces,
        if (size != null) 'size': size,
        if (lengthBroadness != null) 'lengthBroadness': lengthBroadness,
        if (productDescription != null) 'productDescription': productDescription,
        if (purity != null) 'purity': purity,
        if (style != null) 'style': style,
        if (marking != null) 'marking': marking,
        'removeOldImages': removeOldImages,
      };

      if (newImages != null && newImages.isNotEmpty) {
        map['images'] = [
          for (final img in newImages)
            await MultipartFile.fromFile(img.path,
                filename: img.path.split('/').last),
        ];
      }

      final formData = FormData.fromMap(map);

      final response = await httpClient.patch(
        ApiUrlConstants.customOrderModify(orderId),
        data: formData,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _modifyState.value = CurrentAppState.SUCCESS;

        Logger.info("CustomOrderController", "Custom order modified: $orderId");

        await fetchUserCustomOrders();

        if (_selectedOrder.value?.id == orderId) {
          await fetchOrderDetail(orderId);
        }

        return true;
      }

      _modifyState.value = CurrentAppState.ERROR;
      Get.snackbar(
        "Failed",
        response.data?['message'] ?? "Failed to update custom order",
      );
      return false;
    } catch (e, st) {
      _modifyState.value = CurrentAppState.ERROR;
      Logger.error("CustomOrderController", "modifyCustomOrder error: $e\n$st");

      String errorMessage = "Failed to update custom order";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.message ?? errorMessage;
      }

      Get.snackbar("Failed", errorMessage);
      return false;
    } finally {
      _isModifying.value = false;
    }
  }

  // =====================================================
  // DELETE CUSTOM ORDER
  // =====================================================

  Future<bool> deleteCustomOrder(String orderId) async {
    if (_isDeleting.value) return false;

    try {
      _isDeleting.value = true;

      final response = await httpClient.delete(
        ApiUrlConstants.customOrderDelete(orderId),
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _userCustomOrders.removeWhere((o) => o.id == orderId);

        Get.snackbar(
          "Deleted",
          "Custom order deleted successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF2D9D59),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        Logger.info("CustomOrderController", "Custom order deleted: $orderId");
        return true;
      }

      Get.snackbar(
        "Failed",
        response.data?['message'] ?? "Failed to delete custom order",
      );
      return false;
    } catch (e, st) {
      Logger.error("CustomOrderController", "deleteCustomOrder error: $e\n$st");

      String errorMessage = "Failed to delete custom order";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.message ?? errorMessage;
      }

      Get.snackbar("Failed", errorMessage);
      return false;
    } finally {
      _isDeleting.value = false;
    }
  }

  // =====================================================
  // FETCH USER CUSTOM ORDERS
  // =====================================================

  Future<void> fetchUserCustomOrders({bool isPagination = false}) async {
    if (_isFetching.value) return;
    if (!_hasMore.value && isPagination) return;

    try {
      _isFetching.value = true;

      if (!isPagination) {
        _fetchState.value = CurrentAppState.LOADING;
        _page = 1;
        _hasMore.value = true;
        _userCustomOrders.clear();
      }

      final response = await httpClient.get(
        ApiUrlConstants.CUSTOM_ORDER_USER_ALL,
        queryParameters: {"page": _page, "limit": _pageLimit},
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? {};
        final List raw = data['orders'] is List ? data['orders'] : [];

        final fetched = raw
            .map((e) => CustomOrderModel.fromJson(e))
            .toList();

        if (isPagination) {
          _userCustomOrders.addAll(fetched);
        } else {
          _userCustomOrders.value = fetched;
        }

        _totalOrders.value = data['total'] ?? 0;

        if (fetched.length < _pageLimit) {
          _hasMore.value = false;
        } else {
          _page++;
        }

        _fetchState.value = CurrentAppState.SUCCESS;
      } else {
        _fetchState.value = CurrentAppState.ERROR;
      }
    } catch (e, st) {
      Logger.error("CustomOrderController", "fetchUserCustomOrders error: $e\n$st");
      _fetchState.value = CurrentAppState.ERROR;
    } finally {
      _isFetching.value = false;
    }
  }

  Future<void> loadMoreOrders() async {
    if (_isFetching.value || !_hasMore.value) return;
    await fetchUserCustomOrders(isPagination: true);
  }

  Future<void> refreshOrders() async {
    _page = 1;
    _hasMore.value = true;
    _userCustomOrders.clear();
    await fetchUserCustomOrders();
  }

  // =====================================================
  // FETCH SINGLE ORDER DETAIL
  // =====================================================

  Future<void> fetchOrderDetail(String orderId) async {
    try {
      final response = await httpClient.get(
        '/api/v1/orders/custom-order/$orderId',
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data != null) {
          _selectedOrder.value = CustomOrderModel.fromJson(data);
        }
      }
    } catch (e) {
      Logger.error("CustomOrderController", "fetchOrderDetail error: $e");
    }
  }

  // =====================================================
  // RESET
  // =====================================================

  void resetCreateState() {
    _createState.value = CurrentAppState.INITIAL;
    _isCreating.value = false;
    _createdOrderId.value = '';
  }

  void resetModifyState() {
    _modifyState.value = CurrentAppState.INITIAL;
    _isModifying.value = false;
  }
}
