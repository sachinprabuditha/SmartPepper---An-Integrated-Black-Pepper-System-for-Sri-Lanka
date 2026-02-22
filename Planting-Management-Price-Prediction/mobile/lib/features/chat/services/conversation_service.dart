import '../../../core/network/api_client.dart';
import '../models/conversation_model.dart';
import '../models/chat_model.dart';

class ConversationService {
  final ApiClient _api;

  ConversationService(this._api);

  /// ===============================
  /// GET CONVERSATIONS
  /// ===============================
  Future<List<Conversation>> fetchConversations() async {
    final response =
        await _api.dio.get('/chat/conversations');

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
    final response = await _api.dio.get(
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
