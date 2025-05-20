import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/admin_panel_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/eligibility_form_screen.dart';
import '../services/admin_service.dart';

class ProfileMenu extends StatefulWidget {
  final Function handleSignOut;
  final Color darkGrey;
  final Color primaryOrange;
  final FirebaseAuth auth;

  const ProfileMenu({
    Key? key,
    required this.handleSignOut,
    required this.darkGrey,
    required this.primaryOrange,
    required this.auth,
  }) : super(key: key);

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  final AdminService _adminService = AdminService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _adminService.isAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<Map<String, dynamic>> _getUserData() async {
    final userId = widget.auth.currentUser?.uid;
    if (userId == null) return {};

    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final doc = await docRef.get();
    if (!doc.exists) {
      final userData = {
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': widget.auth.currentUser?.displayName ?? '',
        'email': widget.auth.currentUser?.email ?? '',
        'isAdmin': false,
        'lastLogin': FieldValue.serverTimestamp(),
        'name': widget.auth.currentUser?.displayName ?? '',
        'photoURL': widget.auth.currentUser?.photoURL ?? '',
        'provider': 'email',
        'uid': userId,
      };
      await docRef.set(userData);
      return userData;
    }
    return doc.data() ?? {};
  }

  void _navigateToProfileEdit(BuildContext context) async {
    try {
      // Kullanıcı verilerini al
      final userData = await _getUserData();
      
      // Context'in hala geçerli olduğundan emin ol
      if (!context.mounted) return;
      
      // Önce menüyü kapat
      Navigator.pop(context);
      
      // Profil düzenleme sayfasına yönlendir
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileEditScreen(userData: userData),
        ),
      );
    } catch (e) {
      print('Profil düzenleme sayfasına yönlendirme hatası: $e');
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil düzenleme sayfası açılırken bir hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profil başlığı
            const Text(
              'Profil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Kullanıcı bilgileri
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: widget.primaryOrange,
                backgroundImage: (widget.auth.currentUser?.photoURL != null && widget.auth.currentUser!.photoURL!.isNotEmpty)
                    ? NetworkImage(widget.auth.currentUser!.photoURL!)
                    : null,
                child: (widget.auth.currentUser?.photoURL == null || widget.auth.currentUser!.photoURL!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 30)
                    : null,
              ),
              title: Text(
                widget.auth.currentUser?.displayName ?? 'Kullanıcı Adı',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              subtitle: Text(
                widget.auth.currentUser?.email ?? 'E-posta',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            const Divider(color: Colors.white24),
            // Menü seçenekleri
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                'Profili Düzenle',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _navigateToProfileEdit(context),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in, color: Colors.white),
              title: const Text(
                'Uygunluk Bilgilerini Güncelle',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final userId = widget.auth.currentUser?.uid;
                if (userId != null) {
                  Navigator.pop(context); // Menüyü kapat
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EligibilityFormScreen(userId: userId),
                    ),
                  );
                }
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.white),
              title: const Text(
                'Bildirimler',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context); // Menüyü kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(),
                  ),
                );
              },
            ),
            if (_isAdmin) ...[
              const Divider(color: Colors.white24),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.white),
                title: const Text(
                  'Admin Paneli',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Menüyü kapat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminPanelScreen(),
                    ),
                  );
                },
              ),
            ],
            const Divider(color: Colors.white24),
            // Çıkış yap butonu
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: () => widget.handleSignOut(),
            ),
          ],
        ),
      ),
    );
  }
}
