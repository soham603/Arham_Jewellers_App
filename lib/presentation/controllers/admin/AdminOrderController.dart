import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/data/repositories/order_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class AdminOrderController extends GetxController {
  static AdminOrderController get instance => Get.find();

  final _orderRepo = OrderRepository();

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

  final _productRawDataCache = <String, Map<String, dynamic>>{}.obs;
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

  String _buildOrderActionLabel(String action) {
    final upperAction = action.toUpperCase();
    switch (upperAction) {
      case 'APPROVE':
      case 'APPROVE_AND_ASSIGN':
        return 'Approved';
      case 'REJECT':
        return 'Rejected';
      case 'COMPLETE':
        return 'Completed';
      default:
        return upperAction;
    }
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

      final baseParams = <String, dynamic>{
        "page": _page,
        "limit": _pageLimit,
        "status": selectedStatus.value,
        if (searchController.text.trim().isNotEmpty)
          "userPhoneNumber": "+91${searchController.text.trim()}",
      };

      List<AdminOrderModel> allItems;
      int totalItems;
      int totalPages;

      if (selectedOrderType.value == "all") {
        final normalParams = {...baseParams, "orderType": "normal"};
        final customParams = {...baseParams, "orderType": "custom"};

        final normalResult = await _orderRepo.fetchAdminOrders(queryParams: normalParams);
        final customResult = await _orderRepo.fetchAdminOrders(queryParams: customParams);

        allItems = [...normalResult.items, ...customResult.items];
        totalItems = normalResult.total + customResult.total;
        totalPages = totalItems > 0 ? (totalItems / _pageLimit).ceil() : 1;
      } else {
        final params = {
          ...baseParams,
          "orderType": selectedOrderType.value,
        };
        final result = await _orderRepo.fetchAdminOrders(queryParams: params);
        allItems = result.items;
        totalItems = result.total;
        totalPages = result.totalPages;
      }

      allItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (isPagination) {
        _orders.addAll(allItems);
      } else {
        _orders.value = allItems;
      }

      _hasMore = _page < totalPages;

      if (_hasMore) {
        _page++;
      }

      _orderState.value = CurrentAppState.SUCCESS;
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
          final result = await _orderRepo.searchProducts(
            query: entry.value,
            queryParams: {
              "page": 1,
              "limit": 10,
              "showAll": true,
            },
          );
          final match = result.items.where((p) => p.id == entry.key).firstOrNull;
          if (match != null && match.rawData != null) {
            _productRawDataCache[entry.key] = Map<String, dynamic>.from(match.rawData!);
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
    String? deliveryDate,
    String? completeAdminNotes,
  }) async {
    try {
      _isActionLoading.value = true;

      await _orderRepo.performOrderAction(
        actionData: {
          "orderId": orderId,
          "action": action,
          "allocations": allocations,
          if (reason != null && reason.trim().isNotEmpty)
            "adminMessage": reason.trim(),
          if (deliveryDate != null && deliveryDate.isNotEmpty)
            "deliveryDate": deliveryDate,
          if (completeAdminNotes != null && completeAdminNotes.isNotEmpty)
            "completeAdminNotes": completeAdminNotes,
        },
      );

      await fetchOrders();

      if (Get.isRegistered<NotificationController>()) {
        final actionLabel = _buildOrderActionLabel(action);
        Get.find<NotificationController>().addLocalNotification(
          title: 'Order $actionLabel',
          body: 'Order ${orderId.length > 8 ? orderId.substring(0, 8) : orderId} has been ${actionLabel.toLowerCase()}.',
          data: {
            'route': AppRoutes.adminOrderDetail,
            'orderId': orderId,
          },
        );
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

      final responseData = await _orderRepo.performCustomOrderAction(
        actionData: {
          "orderId": orderId,
          "action": action,
          if (adminMessage != null && adminMessage.isNotEmpty)
            "adminMessage": adminMessage,
          "assignedKarigarId": ?assignedKarigarId,
          "talkedToStaffName": ?talkedToStaffName,
          "assignAdminNotes": ?assignAdminNotes,
          "deliveryDate": ?deliveryDate,
          "completeAdminNotes": ?completeAdminNotes,
        },
      );

      await fetchOrders();

      if (Get.isRegistered<NotificationController>()) {
        final actionLabel = _buildOrderActionLabel(action);
        Get.find<NotificationController>().addLocalNotification(
          title: 'Custom Order $actionLabel',
          body: 'Custom order ${orderId.length > 8 ? orderId.substring(0, 8) : orderId} has been ${actionLabel.toLowerCase()} successfully.',
          data: {
            'route': AppRoutes.adminOrderDetail,
            'orderId': orderId,
          },
        );
      }

      ToastUtils.showSuccess(responseData['message'] ?? "Order updated");
      return true;
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
