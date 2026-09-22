import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return user.uid;
  }

  Future<String> createChat({
    String title = 'Նոր զրույց',
  }) async {
    final chatRef = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 15)),
      ),
      'pinned': false,
    });

    return chatRef.id;
  }

  Future<void> setChatPinned({
    required String chatId,
    required bool pinned,
  }) async {
    final chatRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .doc(chatId);

    final newExpiry = pinned
        ? null
        : Timestamp.fromDate(DateTime.now().add(const Duration(days: 15)));

    await chatRef.update({
      'pinned': pinned,
      'expiresAt': newExpiry,
    });

    final messages = await chatRef.collection('messages').get();
    final batch = _firestore.batch();
    for (final msg in messages.docs) {
      batch.update(msg.reference, {'expiresAt': newExpiry});
    }
    await batch.commit();
  }

  Future<void> cleanupExpiredChats() async {
    final now = Timestamp.now();

    final expiredChats = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .where('expiresAt', isLessThanOrEqualTo: now)
        .get();

    if (expiredChats.docs.isEmpty) return;

    for (final chatDoc in expiredChats.docs) {
      final messages = await chatDoc.reference.collection('messages').get();

      final batch = _firestore.batch();

      for (final message in messages.docs) {
        batch.delete(message.reference);
      }

      batch.delete(chatDoc.reference);

      await batch.commit();
    }
  }

  Future<void> saveMessage({
    required String chatId,
    required String text,
    required String role,
  }) async {
    final chatDoc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .doc(chatId)
        .get();

    final pinned = chatDoc.data()?['pinned'] as bool? ?? false;

    await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': pinned
          ? null
          : Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamChats() {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(
    String chatId,
  ) {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> deleteChat(String chatId) async {
    final messages = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();

    for (final message in messages.docs) {
      batch.delete(message.reference);
    }

    batch.delete(
      _firestore.collection('users').doc(_uid).collection('chats').doc(chatId),
    );

    await batch.commit();
  }
}
