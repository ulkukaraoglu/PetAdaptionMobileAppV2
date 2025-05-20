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
