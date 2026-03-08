import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_model.dart';
import '../services/conversation_service.dart';
import '../../../core/network/api_client.dart';

/// Service provider
final conversationServiceProvider =
    Provider((ref) => ConversationService(ApiClient()));

/// Fetch conversation list
final conversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  final service = ref.read(conversationServiceProvider);
  return service.fetchConversations();
});

/// ACTIVE CHAT (THIS WAS MISSING)
final activeConversationProvider =
    StateProvider<String?>((ref) => null);
