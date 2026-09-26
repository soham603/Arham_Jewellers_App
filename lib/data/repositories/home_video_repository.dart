import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/core/constants/timeout_constants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/home_video_model.dart';
import 'package:ratnesh_gold_app/domain/repositories/i_home_video_repository.dart';

class HomeVideoRepository extends BaseRepository
    implements IHomeVideoRepository {
  @override
  Future<HomeVideoModel?> fetchVideo() async {
    final response = await dio.get(
      ApiUrlConstants.HOME_VIDEO,
      options: Options(
        extra: {'requiresAuth': false},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );

    final responseData = response.data;
    if (responseData['success'] == false) {
      throw ApiException(
        responseData['message'] ?? 'Failed to load home video',
        code: responseData['error']?['code'],
        response: responseData,
      );
    }

    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return HomeVideoModel.fromJson(data);
    }
    return null;
  }

  @override
  Future<HomeVideoModel> upsertVideo({File? file, bool? isActive}) async {
    final map = <String, dynamic>{
      if (isActive != null) 'isActive': isActive.toString(),
      if (file != null)
        'video': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
    };

    final response = await dio.put(
      ApiUrlConstants.HOME_VIDEO,
      data: FormData.fromMap(map),
      options: Options(
        extra: {'requiresAuth': true},
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );

    final responseData = response.data;
    if (responseData['success'] == false) {
      throw ApiException(
        responseData['message'] ?? 'Failed to save home video',
        code: responseData['error']?['code'],
        response: responseData,
      );
    }

    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return HomeVideoModel.fromJson(data);
    }
    throw ApiException(
      responseData['message'] ?? 'No data received',
      response: responseData,
    );
  }

  @override
  Future<void> deleteVideo() async {
    final response = await dio.delete(
      ApiUrlConstants.HOME_VIDEO,
      options: Options(
        extra: {'requiresAuth': true},
        sendTimeout: AppTimeouts.quickSend,
        receiveTimeout: AppTimeouts.quickReceive,
      ),
    );

    final responseData = response.data;
    if (responseData is Map && responseData['success'] == false) {
      throw ApiException(
        responseData['message'] ?? 'Failed to delete home video',
        code: responseData['error']?['code'],
        response: Map<String, dynamic>.from(responseData),
      );
    }
  }
}
