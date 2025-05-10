import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../wrapper.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/profile_menu.dart';
import '../widgets/add_pet_fab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';
import '../utils/city_utils.dart';
import 'pet_detail_screen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Renk tanımlamaları
  final Color primaryOrange = Color(0xFFFF8C00);
  final Color darkGrey = Color(0xFF333333);
  final Color modalBackground = Color(0xFF333333).withOpacity(0.95);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Filtre state değişkenleri ---
  String? selectedType; // 'Köpek', 'Kedi', 'Kuş', 'Diğer'
  String? selectedAge; // '0-1 yaş', '1-3 yaş', '3-5 yaş', '5+ yaş'
  String location = '';
  bool urgentOnly = false;

  Stream<List<Pet>> get petsStream {
    try {
      print('Firestore bağlantısı başlatılıyor...');
      return FirebaseFirestore.instance
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              print('Döküman sayısı: ${snapshot.docs.length}');
              final pets = snapshot.docs.map((doc) {
                print('Döküman ID: ${doc.id}');
                print('Döküman verisi: ${doc.data()}');
                return Pet.fromFirestore(doc);
              }).toList();
              print('Dönüştürülen pet sayısı: ${pets.length}');
              return pets;
            } catch (e) {
              print('Veri dönüştürme hatası: $e');
              return <Pet>[];
            }
          });
    } catch (e) {
      print('Firestore bağlantı hatası: $e');
      return Stream.value(<Pet>[]);
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
          content:
              Text('Çıkış yapılırken bir hata oluştu. Lütfen tekrar deneyin.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Filtreleme bottom sheet'i
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Geçici controller ile konum filtresi
        TextEditingController locationController = TextEditingController(
          text: location,
        );
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Filtrele',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Colors.white24),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Text(
                            'Tür',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              for (var type in [
                                'Köpek',
                                'Kedi',
                                'Kuş',
                                'Diğer',
                              ])
                                FilterChip(
                                  label: Text(
                                    type,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  selected: selectedType == type,
                                  onSelected: (val) {
                                    setModalState(
                                      () => selectedType = val ? type : null,
                                    );
                                    setState(
                                      () => selectedType = val ? type : null,
                                    );
                                  },
                                  backgroundColor: darkGrey.withOpacity(0.85),
                                  selectedColor: primaryOrange,
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Text(
                            'Yaş Aralığı',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              for (var age in [
                                '0-1 yaş',
                                '1-3 yaş',
                                '3-5 yaş',
                                '5+ yaş',
                              ])
                                FilterChip(
                                  label: Text(
                                    age,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  selected: selectedAge == age,
                                  onSelected: (val) {
                                    setModalState(
                                      () => selectedAge = val ? age : null,
                                    );
                                    setState(
                                      () => selectedAge = val ? age : null,
                                    );
                                  },
                                  backgroundColor: darkGrey.withOpacity(0.85),
                                  selectedColor: primaryOrange,
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Text(
                            'Konum',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            controller: locationController,
                            decoration: InputDecoration(
                              hintText: 'Şehir veya ilçe girin',
                              hintStyle: TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                            onChanged: (val) {
                              setModalState(() => location = val);
                              setState(() => location = val);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: SwitchListTile(
                            title: Text(
                              'Sadece acil durumdaki hayvanları göster',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: urgentOnly,
                            onChanged: (val) {
                              setModalState(() => urgentOnly = val);
                              setState(() => urgentOnly = val);
                            },
                            activeColor: primaryOrange,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      selectedType = null;
                                      selectedAge = null;
                                      location = '';
                                      urgentOnly = false;
                                      locationController.text = '';
                                    });
                                    setState(() {
                                      selectedType = null;
                                      selectedAge = null;
                                      location = '';
                                      urgentOnly = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white),
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text('Filtreleri Temizle'),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryOrange,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: Text('Filtrele'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Profil menüsünü göster
  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProfileMenu(
        handleSignOut: _handleSignOut,
        darkGrey: darkGrey,
        primaryOrange: primaryOrange,
        auth: _auth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ChatListScreen build edildi');
    return Scaffold(
      backgroundColor: modalBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Pet Adoption',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.message, color: Colors.white),
        //     onPressed: () {
        //       print('Chat ikonuna basıldı');
        //       Navigator.of(context, rootNavigator: true).push(
        //         MaterialPageRoute(builder: (context) => ChatListScreen()),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Arama ve filtreleme satırı
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Arama çubuğu
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Evcil hayvan ara...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Filtreleme butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _showFilterBottomSheet,
                    ),
                  ),
                ],
              ),
            ),
            // Evcil hayvan listesi
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Stream'i yeniden başlatmak için setState kullanıyoruz
                  setState(() {});
                },
                child: StreamBuilder<List<Pet>>(
                  stream: petsStream,
                  builder: (context, snapshot) {
                    print('StreamBuilder durumu: ${snapshot.connectionState}');
                    if (snapshot.hasError) {
                      print('StreamBuilder hatası: ${snapshot.error}');
                      return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Bir hata oluştu',
                                  style: TextStyle(color: Colors.white)),
                              SizedBox(height: 8),
                              Text(snapshot.error.toString(),
                                  style: TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center),
                            ],
                          ));
                    }
                    final pets = snapshot.data ?? [];
                    print('StreamBuilder veri sayısı: ${pets.length}');
                    if (pets.isEmpty) {
                      return Center(
                          child: Text('Hiç ilan yok',
                              style: TextStyle(color: Colors.white)));
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PetDetailScreen(pet: pet),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    pet.imageUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      height: 120,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.pets,
                                        color: Colors.white38,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pet.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${pet.age} yaş',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            CityUtils.getCityNameFromPlate(
                                                pet.location),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (pet.isUrgent)
                                            const Icon(
                                              Icons.warning,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AddPetFAB(primaryOrange: primaryOrange),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        showProfileMenu: _showProfileMenu,
        darkGrey: darkGrey,
        primaryOrange: primaryOrange,
      ),
    );
  }
}
