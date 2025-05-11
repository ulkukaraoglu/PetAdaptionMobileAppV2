import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> users;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final DateTime? createdAt;
  String otherUserName;
  String otherUserProfilePic;

  Chat({
    required this.id,
    required this.users,
    required this.lastMessage,
    this.lastMessageTime,
    this.createdAt,
    this.otherUserName = '',
    this.otherUserProfilePic = '',
  });

  factory Chat.fromFirestore(Map<String, dynamic> data, String id) {
    return Chat(
      id: id,
      users: List<String>.from(data['users'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'users': users,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}

class Message {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
  });

  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    };
  }
}
