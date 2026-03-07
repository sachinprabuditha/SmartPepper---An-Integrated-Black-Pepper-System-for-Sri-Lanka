import '../../services/plantation_api_client.dart';
import '../models/conversation_model.dart';
import '../models/chat_model.dart';

class ConversationService {
  final PlantationApiClient _client;

  ConversationService(this._client);

  /// ===============================
  /// GET CONVERSATIONS
  /// ===============================
  Future<List<Conversation>> fetchConversations() async {
    final response =
        await _client.dio.get('/chat/conversations');

    final List list = response.data['data'];

    return list
        .map((e) => Conversation.fromJson(e))
        .toList();
  }

  /// ===============================
  /// GET MESSAGES
  /// ===============================
  Future<List<ChatMessage>> fetchMessages(
      String conversationId) async {
    final response = await _client.dio.get(
      '/chat/conversations/$conversationId/messages',
    );

    final List list = response.data['data'];

    return list.map((m) {
      return ChatMessage(
        text: m['content'],
        isUser: m['role'] == 'user',
        timestamp: DateTime.parse(m['timestamp']),
        sources: m['sources'] != null
            ? List<String>.from(m['sources'])
            : [],
      );
    }).toList();
  }
}
