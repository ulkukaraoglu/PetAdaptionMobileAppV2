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
  final String uid;

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
    required this.uid,
  });

  factory Pet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle different types of createdAt field
    DateTime createdAt;
    final createdAtData = data['createdAt'];
    if (createdAtData is Timestamp) {
      createdAt = createdAtData.toDate();
    } else if (createdAtData is String) {
      try {
        createdAt = DateTime.parse(createdAtData);
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    // Handle location as int or String
    String location;
    final locationData = data['location'];
    if (locationData is int) {
      location = locationData.toString();
    } else if (locationData is String) {
      location = locationData;
    } else {
      location = '';
    }

    return Pet(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      breed: data['breed'] ?? '',
      age: data['age'] ?? 0,
      location: location,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      isUrgent: data['isUrgent'] ?? false,
      createdAt: createdAt,
      uid: data['uid'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'isUrgent': isUrgent,
      'createdAt': Timestamp.fromDate(createdAt),
      'uid': uid,
    };
  }
}
