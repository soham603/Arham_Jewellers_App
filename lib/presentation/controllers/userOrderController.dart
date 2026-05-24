import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class UserOrderController extends GetxController {
  static UserOrderController get instance => Get.find();

  final CartController cartController = Get.isRegistered<CartController>() ? Get.find<CartController>() : Get.put(CartController());

  final _createOrderState = CurrentAppState.INITIAL.obs;

  CurrentAppState get createOrderState => _createOrderState.value;

  final _isCreatingOrder = false.obs;

  bool get isCreatingOrder => _isCreatingOrder.value;

  final _orderMessage = ''.obs;

  String get orderMessage => _orderMessage.value;

  final _createdOrderId = ''.obs;

  String get createdOrderId => _createdOrderId.value;


  static const int _ordersLimit = 5;

  final _userOrders = <UserOrderModel>[].obs;

  List<UserOrderModel> get userOrders => _userOrders;

  final _ordersState = CurrentAppState.INITIAL.obs;

  CurrentAppState get ordersState => _ordersState.value;

  final _isFetchingOrders = false.obs;

  bool get isFetchingOrders => _isFetchingOrders.value;

  final _hasMoreOrders = true.obs;

  bool get hasMoreOrders => _hasMoreOrders.value;

  final _totalOrders = 0.obs;

  int get totalOrders => _totalOrders.value;

  int _ordersPage = 1;


  Future<bool> createOrder() async {
    if (_isCreatingOrder.value) return false;

    if (cartController.items.isEmpty) {
      Get.snackbar("Cart Empty", "Please add products to cart");

      return false;
    }

    try {
      _isCreatingOrder.value = true;

      _createOrderState.value = CurrentAppState.LOADING;

      final products = cartController.items.map((item) {
        return {"productId": item.product.id, "quantity": item.quantity};
      }).toList();

      Logger.info("UserOrderController", "Creating order payload: $products");

      final response = await httpClient.post(
        "/api/v1/products/create-order",
        data: {"products": products},
        options: Options(
          extra: {"requiresAuth" : true },
        )
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        final data = responseData["data"] ?? {};

        _createdOrderId.value = data["orderId"]?.toString() ?? '';

        _orderMessage.value =
            data["message"]?.toString() ?? "Order placed successfully";

        _createOrderState.value = CurrentAppState.SUCCESS;

        cartController.clearCart();

        Get.snackbar("Order Placed", _orderMessage.value);

        Logger.info("UserOrderController", "Order created successfully");

        return true;
      }

      _createOrderState.value = CurrentAppState.ERROR;

      Get.snackbar(
        "Order Failed",
        response.data?["message"] ?? "Something went wrong",
      );

      return false;
    } catch (e, st) {
      _createOrderState.value = CurrentAppState.ERROR;

      Logger.error("UserOrderController", "createOrder error: $e\n$st");

      String errorMessage = "Failed to place order";

      if (e is DioException) {
        errorMessage =
            e.response?.data?["message"]?.toString() ??
            e.message ??
            errorMessage;
      }

      Get.snackbar("Order Failed", errorMessage);

      return false;
    } finally {
      _isCreatingOrder.value = false;
    }
  }


  Future<void> fetchUserOrders({bool isPagination = false}) async {
    if (_isFetchingOrders.value) return;

    if (!_hasMoreOrders.value && isPagination) {
      return;
    }

    try {
      _isFetchingOrders.value = true;

      if (!isPagination) {
        _ordersState.value = CurrentAppState.LOADING;

        _ordersPage = 1;

        _hasMoreOrders.value = true;

        _userOrders.clear();
      }

      Logger.info("UserOrderController", "Fetching orders page: $_ordersPage");

      final response = await httpClient.get(
        "/api/v1/products/get-userAllOrders",
        queryParameters: {"page": _ordersPage, "limit": _ordersLimit},
        options: Options(
          extra: {"requiresAuth" : true },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        final data = responseData["data"] ?? {};

        final List rawOrders = data["orders"] is List ? data["orders"] : [];

        final fetchedOrders = rawOrders
            .map((e) => UserOrderModel.fromJson(e))
            .toList();

        if (isPagination) {
          _userOrders.addAll(fetchedOrders);
        } else {
          _userOrders.value = fetchedOrders;
        }

        _totalOrders.value = data["total"] ?? 0;

        // IMPORTANT PAGINATION LOGIC
        if (fetchedOrders.length < _ordersLimit) {
          _hasMoreOrders.value = false;
        } else {
          _ordersPage++;
        }

        _ordersState.value = CurrentAppState.SUCCESS;

        Logger.info("UserOrderController", "Orders fetched successfully");
      } else {
        _ordersState.value = CurrentAppState.ERROR;

        Get.snackbar(
          "Failed",
          response.data?["message"] ?? "Failed to fetch orders",
        );
      }
    } catch (e, st) {
      _ordersState.value = CurrentAppState.ERROR;

      Logger.error("UserOrderController", "fetchUserOrders error: $e\n$st");

      String errorMessage = "Failed to fetch orders";

      if (e is DioException) {
        errorMessage =
            e.response?.data?["message"]?.toString() ??
            e.message ??
            errorMessage;
      }

      Get.snackbar("Error", errorMessage);
    } finally {
      _isFetchingOrders.value = false;
    }
  }

  // =====================================================
  // LOAD MORE ORDERS
  // =====================================================

  Future<void> loadMoreOrders() async {
    if (_isFetchingOrders.value) return;

    if (!_hasMoreOrders.value) return;

    await fetchUserOrders(isPagination: true);
  }

  // =====================================================
  // REFRESH ORDERS
  // =====================================================

  Future<void> refreshOrders() async {
    _ordersPage = 1;

    _hasMoreOrders.value = true;

    _userOrders.clear();

    await fetchUserOrders();
  }

  // =====================================================
  // RESET ORDER STATE
  // =====================================================

  void resetOrderState() {
    _createOrderState.value = CurrentAppState.INITIAL;

    _isCreatingOrder.value = false;

    _orderMessage.value = '';

    _createdOrderId.value = '';
  }
}
