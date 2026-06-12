import 'package:ratnesh_gold_app/utils/ToastUtil.dart';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:ratnesh_gold_app/data/repositories/custom_order_repository.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';

class CustomOrderController extends GetxController {
  static CustomOrderController get instance => Get.find();

  final _customOrderRepo = CustomOrderRepository();

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

  
  // CREATE CUSTOM ORDER
  

  Future<bool> createCustomOrder({
    String? productId,
    required String partyCode,
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
        if (productId != null && productId.isNotEmpty) 'productId': productId,
        'partyCode': partyCode,
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

      final responseData = await _customOrderRepo.createCustomOrder(data: formData);

      if (responseData.isNotEmpty) {
        final data = responseData['data'] ?? {};
        _createdOrderId.value = data['orderId']?.toString() ?? '';
        _createState.value = CurrentAppState.SUCCESS;

        Logger.info("CustomOrderController",
            "Custom order created: ${_createdOrderId.value}");

        return true;
      }

      _createState.value = CurrentAppState.ERROR;
      ToastUtils.showError("Failed to create custom order");
      return false;
    } catch (e, st) {
      _createState.value = CurrentAppState.ERROR;
      Logger.error("CustomOrderController", "createCustomOrder error: $e\n$st");

      String errorMessage = "Failed to create custom order";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.message ?? errorMessage;
      }

      ToastUtils.showError(errorMessage);
      return false;
    } finally {
      _isCreating.value = false;
    }
  }

  
  // MODIFY CUSTOM ORDER
  

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
        'partyCode': ?partyCode,
        'partyName': ?partyName,
        'area': ?area,
        'contactNumber': ?contactNumber,
        'itemName': ?itemName,
        'weight': ?weight,
        'noOfPieces': ?noOfPieces,
        'size': ?size,
        'lengthBroadness': ?lengthBroadness,
        'productDescription': ?productDescription,
        'purity': ?purity,
        'style': ?style,
        'marking': ?marking,
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

      await _customOrderRepo.modifyCustomOrder(
        orderId: orderId,
        data: formData,
      );

      _modifyState.value = CurrentAppState.SUCCESS;

      Logger.info("CustomOrderController", "Custom order modified: $orderId");

      return true;
    } catch (e, st) {
      _modifyState.value = CurrentAppState.ERROR;
      Logger.error("CustomOrderController", "modifyCustomOrder error: $e\n$st");

      String errorMessage = "Failed to update custom order";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.message ?? errorMessage;
      }

      ToastUtils.showError(errorMessage);
      return false;
    } finally {
      _isModifying.value = false;
    }
  }

  
  // DELETE CUSTOM ORDER
  

  Future<bool> deleteCustomOrder(String orderId) async {
    if (_isDeleting.value) return false;

    try {
      _isDeleting.value = true;

      await _customOrderRepo.deleteCustomOrder(orderId: orderId);

      ToastUtils.showSuccess("Custom order deleted successfully");

      Logger.info("CustomOrderController", "Custom order deleted: $orderId");
      return true;
    } catch (e, st) {
      Logger.error("CustomOrderController", "deleteCustomOrder error: $e\n$st");

      String errorMessage = "Failed to delete custom order";
      if (e is DioException) {
        errorMessage =
            e.response?.data?['message']?.toString() ?? e.message ?? errorMessage;
      }

      ToastUtils.showError(errorMessage);
      return false;
    } finally {
      _isDeleting.value = false;
    }
  }

  
  // RESET
  

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
