import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

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
        .orderBy('timestamp', descending: true)
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
        'timestamp': FieldValue.serverTimestamp(),
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
} 