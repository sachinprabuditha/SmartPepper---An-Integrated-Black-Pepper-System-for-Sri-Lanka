import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../widgets/conversation_sidebar.dart';
import '../providers/conversation_provider.dart';
import '../providers/message_provider.dart';

// Farm Logic
import '../../plantation/controllers/plantation_controller.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _selectedFarmId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ===============================
  /// SEND MESSAGE
  /// ===============================
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final activeConversationId =
        ref.read(activeConversationProvider);

    _controller.clear();

    /// Add user message instantly
    ref.read(messagesProvider.notifier).add(
          ChatMessage(
            text: text,
            isUser: true,
            timestamp: DateTime.now(),
          ),
        );

    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      final chatService = ref.read(chatServiceProvider);

      final response = await chatService.sendMessage(
        text,
        conversationId: activeConversationId,
        activeFarmId: _selectedFarmId,
      );

      /// update active conversation automatically
      final isNewConversation = activeConversationId == null;
      ref.read(activeConversationProvider.notifier).state =
          response.conversationId;

      if (isNewConversation) {
        ref.invalidate(conversationsProvider);
      }

      /// add assistant message
      ref.read(messagesProvider.notifier).add(
            ChatMessage(
              text: response.reply,
              isUser: false,
              timestamp: DateTime.now(),
              sources: response.sources,
              suggestions: response.suggestions,
            ),
          );
    } catch (e) {
      ref.read(messagesProvider.notifier).add(
            ChatMessage(
              text: "Error: $e",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(farmsProvider);

    /// ⭐ messages now come from provider
    final messages = ref.watch(messagesProvider);

    return Scaffold(
      drawer: const ConversationSidebar(),

      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('AI Assistant'),
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: Colors.white,
        actions: [
          farmsAsync.when(
            data: (farms) {
              if (farms.isEmpty) return const SizedBox.shrink();

              return DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  dropdownColor: AppTheme.deepEmerald,
                  icon:
                      const Icon(Icons.arrow_drop_down, color: Colors.white),
                  value: _selectedFarmId,
                  hint: const Text("Mode: Guide",
                      style: TextStyle(color: Colors.white70)),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        "Mode: Guide (General)",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ...farms.map(
                      (f) => DropdownMenuItem<String?>(
                        value: f.id,
                        child: Text(
                          "Mode: ${f.farmName}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFarmId = value);
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 16),
        ],
      ),

      body: Column(
        children: [
          /// MODE INDICATOR
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color: _selectedFarmId == null
                ? Colors.blueGrey[100]
                : Colors.green[100],
            child: Text(
              _selectedFarmId == null
                  ? "🌱 Guide Mode: General agronomy advice only."
                  : "🌿 Farmer Mode: Advice tailored to this farm.",
              style: TextStyle(
                fontSize: 12,
                color: _selectedFarmId == null
                    ? Colors.blueGrey[800]
                    : Colors.green[800],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          /// CHAT LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          _buildInputArea(),
        ],
      ),
    );
  }

  /// ===============================
  /// MESSAGE BUBBLE
  /// ===============================
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isUser ? AppTheme.pepperGold : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),

            /// SOURCES
            if (!isUser &&
                msg.sources != null &&
                msg.sources!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sources",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    ...msg.sources!.map(
                      (s) => Text(
                        "• $s",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  ],
                ),
              ),

            /// SUGGESTIONS
            if (!isUser && msg.suggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: msg.suggestions.map((s) {
                    return ActionChip(
                      label: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        _controller.text = s;
                        _sendMessage();
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// INPUT AREA
  /// ===============================
  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: _selectedFarmId == null
                    ? 'Ask about black pepper...'
                    : 'Ask about your farm...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: AppTheme.pepperGold,
          ),
        ],
      ),
    );
  }
}
