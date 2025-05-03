import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
              backgroundColor: primaryOrange,
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            title: Text(
              auth.currentUser?.displayName ?? 'Kullanıcı Adı',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            subtitle: Text(
              auth.currentUser?.email ?? 'E-posta',
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
            onTap: () {
              // Profil düzenleme sayfasına git
              Navigator.pop(context);
            },
          ),
          const Divider(color: Colors.white24),
          // Çıkış yap butonu
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () => handleSignOut(),
          ),
        ],
      ),
    );
  }
}
