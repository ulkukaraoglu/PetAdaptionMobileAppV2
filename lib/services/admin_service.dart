import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının admin olup olmadığını kontrol et
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;

    final data = doc.data();
    return data?['isAdmin'] == true;
  }

  // Tüm kullanıcıları getir (sadece adminler için)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    if (!await isAdmin()) return [];

    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Kullanıcıyı admin yap
  Future<bool> makeUserAdmin(String userId) async {
    if (!await isAdmin()) return false;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
      });
      return true;
    } catch (e) {
      print('Kullanıcı admin yapılırken hata: $e');
      return false;
    }
  }

  // Kullanıcının admin yetkisini kaldır
  Future<bool> removeAdmin(String userId) async {
    if (!await isAdmin()) return false;

    try {
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
      });
      return true;
    } catch (e) {
      print('Admin yetkisi kaldırılırken hata: $e');
      return false;
    }
  }
} 