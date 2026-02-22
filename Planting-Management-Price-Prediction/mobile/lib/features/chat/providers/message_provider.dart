import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/chat_model.dart';
import '../services/conversation_service.dart';

/// service
final conversationServiceProvider =
    Provider((ref) => ConversationService(ApiClient()));

/// message state
class MessageNotifier extends StateNotifier<List<ChatMessage>> {
  final ConversationService service;

  MessageNotifier(this.service) : super([]);

  /// load messages from backend
  Future<void> loadMessages(String conversationId) async {
    state = await service.fetchMessages(conversationId);
  }

  /// add message locally
  void add(ChatMessage message) {
    state = [...state, message];
  }

  /// clear for new chat
  void clear() {
    state = [];
  }
}

final messagesProvider =
    StateNotifierProvider<MessageNotifier, List<ChatMessage>>(
  (ref) => MessageNotifier(
    ref.read(conversationServiceProvider),
  ),
);
