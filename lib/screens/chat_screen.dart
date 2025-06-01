import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatScreen({Key? key, required this.chatId, required this.otherUserId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Color primaryOrange = const Color(0xFFFF8C00);
  final Color darkGrey = const Color(0xFF333333);
  final Color modalBackground = const Color(0xFF333333);

  String? otherUserName;
  String? otherUserPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchOtherUserName();
    ChatService().markMessagesAsRead(widget.chatId);
  }

  Future<void> _fetchOtherUserName() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: widget.otherUserId)
        .limit(1)
        .get();
    final doc = query.docs.isNotEmpty ? query.docs.first : null;
    setState(() {
      otherUserName = doc != null ? doc['name'] : widget.otherUserId;
      otherUserPhotoUrl = doc != null ? doc['photoURL'] : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: modalBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              backgroundImage: (otherUserPhotoUrl != null && otherUserPhotoUrl!.isNotEmpty)
                  ? NetworkImage(otherUserPhotoUrl!)
                  : null,
              child: (otherUserPhotoUrl == null || otherUserPhotoUrl!.isEmpty)
                  ? Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                otherUserName != null ? otherUserName! : 'Kullanıcı...',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: ChatService().getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  final currentUser = FirebaseAuth.instance.currentUser;
                  final unread = messages.any((msg) => !msg.isRead && msg.senderId != currentUser?.uid);
                  if (unread) {
                    ChatService().markMessagesAsRead(widget.chatId);
                  }
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Bir hata oluştu', style: TextStyle(color: Colors.white)));
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? primaryOrange : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(color: isMe ? Colors.white : Colors.white70, fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: darkGrey,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz...'
                          ,
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: primaryOrange),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty && currentUser != null) {
                      await ChatService().sendMessage(widget.chatId, text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 