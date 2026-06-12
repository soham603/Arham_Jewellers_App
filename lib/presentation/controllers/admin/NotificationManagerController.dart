import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:ratnesh_gold_app/data/repositories/notification_repository.dart';
import 'package:ratnesh_gold_app/utils/Enums.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/ToastUtil.dart';

class NotificationManagerController extends GetxController {
  static NotificationManagerController get instance => Get.find();

  final _notificationRepo = NotificationRepository();

  // ── Form fields
  final _title = ''.obs;
  String get title => _title.value;

  final _body = ''.obs;
  String get body => _body.value;

  final _targetType = 'all'.obs;
  String get targetType => _targetType.value;

  final _targetValue = ''.obs;
  String get targetValue => _targetValue.value;

  // ── Send state
  final _sendState = CurrentAppState.INITIAL.obs;
  CurrentAppState get sendState => _sendState.value;

  // ── History
  final _history = <SentNotification>[].obs;
  List<SentNotification> get history => _history;

  final _historyState = CurrentAppState.INITIAL.obs;
  CurrentAppState get historyState => _historyState.value;

  final _error = ''.obs;
  String get error => _error.value;

  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  static const int _pageLimit = 20;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  // ── Form setters
  void setTitle(String value) => _title.value = value;
  void setBody(String value) => _body.value = value;
  void setTargetType(String value) {
    _targetType.value = value;
    _targetValue.value = '';
  }
  void setTargetValue(String value) => _targetValue.value = value;

  // ── Send notification
  Future<bool> sendNotification() async {
    if (_title.value.trim().isEmpty) {
      ToastUtils.showWarning('Please enter a notification title');
      return false;
    }
    if (_body.value.trim().isEmpty) {
      ToastUtils.showWarning('Please enter a notification body');
      return false;
    }
    if (_targetType.value != 'all' && _targetValue.value.trim().isEmpty) {
      ToastUtils.showWarning('Please enter a target value');
      return false;
    }

    _sendState.value = CurrentAppState.LOADING;

    try {
      final data = <String, dynamic>{
        'title': _title.value.trim(),
        'body': _body.value.trim(),
        'targetType': _targetType.value,
      };

      if (_targetType.value != 'all') {
        data['targetValue'] = _targetValue.value.trim();
      }

      final response = await _notificationRepo.sendNotification(data: data);

      if (response['code'] != 'ERROR') {
        _sendState.value = CurrentAppState.SUCCESS;
        ToastUtils.showSuccess(response['message'] ?? 'Notification sent successfully');
        _clearForm();
        _page = 1;
        _hasMore = true;
        await fetchHistory();
        return true;
      }

      final message = response['error']?['message'] ??
          response['message'] ??
          'Failed to send notification';

      _sendState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } on DioException catch (e, st) {
      Logger.error('NotificationManagerController', 'sendNotification Dio: $e\n$st');

      String message = 'Something went wrong';
      if (e.response?.data is Map) {
        final data = e.response!.data;
        message = data['error']?['message'] ?? data['message'] ?? e.message ?? 'Something went wrong';
      } else {
        message = e.message ?? 'Something went wrong';
      }

      _sendState.value = CurrentAppState.ERROR;
      _error.value = message;
      ToastUtils.showError(message);
      return false;
    } catch (e, st) {
      Logger.error('NotificationManagerController', 'sendNotification: $e\n$st');
      _sendState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
      ToastUtils.showError(e.toString());
      return false;
    }
  }

  // ── Fetch history
  Future<void> fetchHistory({bool isPagination = false}) async {
    if (!_hasMore && isPagination) return;

    _historyState.value = CurrentAppState.LOADING;
    if (!isPagination) {
      _page = 1;
      _hasMore = true;
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _page,
        'limit': _pageLimit,
      };

      final response = await _notificationRepo.getNotificationHistory(
        queryParams: queryParams,
      );

      if (response['code'] != 'ERROR') {
        final rawData = response['data'];
        List raw = [];

        if (rawData is List) {
          raw = rawData;
        } else if (rawData is Map<String, dynamic>) {
          raw = rawData['notifications'] ?? rawData['data'] ?? [];
        }

        final fetched = raw.map((e) => SentNotification.fromJson(e)).toList();

        if (isPagination) {
          _history.addAll(fetched);
        } else {
          _history.assignAll(fetched);
        }

        if (fetched.length < _pageLimit) {
          _hasMore = false;
        } else {
          _page++;
        }

        _historyState.value = CurrentAppState.SUCCESS;
      } else {
        _historyState.value = CurrentAppState.ERROR;
        _error.value = response['message'] ?? 'Failed to load history';
      }
    } on DioException catch (e, st) {
      Logger.error('NotificationManagerController', 'fetchHistory Dio: $e\n$st');
      _historyState.value = CurrentAppState.ERROR;
      _error.value =
          e.response?.data?['message'] ?? e.message ?? 'Something went wrong';
    } catch (e, st) {
      Logger.error('NotificationManagerController', 'fetchHistory: $e\n$st');
      _historyState.value = CurrentAppState.ERROR;
      _error.value = e.toString();
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore || _historyState.value == CurrentAppState.LOADING) return;
    await fetchHistory(isPagination: true);
  }

  Future<void> refreshHistory() async {
    _page = 1;
    _hasMore = true;
    await fetchHistory();
  }

  void _clearForm() {
    _title.value = '';
    _body.value = '';
    _targetType.value = 'all';
    _targetValue.value = '';
  }
}

class SentNotification {
  final String id;
  final String title;
  final String body;
  final String targetType;
  final String? targetValue;
  final DateTime sentAt;
  final String? sentBy;
  final int? recipientCount;

  SentNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.targetType,
    this.targetValue,
    required this.sentAt,
    this.sentBy,
    this.recipientCount,
  });

  factory SentNotification.fromJson(Map<String, dynamic> json) {
    return SentNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      targetType: json['targetType'] ?? json['target_type'] ?? 'all',
      targetValue: json['targetValue'] ?? json['target_value'],
      sentAt: DateTime.tryParse(json['sentAt'] ?? json['sent_at'] ?? json['timestamp'] ?? '') ?? DateTime.now(),
      sentBy: json['sentBy'] ?? json['sent_by'],
      recipientCount: json['recipientCount'] ?? json['recipient_count'],
    );
  }
}
