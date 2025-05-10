import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // İki kullanıcı arasında chat başlat veya mevcutsa chatId döndür
  Future<String> startOrGetChat(String userId1, String userId2) async {
    final chats = await _firestore
        .collection('chats')
        .where('users', arrayContains: userId1)
        .get();
    for (var doc in chats.docs) {
      List users = doc['users'];
      if (users.contains(userId2)) {
        return doc.id;
      }
    }
    // Yoksa yeni chat oluştur
    final newChat = await _firestore.collection('chats').add({
      'users': [userId1, userId2],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
    return newChat.id;
  }

  // Belirli bir chat'in mesajlarını dinle
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Mesaj gönder
  Future<void> sendMessage(String chatId, Message message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
    // Chat dökümanını güncelle (son mesaj ve zaman)
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.text,
      'lastMessageTime': message.createdAt,
    });
  }
}
