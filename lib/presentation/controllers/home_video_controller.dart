import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/data/repositories/home_video_repository.dart';
import 'package:ratnesh_gold_app/domain/entities/home_video_model.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';

class HomeVideoController extends GetxController {
  static HomeVideoController get instance => Get.find();

  final _repo = HomeVideoRepository();

  final Rxn<HomeVideoModel> _video = Rxn<HomeVideoModel>();
  HomeVideoModel? get video => _video.value;

  final _state = CurrentAppState.INITIAL.obs;
  CurrentAppState get state => _state.value;

  final _uploadState = CurrentAppState.INITIAL.obs;
  CurrentAppState get uploadState => _uploadState.value;

  final _toggleState = CurrentAppState.INITIAL.obs;
  CurrentAppState get toggleState => _toggleState.value;

  final _deleteState = CurrentAppState.INITIAL.obs;
  CurrentAppState get deleteState => _deleteState.value;

  final _linkState = CurrentAppState.INITIAL.obs;
  CurrentAppState get linkState => _linkState.value;

  final _error = ''.obs;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    fetchVideo();
  }

  Future<void> fetchVideo() async {
    try {
      _state.value = CurrentAppState.LOADING;
      _video.value = await _repo.fetchVideo();
      _state.value = CurrentAppState.SUCCESS;
    } catch (e) {
      _error.value = _messageFrom(e, 'Failed to load home video');
      _state.value = CurrentAppState.ERROR;
    }
  }

  Future<bool> uploadVideo(
    File file, {
    bool? isActive,
    String? linkType,
    String? linkId,
  }) async {
    try {
      _uploadState.value = CurrentAppState.LOADING;
      _error.value = '';

      _video.value = await _repo.upsertVideo(
        file: file,
        isActive: isActive,
        linkType: linkType,
        linkId: linkId,
      );

      _uploadState.value = CurrentAppState.SUCCESS;
      return true;
    } catch (e) {
      _error.value = _messageFrom(e, 'Failed to upload home video');
      _uploadState.value = CurrentAppState.ERROR;
      return false;
    }
  }

  Future<bool> setActive(bool isActive) async {
    try {
      _toggleState.value = CurrentAppState.LOADING;
      _error.value = '';

      _video.value = await _repo.upsertVideo(isActive: isActive);

      _toggleState.value = CurrentAppState.SUCCESS;
      return true;
    } catch (e) {
      _error.value = _messageFrom(e, 'Failed to update home video');
      _toggleState.value = CurrentAppState.ERROR;
      return false;
    }
  }

  Future<bool> setLink({required String linkType, String? linkId}) async {
    try {
      _linkState.value = CurrentAppState.LOADING;
      _error.value = '';

      _video.value = await _repo.upsertVideo(linkType: linkType, linkId: linkId);

      _linkState.value = CurrentAppState.SUCCESS;
      return true;
    } catch (e) {
      _error.value = _messageFrom(e, 'Failed to update the video link');
      _linkState.value = CurrentAppState.ERROR;
      return false;
    }
  }

  Future<bool> deleteVideo() async {
    try {
      _deleteState.value = CurrentAppState.LOADING;
      _error.value = '';

      await _repo.deleteVideo();
      _video.value = null;

      _deleteState.value = CurrentAppState.SUCCESS;
      return true;
    } catch (e) {
      _error.value = _messageFrom(e, 'Failed to delete home video');
      _deleteState.value = CurrentAppState.ERROR;
      return false;
    }
  }

  String _messageFrom(Object e, String fallback) {
    if (e is DioException) {
      return e.response?.data?['message']?.toString() ?? e.message ?? fallback;
    }
    if (e is Exception) {
      final text = e.toString().replaceFirst('Exception: ', '');
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}
