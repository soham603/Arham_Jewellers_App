import 'dart:io';

import 'package:ratnesh_gold_app/domain/entities/home_video_model.dart';

abstract class IHomeVideoRepository {
  Future<HomeVideoModel?> fetchVideo();

  Future<HomeVideoModel> upsertVideo({
    File? file,
    bool? isActive,
    String? linkType,
    String? linkId,
  });

  Future<void> deleteVideo();
}
