import 'package:flutter/material.dart';
import '../../services/plantation_api_client.dart';
import '../models/chat_model.dart';
import '../models/conversation_model.dart';
import '../services/chat_service.dart';
import '../services/conversation_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final ConversationService _conversationService;

  ChatProvider()
      : _chatService = ChatService(PlantationApiClient()),
        _conversationService = ConversationService(PlantationApiClient()) {
    fetchConversations();
  }

  List<Conversation> _conversations = [];
  List<Conversation> get conversations => _conversations;

  bool _isLoadingConversations = false;
  bool get isLoadingConversations => _isLoadingConversations;

  String? _conversationsError;
  String? get conversationsError => _conversationsError;

  String? _activeConversationId;
  String? get activeConversationId => _activeConversationId;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  Future<void> fetchConversations() async {
    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      _conversations = await _conversationService.fetchConversations();
    } catch (e) {
      _conversationsError = e.toString();
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _activeConversationId = conversationId;
    _isLoadingMessages = true;
    notifyListeners();

    try {
      _messages = await _conversationService.fetchMessages(conversationId);
    } catch (e) {
      _messages = [
        ChatMessage(
            text: 'Error loading messages: $e',
            isUser: false,
            timestamp: DateTime.now())
      ];
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  void startNewChat() {
    _activeConversationId = null;
    _messages = [];
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> sendMessage(String text, String? activeFarmId) async {
    addMessage(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));

    try {
      final response = await _chatService.sendMessage(
        text,
        conversationId: _activeConversationId,
        activeFarmId: activeFarmId,
      );

      final isNewConversation = _activeConversationId == null;
      _activeConversationId = response.conversationId;

      if (isNewConversation) {
        fetchConversations();
      }

      addMessage(
        ChatMessage(
          text: response.reply,
          isUser: false,
          timestamp: DateTime.now(),
          sources: response.sources,
          suggestions: response.suggestions,
        ),
      );
    } catch (e) {
      addMessage(
        ChatMessage(
          text: "Error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    }
  }
}
