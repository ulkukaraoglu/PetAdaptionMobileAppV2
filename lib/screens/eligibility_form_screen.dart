import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/eligibility_service.dart';
import 'eligibility_result_screen.dart';
import '../wrapper.dart';

class EligibilityFormScreen extends StatefulWidget {
  final String userId;

  const EligibilityFormScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _EligibilityFormScreenState createState() => _EligibilityFormScreenState();
}

class _EligibilityFormScreenState extends State<EligibilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int _age = 0;
  double _income = 0;
  String _housing = 'rent';
  bool _petExperience = false;
  String _familyStatus = 'single';

  // Controller'lar
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();

  final EligibilityService _eligibilityService = EligibilityService();

  @override
  void initState() {
    super.initState();
    _loadEligibilityData();
  }

  Future<void> _loadEligibilityData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            if (data['age'] != null) {
              _age = data['age'];
              _ageController.text = data['age'].toString();
            }
            if (data['income'] != null) {
              _income = data['income'].toDouble();
              _incomeController.text = data['income'].toString();
            }
            if (data['housing'] != null) {
              _housing = data['housing'];
            }
            if (data['petExperience'] != null) {
              _petExperience = data['petExperience'];
            }
            if (data['familyStatus'] != null) {
              _familyStatus = data['familyStatus'];
            }
          });
        }
      }
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  // Renk tanımlamaları
  final Color primaryOrange = Color(0xFFFF8C00);
  final Color darkGrey = Color(0xFF333333);

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Kullanıcı verilerini hazırla
        Map<String, dynamic> userData = {
          'age': _age,
          'income': _income,
          'housing': _housing,
          'petExperience': _petExperience,
          'familyStatus': _familyStatus,
          'eligibilityCompleted': true, // Uygunluk değerlendirmesinin tamamlandığını belirt
        };

        // Firestore'a kullanıcı verilerini güncelle
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update(userData);

        // Uygunluk değerlendirmesi yap
        final eligibilityResult = await _eligibilityService.evaluateEligibility(
          userId: widget.userId,
          userData: userData,
        );

        // Bildirim oluştur
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': widget.userId,
          'title': 'Uygunluk Testi Sonucu',
          'message': eligibilityResult['message'] ?? 'Uygunluk değerlendirme sonucunuz hazır.',
          'result': eligibilityResult['isEligible'] == true ? 'Geçti' : 'Geçemedi',
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
        });

        if (!mounted) return;

        // Uygunluk sonuçlarını göster
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EligibilityResultScreen(
              eligibilityResult: eligibilityResult,
            ),
          ),
        );

        // Her durumda ana sayfaya yönlendir
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      } catch (e) {
        print('Form gönderilirken hata: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form gönderilirken bir hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        title: Text(
          'Uygunluk Değerlendirmesi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evcil Hayvan Sahiplenme Uygunluğu',
                style: TextStyle(
                  color: primaryOrange,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Lütfen aşağıdaki bilgileri doldurun. Bu bilgiler, evcil hayvan sahiplenme uygunluğunuzu değerlendirmek için kullanılacaktır.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Yaş',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  hintText: 'Yaşınız',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yaş alanı boş bırakılamaz';
                  }
                  int? age = int.tryParse(value);
                  if (age == null || age < 18) {
                    return '18 yaşından büyük olmalısınız';
                  }
                  return null;
                },
                onSaved: (value) => _age = int.parse(value!),
              ),
              SizedBox(height: 16),
              Text(
                'Aylık Gelir (TL)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _incomeController,
                decoration: InputDecoration(
                  hintText: 'Aylık geliriniz',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Gelir alanı boş bırakılamaz';
                  }
                  double? income = double.tryParse(value);
                  if (income == null || income < 0) {
                    return 'Geçerli bir gelir giriniz';
                  }
                  return null;
                },
                onSaved: (value) => _income = double.parse(value!),
              ),
              SizedBox(height: 16),
              Text(
                'Barınma Durumu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _housing,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                dropdownColor: darkGrey,
                style: TextStyle(color: Colors.white),
                items: [
                  DropdownMenuItem(
                    value: 'own',
                    child: Text('Ev Sahibi'),
                  ),
                  DropdownMenuItem(
                    value: 'rent',
                    child: Text('Kiracı'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Diğer'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _housing = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              Text(
                'Daha önce evcil hayvan sahibi oldunuz mu?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _petExperience = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _petExperience ? primaryOrange : Colors.white.withOpacity(0.1),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Evet',
                        style: TextStyle(
                          color: _petExperience ? Colors.white : Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _petExperience = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_petExperience ? primaryOrange : Colors.white.withOpacity(0.1),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Hayır',
                        style: TextStyle(
                          color: !_petExperience ? Colors.white : Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Aile Durumu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _familyStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                dropdownColor: darkGrey,
                style: TextStyle(color: Colors.white),
                items: [
                  DropdownMenuItem(
                    value: 'single',
                    child: Text('Bekar'),
                  ),
                  DropdownMenuItem(
                    value: 'married',
                    child: Text('Evli'),
                  ),
                  DropdownMenuItem(
                    value: 'divorced',
                    child: Text('Boşanmış'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Diğer'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _familyStatus = value!;
                  });
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Değerlendirmeyi Başlat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 