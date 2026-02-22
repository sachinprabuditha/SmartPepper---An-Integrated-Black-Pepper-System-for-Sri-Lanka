import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skr_frontend_mobile/core/network/api_client.dart';
import '../models/chat_model.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ApiClient());
});

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<RagChatResponse> sendMessage(
    String message, {
    String? conversationId,
    String? activeFarmId,
  }) async {

    final body = {
      "message": message,
      "conversationId": conversationId,
      "activeFarmId": activeFarmId,
    };

    final response = await _apiClient.dio.post(
      '/chat', // FIXED
      data: body,
    );

    final data = response.data['data'];

    return RagChatResponse(
      reply: data['reply'],
      sources: List<String>.from(data['sources']),
      conversationId: data['conversationId'],
    );
  }
}
