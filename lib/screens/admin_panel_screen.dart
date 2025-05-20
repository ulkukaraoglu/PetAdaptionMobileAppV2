import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_reports_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color primaryOrange = const Color(0xFFFF6B00);
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcılar yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _toggleAdminStatus(String userId, bool currentStatus) async {
    try {
      final success = currentStatus
          ? await _adminService.removeAdmin(userId)
          : await _adminService.makeUserAdmin(userId);

      if (success) {
        await _loadUsers(); // Listeyi yenile
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentStatus
                  ? 'Admin yetkisi kaldırıldı'
                  : 'Kullanıcı admin yapıldı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İşlem başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePet(String petId, String userId) async {
    try {
      // Silme nedenini al
      final TextEditingController reasonController = TextEditingController();
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: darkGrey,
          title: const Text('İlanı Sil', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bu ilanı silmek istediğinizden emin misiniz?',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Silme Nedeni',
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lütfen silme nedenini belirtin'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              child: const Text('Sil'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // İlanı sil
      await FirebaseFirestore.instance.collection('pets').doc(petId).delete();

      // Kullanıcıya bildirim gönder
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'İlanınız Silindi',
        'message': 'İlanınız admin tarafından silindi. Neden: ${reasonController.text}',
        'type': 'pet_deleted',
        'petId': petId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('İlan silinirken hata: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İlan silinirken bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: darkGrey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Admin Paneli',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kullanıcılar'),
              Tab(text: 'İlanlar'),
              Tab(text: 'Raporlar'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            // Kullanıcılar Tab
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isAdmin = user['isAdmin'] == true;

                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['photoURL'] != null &&
                                      user['photoURL'].toString().isNotEmpty
                                  ? NetworkImage(user['photoURL'])
                                  : null,
                              child: user['photoURL'] == null ||
                                      user['photoURL'].toString().isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              user['name'] ?? 'İsimsiz Kullanıcı',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              user['email'] ?? 'E-posta yok',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Switch(
                              value: isAdmin,
                              onChanged: (value) =>
                                  _toggleAdminStatus(user['uid'], isAdmin),
                              activeColor: primaryOrange,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            // İlanlar Tab
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'İlanlarda ara...',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: primaryOrange),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    style: TextStyle(color: Colors.white),
                    onChanged: (val) {
                      setState(() {
                        _searchTerm = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('pets')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Bir hata oluştu: \\${snapshot.error}'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      final pets = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString().toLowerCase();
                        final desc = (data['description'] ?? '').toString().toLowerCase();
                        return _searchTerm.isEmpty ||
                            name.contains(_searchTerm) ||
                            desc.contains(_searchTerm);
                      }).toList();
                      if (pets.isEmpty) {
                        return const Center(
                          child: Text(
                            'Aramanıza uygun ilan yok',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index].data() as Map<String, dynamic>;
                          final petId = pets[index].id;
                          return Card(
                            color: Colors.white.withOpacity(0.1),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: pet['imageUrl'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        pet['imageUrl'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.pets, size: 40),
                              title: Text(
                                pet['name'] ?? 'İsimsiz',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: pet['uid'] != null
                                  ? FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance.collection('users').doc(pet['uid']).get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text('Sahibi: Yükleniyor...', style: TextStyle(color: Colors.white70));
                                        }
                                        if (!snapshot.hasData || !snapshot.data!.exists) {
                                          return const Text('Sahibi: Bilinmiyor', style: TextStyle(color: Colors.white70));
                                        }
                                        final userData = snapshot.data!.data() as Map<String, dynamic>;
                                        final userName = userData['name'] ?? userData['displayName'] ?? 'Bilinmiyor';
                                        return Text('Sahibi: $userName', style: const TextStyle(color: Colors.white70));
                                      },
                                    )
                                  : const Text('Sahibi: Bilinmiyor', style: TextStyle(color: Colors.white70)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePet(petId, pet['uid']),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            // Raporlar Tab
            AdminReportsScreen(),
          ],
        ),
      ),
    );
  }
} 