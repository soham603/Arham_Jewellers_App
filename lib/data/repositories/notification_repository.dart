import 'package:ratnesh_gold_app/core/constants/ApiUrlConstants.dart';
import 'package:ratnesh_gold_app/data/repositories/base_repository.dart';

class NotificationRepository extends BaseRepository {
  Future<void> updateFcmToken({
    required Map<String, dynamic> data,
  }) async {
    await dio.post(
      ApiUrlConstants.UPDATE_FCM_TOKEN,
      data: data,
    );
  }
}
