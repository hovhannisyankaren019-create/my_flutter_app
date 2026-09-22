import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.bg(isDark),
        title: Text(
          'Նախորդ զրույցներ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.text(isDark),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Նոր նամակագրություն',
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.text(isDark),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _chatService.streamChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.forest),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: Text(
                  'Չհաջողվեց բեռնել զրույցները։',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text(isDark)),
                ),
              ),
            );
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Center(
                child: Text(
                  'Դեռևս պահպանված զրույցներ չկան։',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.4,
                    color: AppColors.muted(isDark),
                  ),
                ),
              ),
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

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkForest : AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isDark ? AppColors.olive : AppColors.lightChip,
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.text(isDark),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.text(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
