import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/domain/entities/admin/adminOrderModel.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class AdminCustomOrderController extends GetxController {
  static AdminCustomOrderController get instance => Get.find();

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

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  void onInit() {
    super.onInit();
    fetchCustomOrders();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // =====================================================
  // FETCH CUSTOM ORDERS (ADMIN)
  // =====================================================

  Future<void> fetchCustomOrders({bool isPagination = false}) async {
    if (_orderState.value == CurrentAppState.LOADING && !isPagination) return;
    if (!_hasMore && isPagination) return;

    try {
      if (!isPagination) {
        _page = 1;
        _orderState.value = CurrentAppState.LOADING;
      } else {
        _isPaginationLoading.value = true;
      }

      final response = await httpClient.get(
        ApiUrlConstants.ADMIN_CUSTOM_ORDER_ALL,
        queryParameters: {
          "page": _page,
          "limit": _pageLimit,
          "status": selectedStatus.value,
          if (searchController.text.trim().isNotEmpty)
            "search": searchController.text.trim(),
        },
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final totalPages = data['totalPages'] ?? 1;
        final currentPage = data['page'] ?? 1;
        final List raw = data['results'] ?? [];

        final fetched = raw.map((e) => AdminOrderModel.fromJson(e)).toList();

        if (isPagination) {
          _orders.addAll(fetched);
        } else {
          _orders.value = fetched;
        }

        _hasMore = currentPage < totalPages;
        if (_hasMore) _page++;

        _orderState.value = CurrentAppState.SUCCESS;
      }
    } catch (e, st) {
      Logger.error("AdminCustomOrderController", "fetchCustomOrders error: $e\n$st");
      _orderState.value = CurrentAppState.ERROR;
    } finally {
      _isPaginationLoading.value = false;
    }
  }

  // =====================================================
  // CHANGE STATUS FILTER
  // =====================================================

  void changeStatus(String value) {
    if (selectedStatus.value == value) return;
    selectedStatus.value = value;
    _orders.clear();
    _page = 1;
    _hasMore = true;
    fetchCustomOrders();
  }

  // =====================================================
  // SEARCH
  // =====================================================

  void onSearchChanged(String value) {
    _orders.clear();
    _page = 1;
    _hasMore = true;
    fetchCustomOrders();
  }

  // =====================================================
  // PERFORM ACTION
  // =====================================================

  Future<bool> performAction({
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
        if (assignedKarigarId != null) "assignedKarigarId": assignedKarigarId,
        if (talkedToStaffName != null) "talkedToStaffName": talkedToStaffName,
        if (assignAdminNotes != null) "assignAdminNotes": assignAdminNotes,
        if (deliveryDate != null) "deliveryDate": deliveryDate,
        if (completeAdminNotes != null)
          "completeAdminNotes": completeAdminNotes,
      };

      final response = await httpClient.post(
        ApiUrlConstants.ADMIN_CUSTOM_ORDER_ACTION,
        data: body,
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCustomOrders();

        Get.snackbar(
          "Success",
          response.data['message'] ?? "Order updated",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF2D9D59),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return true;
      } else {
        Get.snackbar(
          "Error",
          response.data?['message'] ?? "Failed to update order",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e, st) {
      Logger.error("AdminCustomOrderController", "performAction error: $e\n$st");

      String errorMessage = "Something went wrong";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.message ?? errorMessage;
      }

      Get.snackbar(
        "Error",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isActionLoading.value = false;
    }
  }
}
