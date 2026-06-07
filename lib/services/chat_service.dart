import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ratnesh_gold_app/utils/Logger.dart';
import 'package:ratnesh_gold_app/utils/SessionManager.dart';

enum ChatEventType { toolCall, textDelta, done, error }

class ChatEvent {
  final ChatEventType type;
  final String? tool;
  final String? label;
  final String? content;

  ChatEvent({required this.type, this.tool, this.label, this.content});
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});
}

class ChatService {
  final Dio _dio = Dio();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  String get _agentUrl => dotenv.env['AGENT_SERVER_URL'] ?? 'http://192.168.1.112:3001';
  bool get isConfigured => _agentUrl.isNotEmpty;

  void clearHistory() {
    _messages.clear();
  }

  Stream<ChatEvent> sendMessageStream(String userMessage) async* {
    if (!isConfigured) {
      yield ChatEvent(type: ChatEventType.error, content: 'Chat not configured. Set AGENT_SERVER_URL in .env.');
      return;
    }

    _isLoading = true;
    _messages.add(ChatMessage(role: 'user', content: userMessage));

    final token = await getToken();

    try {
      final request = await _dio.post(
        '$_agentUrl/chat/stream',
        data: {
          'message': userMessage,
          'sessionId': 'flutter-app',
          if (token != null) 'token': token,
        },
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      final stream = request.data.stream;
      String fullResponse = '';
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty) continue;

            try {
              final data = jsonDecode(jsonStr);
              final type = data['type'] as String?;

              if (type == 'tool_call') {
                yield ChatEvent(
                  type: ChatEventType.toolCall,
                  tool: data['tool'],
                  label: data['label'],
                );
              } else if (type == 'text_delta') {
                final content = data['content'] as String? ?? '';
                fullResponse += content;
                yield ChatEvent(type: ChatEventType.textDelta, content: content);
              } else if (type == 'done') {
                // Use accumulated response
              } else if (type == 'error') {
                yield ChatEvent(type: ChatEventType.error, content: data['error']);
              }
            } catch (e) {
              Logger.warning("ChatService", "Failed to parse SSE chunk: $e");
            }
          }
        }
      }

      if (fullResponse.isNotEmpty) {
        _messages.add(ChatMessage(role: 'assistant', content: fullResponse));
      }
    } catch (e) {
      final errorMsg = 'Error: ${e.toString()}';
      _messages.add(ChatMessage(role: 'assistant', content: errorMsg));
      yield ChatEvent(type: ChatEventType.error, content: errorMsg);
    } finally {
      _isLoading = false;
    }
  }

  static Future<String?> getToken() async {
    return await SessionManager().getAccessToken();
  }
}
