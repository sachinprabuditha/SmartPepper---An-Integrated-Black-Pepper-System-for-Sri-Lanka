import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/conversation_provider.dart';
import '../models/conversation_model.dart';
import '../providers/message_provider.dart';

class ConversationSidebar extends ConsumerWidget {
  const ConversationSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync =
        ref.watch(conversationsProvider);

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
              ref.read(activeConversationProvider.notifier).state = null;
              ref.read(messagesProvider.notifier).clear();

              Navigator.pop(context);
            },
          ),

          const Divider(),

          /// CHAT LIST
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) => ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final convo = conversations[index];

                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(
                      convo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      ref
                          .read(activeConversationProvider.notifier)
                          .state = convo.id;
                      ref
                          .read(messagesProvider.notifier)
                          .loadMessages(convo.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
