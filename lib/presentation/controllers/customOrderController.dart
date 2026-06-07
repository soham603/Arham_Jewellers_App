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

  // =====================================================
  // CREATE CUSTOM ORDER
  // =====================================================

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
