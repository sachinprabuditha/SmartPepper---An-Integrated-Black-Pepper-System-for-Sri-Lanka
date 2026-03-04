class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? sources;
  final bool isLoading;
  final List<String> suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
    this.isLoading = false,
    this.suggestions = const [],
  });
}

class RagChatRequest {
  final String message;
  final String? activeFarmId;

  RagChatRequest({
    required this.message,
    this.activeFarmId,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'activeFarmId': activeFarmId,
      };
}

class RagChatResponse {
  final String reply;
  final List<String> sources;
  final String conversationId;
  final List<String> suggestions;

  RagChatResponse({
    required this.reply,
    required this.sources,
    required this.conversationId,
    this.suggestions = const [],
  });

  factory RagChatResponse.fromJson(Map<String, dynamic> json) {
    return RagChatResponse(
      reply: json['reply'] ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      conversationId: json['conversationId'] ?? '',
      suggestions: List<String>.from(
        json['suggestions'] ?? [],
      ),
    );
  }
}
