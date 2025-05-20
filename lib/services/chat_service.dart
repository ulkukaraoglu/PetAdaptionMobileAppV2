import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Chat>> getChats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final chatDocs = await _firestore
          .collection('chats')
          .where('users', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final chats = <Chat>[];
      for (var doc in chatDocs.docs) {
        final data = doc.data();
        final chat = Chat.fromFirestore(data, doc.id);
        
        // Get other user's info
        final otherUserId = chat.users.firstWhere(
          (id) => id != currentUser.uid,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          final userDoc = await _firestore
              .collection('users')
              .where('uid', isEqualTo: otherUserId)
              .limit(1)
              .get();

          if (userDoc.docs.isNotEmpty) {
            final userData = userDoc.docs.first.data();
            chat.otherUserName = userData['name'] ?? otherUserId;
            chat.otherUserProfilePic = userData['photoURL'] ?? '';
          }
        }

        chats.add(chat);
      }

      return chats;
    } catch (e) {
      print('Error getting chats: $e');
      rethrow;
    }
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> sendMessage(String chatId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final messageData = {
        'senderId': currentUser.uid,
        'text': message,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update last message in chat document
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  Future<String> createChat(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Check if chat already exists
      final existingChats = await _firestore
          .collection('chats')
          .where('users', arrayContains: currentUser.uid)
          .get();

      for (var doc in existingChats.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        if (users.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new chat
      final chatData = {
        'users': [currentUser.uid, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('chats').add(chatData);
      return docRef.id;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Stream<int> getUnreadMessageCount(String chatId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUser.uid)
        .orderBy('senderId')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
} 