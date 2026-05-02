import '../../services/plantation_api_client.dart';
import '../models/chat_model.dart';

class ChatService {
  final PlantationApiClient _client;

  ChatService(this._client);

  Future<RagChatResponse> sendMessage(
    String message, {
    String? conversationId,
    String? activeFarmId,
    String? language,
  }) async {
    final body = {
      "message": message,
      "conversationId": conversationId,
      "activeFarmId": activeFarmId,
      "language": language ?? "en",
    };

    final response = await _client.dio.post(
      '/chat',
      data: body,
    );

    final data = response.data['data'] as Map<String, dynamic>;
    return RagChatResponse.fromJson(data);
  }
}
