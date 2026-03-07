import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/plantation_api_client.dart';
import '../models/chat_model.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(PlantationApiClient());
});

class ChatService {
  final PlantationApiClient _client;

  ChatService(this._client);

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

    final response = await _client.dio.post(
      '/chat',
      data: body,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return RagChatResponse.fromJson(data);
  }
}
