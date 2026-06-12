import 'package:ratnesh_gold_app/app/routes/app_routes.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:ratnesh_gold_app/data/repositories/order_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/userOrderModel.dart';
import 'package:ratnesh_gold_app/presentation/controllers/cart_controller.dart';
import 'package:ratnesh_gold_app/presentation/controllers/notification_controller.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class UserOrderController extends GetxController {
  static UserOrderController get instance => Get.find();

  final _orderRepo = OrderRepository();

  final CartController cartController = Get.isRegistered<CartController>() ? Get.find<CartController>() : Get.put(CartController());

  final _createOrderState = CurrentAppState.INITIAL.obs;

  CurrentAppState get createOrderState => _createOrderState.value;

  final _isCreatingOrder = false.obs;

  bool get isCreatingOrder => _isCreatingOrder.value;

  final _orderMessage = ''.obs;

  String get orderMessage => _orderMessage.value;

  final _createdOrderId = ''.obs;

  String get createdOrderId => _createdOrderId.value;

  final _lastOrderImages = <String>[].obs;

  List<String> get lastOrderImages => _lastOrderImages;

  final _lastOrderItemNames = <String>[].obs;

  List<String> get lastOrderItemNames => _lastOrderItemNames;

  final _lastOrderItemQuantities = <int>[].obs;

  List<int> get lastOrderItemQuantities => _lastOrderItemQuantities;

  final _lastOrderItemPrices = <double>[].obs;

  List<double> get lastOrderItemPrices => _lastOrderItemPrices;

  double _lastOrderTotal = 0;

  double get lastOrderTotal => _lastOrderTotal;

  DateTime _lastOrderCreatedAt = DateTime.now();

  DateTime get lastOrderCreatedAt => _lastOrderCreatedAt;


  static const int _ordersLimit = 10;

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



  // ── Status filter 

  final _selectedFilter = 'all'.obs;
  String get selectedFilter => _selectedFilter.value;

  void setFilter(String filter) => _selectedFilter.value = filter;

  List<UserOrderModel> get filteredOrders {
    switch (_selectedFilter.value) {
      case 'pending':
        return _userOrders
            .where((o) => o.status.toLowerCase() == 'pending')
            .toList();
      case 'approved':
        return _userOrders.where((o) {
          final s = o.status.toLowerCase();
          return s == 'confirmed' || s == 'processing' || s == 'approved' || s == 'assigned';
        }).toList();
      case 'rejected':
        return _userOrders.where((o) {
          final s = o.status.toLowerCase();
          return s == 'rejected' || s == 'cancelled';
        }).toList();
      default:
        return _userOrders.toList();
    }
  }


  Future<bool> createOrder() async {
    if (_isCreatingOrder.value) return false;

    if (cartController.items.isEmpty) {
      ToastUtils.showWarning("Please add products to cart");

      return false;
    }

    try {
      _isCreatingOrder.value = true;

      _createOrderState.value = CurrentAppState.LOADING;

      final products = cartController.items.map((item) {
        return {"productId": item.product.id, "quantity": item.quantity};
      }).toList();

      Logger.info("UserOrderController", "Creating order payload: $products");

      final responseData = await _orderRepo.createOrder(orderData: {"products": products});

      final data = responseData["data"] ?? {};

        _createdOrderId.value = data["orderId"]?.toString() ?? '';

        _orderMessage.value =
            data["message"]?.toString() ?? "Order placed successfully";

        _createOrderState.value = CurrentAppState.SUCCESS;

        _lastOrderImages.value = cartController.items
            .map((item) => item.product.displayImageUrl)
            .where((url) => url != null && url.isNotEmpty)
            .cast<String>()
            .toList();

        _lastOrderItemNames.value = cartController.items
            .map((item) => item.product.name)
            .toList();

        _lastOrderItemQuantities.value = cartController.items
            .map((item) => item.quantity)
            .toList();

        _lastOrderItemPrices.value = cartController.items
            .map((item) =>
                ((item.product.rawData?["TagSalesAmount"] ?? 0).toDouble() *
                    item.quantity))
            .toList()
            .cast<double>();

        _lastOrderTotal = _lastOrderItemPrices.fold(0, (sum, p) => sum + p);

        _lastOrderCreatedAt = DateTime.now();

        cartController.clearCart();

        Logger.info("UserOrderController", "Order created successfully");

        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().addLocalNotification(
            title: 'Order Placed',
            body: 'Your order has been placed successfully. We\'ll notify you once it\'s reviewed.',
            data: {
              'route': AppRoutes.userOrderDetail,
              'orderId': _createdOrderId.value,
            },
          );
        }

        return true;
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

      ToastUtils.showError(errorMessage);

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

      final responseData = await _orderRepo.fetchUserOrders(
        queryParams: {"page": _ordersPage, "limit": _ordersLimit},
      );

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

      if (fetchedOrders.length < _ordersLimit) {
        _hasMoreOrders.value = false;
      } else {
        _ordersPage++;
      }

      _ordersState.value = CurrentAppState.SUCCESS;

      Logger.info("UserOrderController", "Orders fetched successfully");
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

      ToastUtils.showError(errorMessage);
    } finally {
      _isFetchingOrders.value = false;
    }
  }

  
  // LOAD MORE ORDERS
  

  Future<void> loadMoreOrders() async {
    if (_isFetchingOrders.value) return;

    if (!_hasMoreOrders.value) return;

    await fetchUserOrders(isPagination: true);
  }

  
  // REFRESH ORDERS
  

  Future<void> refreshOrders() async {
    _ordersPage = 1;

    _hasMoreOrders.value = true;

    _userOrders.clear();

    await fetchUserOrders();
  }

  
  // RESET ORDER STATE
  

  void resetOrderState() {
    _createOrderState.value = CurrentAppState.INITIAL;

    _isCreatingOrder.value = false;

    _orderMessage.value = '';

    _createdOrderId.value = '';

    _lastOrderImages.clear();

    _lastOrderItemNames.clear();

    _lastOrderItemQuantities.clear();

    _lastOrderItemPrices.clear();

    _lastOrderTotal = 0;

    _lastOrderCreatedAt = DateTime.now();
  }
}
