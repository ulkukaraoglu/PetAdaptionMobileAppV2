import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EligibilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı uygunluk değerlendirmesi için gerekli faktörler
  Future<Map<String, dynamic>> evaluateEligibility({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Kullanıcı verilerini analiz et
      double score = 0;
      Map<String, dynamic> analysis = {};

      // Yaş kontrolü
      if (userData['age'] != null) {
        int age = userData['age'];
        if (age >= 18) {
          score += 20;
          analysis['age'] = 'Uygun';
        } else {
          analysis['age'] = '18 yaşından küçükler evcil hayvan sahiplenemez';
        }
      }

      // Gelir durumu kontrolü
      if (userData['income'] != null) {
        double income = userData['income'].toDouble();
        if (income >= 5000) {
          score += 20;
          analysis['income'] = 'Uygun';
        } else {
          analysis['income'] = 'Gelir durumu yetersiz';
        }
      }

      // Ev durumu kontrolü
      if (userData['housing'] != null) {
        String housing = userData['housing'];
        if (housing == 'own' || housing == 'rent') {
          score += 20;
          analysis['housing'] = 'Uygun';
        } else {
          analysis['housing'] = 'Uygun barınma koşulları yok';
        }
      }

      // Daha önce evcil hayvan deneyimi
      if (userData['petExperience'] != null) {
        bool hasExperience = userData['petExperience'];
        if (hasExperience) {
          score += 20;
          analysis['experience'] = 'Uygun';
        } else {
          analysis['experience'] = 'Deneyim yok';
        }
      }

      // Aile durumu kontrolü
      if (userData['familyStatus'] != null) {
        String familyStatus = userData['familyStatus'];
        if (familyStatus == 'single' || familyStatus == 'married') {
          score += 20;
          analysis['familyStatus'] = 'Uygun';
        } else {
          analysis['familyStatus'] = 'Aile durumu uygun değil';
        }
      }

      // Sonuçları Firestore'a kaydet
      await _firestore.collection('eligibility_results').doc(userId).set({
        'score': score,
        'analysis': analysis,
        'isEligible': score >= 60,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return {
        'score': score,
        'analysis': analysis,
        'isEligible': score >= 60,
      };
    } catch (e) {
      print('Eligibility evaluation error: $e');
      throw Exception('Uygunluk değerlendirmesi yapılırken bir hata oluştu');
    }
  }

  // Kullanıcının uygunluk durumunu getir
  Future<Map<String, dynamic>?> getEligibilityStatus(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('eligibility_results')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Get eligibility status error: $e');
      throw Exception('Uygunluk durumu alınırken bir hata oluştu');
    }
  }
} 