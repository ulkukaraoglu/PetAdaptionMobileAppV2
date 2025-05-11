import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Pet>> getPets() async {
    try {
      final petDocs = await _firestore
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .get();

      return petDocs.docs.map((doc) => Pet.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting pets: $e');
      rethrow;
    }
  }

  Future<void> addPet(Pet pet) async {
    try {
      await _firestore.collection('pets').add(pet.toFirestore());
    } catch (e) {
      print('Error adding pet: $e');
      rethrow;
    }
  }

  Future<void> updatePet(String petId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('pets').doc(petId).update(data);
    } catch (e) {
      print('Error updating pet: $e');
      rethrow;
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      await _firestore.collection('pets').doc(petId).delete();
    } catch (e) {
      print('Error deleting pet: $e');
      rethrow;
    }
  }

  Stream<List<Pet>> getPetsStream() {
    return _firestore
        .collection('pets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Pet.fromFirestore(doc)).toList();
        });
  }
} 