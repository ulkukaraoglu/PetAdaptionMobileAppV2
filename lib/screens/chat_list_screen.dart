import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import 'chat_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/add_pet_fab.dart';

class ChatListScreen extends StatelessWidget {
  final Color primaryOrange = const Color(0xFFFF8C00);
  final Color darkGrey = const Color(0xFF333333);
  final Color modalBackground = const Color(0xFF333333);

  ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: modalBackground,
        body: Center(child: Text('Giriş yapmalısınız', style: TextStyle(color: Colors.white))),
      );
    }
    return Scaffold(
      backgroundColor: modalBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sohbetler',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('ChatListScreen hata: ${snapshot.error}');
            return Center(child: Text('Bir hata oluştu', style: TextStyle(color: Colors.white)));
          }
          final chatDocs = snapshot.data?.docs ?? [];
          if (chatDocs.isEmpty) {
            return Center(child: Text('Hiç sohbetiniz yok', style: TextStyle(color: Colors.white70)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final data = chatDocs[index].data() as Map<String, dynamic>;
              final chat = Chat.fromFirestore(data, chatDocs[index].id);
              final otherUserId = chat.users.firstWhere((id) => id != currentUser.uid, orElse: () => '');

              return FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where('uid', isEqualTo: otherUserId)
                    .limit(1)
                    .get()
                    .then((q) => q.docs.isNotEmpty ? q.docs.first : null),
                builder: (context, userSnapshot) {
                  String userName = otherUserId;
                  String? photoUrl;
                  if (userSnapshot.hasData && userSnapshot.data != null) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    userName = userData['name'] ?? otherUserId;
                    photoUrl = userData['photoURL'];
                  }
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: chat.id, otherUserId: otherUserId),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryOrange.withOpacity(0.8),
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  chat.lastMessage,
                                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            chat.lastMessageTime != null
                                ? _formatTime(chat.lastMessageTime)
                                : '',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: AddPetFAB(primaryOrange: primaryOrange),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        showProfileMenu: () {},
        darkGrey: darkGrey,
        primaryOrange: primaryOrange,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inDays == 0) {
      // Bugün ise saat:dakika
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}' ;
    } else {
      // Değilse gün/ay
      return '${dateTime.day}.${dateTime.month}';
    }
  }
} 