import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation_model.dart';
import '../services/conversation_service.dart';
import '../../services/plantation_api_client.dart';

/// Service provider
final conversationServiceProvider =
    Provider((ref) => ConversationService(PlantationApiClient()));

/// Fetch conversation list
final conversationsProvider =
    FutureProvider<List<Conversation>>((ref) async {
  final service = ref.read(conversationServiceProvider);
  return service.fetchConversations();
});

/// ACTIVE CHAT
final activeConversationProvider =
    StateProvider<String?>((ref) => null);
