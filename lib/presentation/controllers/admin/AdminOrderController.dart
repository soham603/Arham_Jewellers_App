import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class AdminOrderController extends GetxController {
  static AdminOrderController get instance => Get.find();

  static const int _pageLimit = 10;

  final _orders = <AdminOrderModel>[].obs;
  List<AdminOrderModel> get orders => _orders;

  final _orderState = CurrentAppState.INITIAL.obs;
  CurrentAppState get orderState => _orderState.value;

  final _isPaginationLoading = false.obs;
  bool get isPaginationLoading => _isPaginationLoading.value;

  final _isActionLoading = false.obs;
  bool get isActionLoading => _isActionLoading.value;

  final RxString selectedStatus = "PENDING".obs;

  final RxString selectedOrderType = "all".obs;

  final searchController = TextEditingController();

  Timer? _debounce;

  int _page = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  final _productRawDataCache = <String, Map<String, dynamic>>{};
  final _isFetchingProductDetails = false.obs;
  bool get isFetchingProductDetails => _isFetchingProductDetails.value;

  Map<String, dynamic>? getProductRawData(String productId) => _productRawDataCache[productId];
  
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    if (!_isInitialized) {
      _isInitialized = true;
      fetchOrders();
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchOrders({bool isPagination = false}) async {
    if (_orderState.value == CurrentAppState.LOADING && !isPagination) {
      return;
    }

    if (!_hasMore && isPagination) {
      return;
    }

    try {
      if (!isPagination) {
        _page = 1;

        _orderState.value = CurrentAppState.LOADING;
      } else {
        _isPaginationLoading.value = true;
      }

      final response = await httpClient.get(
        "/api/v1/admin-order/get-AllOrders",
        queryParameters: {
          "page": _page,
          "limit": _pageLimit,
          "status": selectedStatus.value,
          if (searchController.text.trim().isNotEmpty)
            "userPhoneNumber": "+91${searchController.text.trim()}",
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data["data"];

        final totalPages = data["totalPages"] ?? 1;

        final currentPage = data["page"] ?? 1;

        final List raw = data["results"] ?? [];

        final fetched = raw.map((e) => AdminOrderModel.fromJson(e)).toList();

        final List<AdminOrderModel> filtered;
        if (selectedOrderType.value == "custom") {
          filtered = fetched.where((o) => o.isCustom).toList();
        } else if (selectedOrderType.value == "normal") {
          filtered = fetched.where((o) => !o.isCustom).toList();
        } else {
          filtered = fetched;
        }

        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (isPagination) {
          _orders.addAll(filtered);
        } else {
          _orders.value = filtered;
        }

        _hasMore = currentPage < totalPages;

        if (_hasMore) {
          _page++;
        }

        _orderState.value = CurrentAppState.SUCCESS;
      }
    } catch (e, st) {
      Logger.error("AdminOrderController", "$e\n$st");

      _orderState.value = CurrentAppState.ERROR;
    } finally {
      _isPaginationLoading.value = false;
    }
  }

  Future<void> fetchProductDetails(List<AdminOrderItemModel> items) async {
    final uncached = <String, String>{};
    for (final item in items) {
      final id = item.product.id;
      if (!_productRawDataCache.containsKey(id) && !uncached.containsKey(id)) {
        uncached[id] = item.product.name;
      }
    }
    if (uncached.isEmpty) return;

    _isFetchingProductDetails.value = true;
    try {
      final futures = uncached.entries.map((entry) async {
        try {
          final response = await httpClient.get(
            "/api/v1/products/search",
            queryParameters: {
              "search": entry.value,
              "page": 1,
              "limit": 10,
              "showAll": true,
            },
          );
          if (response.statusCode == 200 || response.statusCode == 201) {
            final List raw = response.data['data']['data'] ?? [];
            final match = raw.cast<Map<String, dynamic>?>().firstWhere(
                  (p) => p?['id'] == entry.key,
                  orElse: () => raw.isNotEmpty ? raw.first as Map<String, dynamic>? : null,
                );
            if (match != null && match['rawData'] != null) {
              _productRawDataCache[entry.key] = Map<String, dynamic>.from(match['rawData']);
            }
          }
        } catch (e) {
          Logger.error("AdminOrderController", "Product detail fetch failed for ${entry.key}: $e");
        }
      });
      await Future.wait(futures);
    } finally {
      _isFetchingProductDetails.value = false;
    }
  }

  void changeStatus(String value) {
    if (selectedStatus.value == value) {
      return;
    }

    selectedStatus.value = value;

    _orders.clear();

    _page = 1;

    _hasMore = true;

    fetchOrders();
  }

  void changeOrderType(String value) {
    if (selectedOrderType.value == value) return;
    selectedOrderType.value = value;
    _orders.clear();
    _page = 1;
    _hasMore = true;
    fetchOrders();
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      _page = 1;

      _hasMore = true;

      _orders.clear();

      fetchOrders();
    });
  }

  Future<void> performOrderAction({
    required String orderId,
    required String action,
    required List<Map<String, dynamic>> allocations,
    String? reason,
  }) async {
    try {
      _isActionLoading.value = true;

      final response = await httpClient.post(
        "/api/v1/admin-order/order-action",
        data: {
          "orderId": orderId,
          "action": action,
          "allocations": allocations,
          if (reason != null && reason.trim().isNotEmpty)
            "adminMessage": reason.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrders();
      } else {
        ToastUtils.showError("Failed to update order");
      }
    } catch (e) {
      String errorMessage = "Something went wrong";
      if (e is DioException) {
        if (e.response?.data is Map) {
          errorMessage =
              e.response?.data?['error']?['message']?.toString() ??
              e.response?.data?['message']?.toString() ??
              e.message ??
              errorMessage;
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      }

      ToastUtils.showError(errorMessage);
    } finally {
      _isActionLoading.value = false;
    }
  }

  Future<bool> performCustomOrderAction({
    required String orderId,
    required String action,
    String? adminMessage,
    String? assignedKarigarId,
    String? talkedToStaffName,
    String? assignAdminNotes,
    String? deliveryDate,
    String? completeAdminNotes,
  }) async {
    try {
      _isActionLoading.value = true;

      final body = <String, dynamic>{
        "orderId": orderId,
        "action": action,
        if (adminMessage != null && adminMessage.isNotEmpty)
          "adminMessage": adminMessage,
        "assignedKarigarId": ?assignedKarigarId,
        "talkedToStaffName": ?talkedToStaffName,
        "assignAdminNotes": ?assignAdminNotes,
        "deliveryDate": ?deliveryDate,
        "completeAdminNotes": ?completeAdminNotes,
      };

      final response = await httpClient.post(
        ApiUrlConstants.ADMIN_CUSTOM_ORDER_ACTION,
        data: body,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchOrders();

        ToastUtils.showSuccess(response.data['message'] ?? "Order updated");
        return true;
      } else {
        ToastUtils.showError(response.data?['message'] ?? "Failed to update order");
        return false;
      }
    } catch (e, st) {
      Logger.error("AdminOrderController", "performCustomOrderAction error: $e\n$st");

      String errorMessage = "Something went wrong";
      if (e is DioException) {
        if (e.response?.data is Map) {
          errorMessage =
              e.response?.data?['error']?['message']?.toString() ??
              e.response?.data?['message']?.toString() ??
              e.message ??
              errorMessage;
        } else {
          errorMessage = e.message ?? errorMessage;
        }
      }

      ToastUtils.showError(errorMessage);
      return false;
    } finally {
      _isActionLoading.value = false;
    }
  }

}
