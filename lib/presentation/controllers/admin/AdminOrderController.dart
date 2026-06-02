import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

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

  final searchController = TextEditingController();

  Timer? _debounce;

  int _page = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  final _productImageCache = <String, String?>{}.obs;
  String? getProductImage(String productId) => _productImageCache[productId];

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
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
          "limit": 10,

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

        if (isPagination) {
          _orders.addAll(fetched);
        } else {
          _orders.value = fetched;
        }

        _hasMore = currentPage < totalPages;

        if (_hasMore) {
          _page++;
        }

        _orderState.value = CurrentAppState.SUCCESS;

        _fetchProductImages();
      }
    } catch (e, st) {
      Logger.error("AdminOrderController", "$e\n$st");

      _orderState.value = CurrentAppState.ERROR;
    } finally {
      _isPaginationLoading.value = false;
    }
  }

  Future<void> _fetchProductImages() async {
    final uniqueProducts = <String, String>{};
    for (final order in _orders) {
      for (final item in order.orderItems) {
        final id = item.product.id;
        if (!_productImageCache.containsKey(id) &&
            !uniqueProducts.containsKey(id)) {
          uniqueProducts[id] = item.product.name;
        }
      }
    }

    if (uniqueProducts.isEmpty) return;

    for (final entry in uniqueProducts.entries) {
      try {
        final response = await httpClient.get(
          "/api/v1/products/search",
          queryParameters: {
            "search": entry.value,
            "page": 1,
            "limit": 5,
            "showAll": true,
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final List raw = response.data['data']['data'] ?? [];
          final match = raw.cast<Map<String, dynamic>?>().firstWhere(
                (p) => p?['id'] == entry.key,
                orElse: () => raw.isNotEmpty ? raw.first as Map<String, dynamic>? : null,
              );

          if (match != null) {
            _productImageCache[entry.key] = match['imageUrl'];
          }
        }
      } catch (e) {
        Logger.error("AdminOrderController", "Image fetch failed for ${entry.key}: $e");
      }
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

        Get.snackbar(
          "Success",
          response.data["message"] ?? "Order updated",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to update order",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      String errorMessage = "Something went wrong";
      try {
        errorMessage = (e as dynamic).response.data["error"]["message"];
      } catch (_) {}

      Get.snackbar(
        "Error",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isActionLoading.value = false;
    }
  }
}
