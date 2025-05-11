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
import '../widgets/custom_app_bar.dart';
import '../widgets/pet_card.dart';
import '../services/pet_service.dart';
import 'add_pet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PetService _petService = PetService();
  List<Pet> _pets = [];
  bool _isLoading = true;
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color primaryOrange = const Color(0xFFFF6B00);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Filtre state değişkenleri ---
  String? selectedType; // 'Köpek', 'Kedi', 'Kuş', 'Diğer'
  String? selectedAge; // '0-1 yaş', '1-3 yaş', '3-5 yaş', '5+ yaş'
  String location = '';
  bool urgentOnly = false;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() => _isLoading = true);
    try {
      final pets = await _petService.getPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pets could not be loaded: $e')),
        );
      }
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
    return Scaffold(
      backgroundColor: darkGrey,
      appBar: CustomAppBar(
        title: 'Pet Adoption',
        showProfileMenu: _showProfileMenu,
        darkGrey: darkGrey,
        primaryOrange: primaryOrange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPets,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 sütun
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7, // Kart oranı, isteğe göre ayarlanabilir
                ),
                itemCount: _pets.length,
                itemBuilder: (context, index) {
                  final pet = _pets[index];
                  return PetCard(
                    pet: pet,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailScreen(pet: pet),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryOrange,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPetScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        darkGrey: darkGrey,
        primaryOrange: primaryOrange,
      ),
    );
  }
}
