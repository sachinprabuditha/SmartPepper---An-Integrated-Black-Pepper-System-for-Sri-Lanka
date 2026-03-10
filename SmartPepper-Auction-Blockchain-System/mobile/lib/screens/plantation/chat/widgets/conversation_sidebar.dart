import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ConversationSidebar extends StatelessWidget {
  const ConversationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            child: Text(
              "Your Chats",
              style: TextStyle(fontSize: 20),
            ),
          ),

          /// NEW CHAT BUTTON
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("New Chat"),
            onTap: () {
              chatProvider.startNewChat();
              Navigator.pop(context);
            },
          ),

          const Divider(),

          /// CHAT LIST
          Expanded(
            child: chatProvider.isLoadingConversations
                ? const Center(child: CircularProgressIndicator())
                : chatProvider.conversationsError != null
                    ? Center(child: Text(chatProvider.conversationsError!))
                    : ListView.builder(
                        itemCount: chatProvider.conversations.length,
                        itemBuilder: (context, index) {
                          final convo = chatProvider.conversations[index];

                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(
                              convo.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              chatProvider.loadMessages(convo.id);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
