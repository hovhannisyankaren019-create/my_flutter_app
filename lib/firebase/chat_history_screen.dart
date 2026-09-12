import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../spiritual_ai/spiritual_ai_screen.dart';
import 'chat_firestore_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService();

  @override
  void initState() {
    super.initState();
    _chatService.cleanupExpiredChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Նախորդ զրույցներ'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _chatService.streamChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Չհաջողվեց բեռնել զրույցները։'),
            );
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Text('Դեռևս պահպանված զրույցներ չկան։'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data();

              final title = data['title'] as String? ?? 'Նոր զրույց';
              final pinned = data['pinned'] as bool? ?? false;

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.chat),
                  ),
                  title: Text(title),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip:
                            pinned ? 'Հանել հավերժ պահումը' : 'Պահել հավերժ',
                        icon: Icon(
                          pinned ? Icons.push_pin : Icons.push_pin_outlined,
                        ),
                        onPressed: () async {
                          try {
                            await _chatService.setChatPinned(
                              chatId: chat.id,
                              pinned: !pinned,
                            );
                          } catch (_) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Չհաջողվեց փոխել զրույցի պահման կարգավիճակը։',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              return AlertDialog(
                                title: const Text('Ջնջել զրույցը'),
                                content: const Text(
                                  'Վստա՞հ եք, որ ուզում եք ջնջել այս զրույցը։',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext, false);
                                    },
                                    child: const Text('Չեղարկել'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext, true);
                                    },
                                    child: const Text('Ջնջել'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldDelete != true) return;

                          try {
                            await _chatService.deleteChat(chat.id);
                          } catch (_) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Չհաջողվեց ջնջել զրույցը։',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpiritualAiScreen(
                          chatId: chat.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
