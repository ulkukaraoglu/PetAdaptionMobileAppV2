import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import 'chat_screen.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/add_pet_fab.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'add_pet_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../wrapper.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  List<Chat> _chats = [];
  bool _isLoading = true;
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color primaryOrange = const Color(0xFFFF6B00);

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final chats = await _chatService.getChats();
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chats could not be loaded: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Bugün ise saat:dakika
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      // 1 haftadan eski ise gün/ay
      return '${dateTime.day}.${dateTime.month}';
    }
  }

  // Çıkış yapma fonksiyonu
  Future<void> _handleSignOut() async {
    try {
      // Önce Google oturumunu kontrol et ve kapat
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      }

      // Firebase oturumunu kapat
      await FirebaseAuth.instance.signOut();

      // SharedPreferences'ı temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      // Ana sayfaya yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      print('Çıkış yaparken hata: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkış yapılırken bir hata oluştu. Lütfen tekrar deneyin.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mesajlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChats,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chats.length,
                itemBuilder: (context, index) {
                  final chat = _chats[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: StreamBuilder<int>(
                      stream: _chatService.getUnreadMessageCount(chat.id),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: (chat.otherUserProfilePic.isNotEmpty)
                                    ? NetworkImage(chat.otherUserProfilePic)
                                    : null,
                                child: (chat.otherUserProfilePic.isEmpty)
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryOrange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            chat.otherUserName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            chat.lastMessage,
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatTime(chat.lastMessageTime),
                            style: TextStyle(
                              color: unreadCount > 0 ? primaryOrange : Colors.white54,
                              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(chat: chat),
                              ),
                            );
                            _loadChats();
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: AddPetFAB(
        primaryOrange: primaryOrange,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        darkGrey: darkGrey,
        primaryOrange: primaryOrange,
        handleSignOut: _handleSignOut,
      ),
    );
  }
} 