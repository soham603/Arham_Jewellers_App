import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide MultipartFile, FormData;
import 'package:ratnesh_gold_app/domain/entities/carousel_model.dart';
import 'package:ratnesh_gold_app/services/Dependencies.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class CarouselsController extends GetxController {
  static CarouselsController get instance => Get.find();

  final _getCarouselState = CurrentAppState.INITIAL.obs;
  CurrentAppState get getCarouselState => _getCarouselState.value;

  final _createState = CurrentAppState.INITIAL.obs;
  CurrentAppState get createState => _createState.value;

  final _editState = CurrentAppState.INITIAL.obs;
  CurrentAppState get editState => _editState.value;

  final _deleteState = CurrentAppState.INITIAL.obs;
  CurrentAppState get deleteState => _deleteState.value;

  final _error = "".obs;
  String get error => _error.value;

  final RxList<CarouselModel> _list = <CarouselModel>[].obs;
  List<CarouselModel> get list => _list;


  Future<void> getAllCarousels() async {
    try {
      _getCarouselState.value = CurrentAppState.LOADING;

      final response = await httpClient.get(
        "/api/v1/carousel/get-All",
        //options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];

        _list.value = data
            .map<CarouselModel>((e) => CarouselModel.fromJson(e))
            .toList();

        _getCarouselState.value = CurrentAppState.SUCCESS;
      } else {
        _getCarouselState.value = CurrentAppState.ERROR;
      }
    } catch (e) {
      _getCarouselState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }


  Future<bool> createCarousel({
    String? title,
    String? description,
    String? descHtml,
    String? linkUrl,
    String? mobileImageUrl,
    File? imageFile,
  }) async {
    try {
      _createState.value = CurrentAppState.LOADING;

      final formData = FormData.fromMap({
        "title": title,
        "description": description,
        "descHtml": descHtml,
        "linkUrl": linkUrl,
        "mobileImageUrl": mobileImageUrl,
        if (imageFile != null)
          "image": await MultipartFile.fromFile(imageFile.path),
      });

      final response = await httpClient.post(
        "/api/v1/carousel/create",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"requiresAuth": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newItem = CarouselModel.fromJson(response.data['data']);
        _list.insert(0, newItem);

        _createState.value = CurrentAppState.SUCCESS;
        return true;
      }

      _createState.value = CurrentAppState.ERROR;
    } catch (e) {
      _createState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
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

      final formData = FormData.fromMap({
        if (title != null) "title": title,
        if (description != null) "description": description,
        if (descHtml != null) "descHtml": descHtml,
        if (linkUrl != null) "linkUrl": linkUrl,
        if (mobileImageUrl != null) "mobileImageUrl": mobileImageUrl,
        if (position != null) "position": position,
        if (isActive != null) "isActive": isActive,
        if (imageFile != null)
          "image": await MultipartFile.fromFile(imageFile.path),
      });

      final response = await httpClient.put(
        "/api/v1/carousel/edit/$id",
        data: formData,
        options: Options(
          headers: {"Content-Type": "multipart/form-data"},
          extra: {"requiresAuth": true},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = CarouselModel.fromJson(response.data['data']);

        final index = _list.indexWhere((e) => e.id == id);
        if (index != -1) {
          _list[index] = updated;
        }

        _editState.value = CurrentAppState.SUCCESS;
        return true;
      }

      _editState.value = CurrentAppState.ERROR;
    } catch (e) {
      _editState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }

    return false;
  }

  
  Future<bool> deleteCarousel(String id) async {
    try {
      _deleteState.value = CurrentAppState.LOADING;

      final response = await httpClient.delete(
        "/api/v1/carousel/delete/$id",
        options: Options(extra: {"requiresAuth": true}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _list.removeWhere((e) => e.id == id);

        _deleteState.value = CurrentAppState.SUCCESS;
        return true;
      }

      _deleteState.value = CurrentAppState.ERROR;
    } catch (e) {
      _deleteState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }

    return false;
  }
}