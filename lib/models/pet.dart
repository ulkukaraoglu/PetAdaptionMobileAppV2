import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String type;
  final String breed;
  final int age;
  final String location;
  final String description;
  final String imageUrl;
  final bool isUrgent;
  final DateTime createdAt;
  final String ownerId;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.isUrgent,
    required this.createdAt,
    required this.ownerId,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      location: data['location'] != null ? data['location'].toString() : '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isUrgent: data['isUrgent'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      ownerId: data['ownerId'] ?? '',
    );
  }
}
