import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> users;
  final String lastMessage;
  final DateTime lastMessageTime;

  Chat({
    required this.id,
    required this.users,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory Chat.fromFirestore(Map<String, dynamic> data, String id) {
    return Chat(
      id: id,
      users: List<String>.from(data['users'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] is Timestamp)
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
    };
  }
}
