import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../utils/city_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/chat_service.dart';
import 'chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetDetailScreen extends StatelessWidget {
  final Pet pet;

  const PetDetailScreen({
    Key? key,
    required this.pet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryOrange = Color(0xFFFF8C00);
    final Color darkGrey = Color(0xFF333333);
    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          pet.name,
          style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withOpacity(0.6),
                  builder: (context) => GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Center(
                      child: Hero(
                        tag: 'pet_image_${pet.id}',
                        child: FractionallySizedBox(
                          widthFactor: 0.95,
                          heightFactor: 0.85,
                          child: InteractiveViewer(
                            minScale: 0.7,
                            maxScale: 4.0,
                            child: Image.network(
                              pet.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.pets, color: Colors.white38, size: 120),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Hero(
                tag: 'pet_image_${pet.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: Image.network(
                    pet.imageUrl,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 300,
                      color: Colors.grey[800],
                      child: const Icon(Icons.pets, color: Colors.white38, size: 60),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pet.isUrgent)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACİL BAKIM İHTİYACI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  SizedBox(height: 18),
                  Text(
                    pet.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${pet.breed} - ${pet.age} yaşında',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: primaryOrange, size: 22),
                      SizedBox(width: 6),
                      Text(
                        CityUtils.getCityNameFromPlate(pet.location),
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 22),
                  Text(
                    'Açıklama',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    pet.description,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null || pet.uid == currentUser.uid) return;
                        final chatId = await ChatService().startOrGetChat(currentUser.uid, pet.uid);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatId,
                              otherUserId: pet.uid,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'İletişime Geç',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) return;
                        String? reason = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            String tempReason = '';
                            return AlertDialog(
                              backgroundColor: darkGrey,
                              title: Text('İlanı Raporla', style: TextStyle(color: primaryOrange)),
                              content: TextField(
                                autofocus: true,
                                maxLines: 3,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Rapor nedeninizi yazınız',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) => tempReason = val,
                              ),
                              actions: [
                                TextButton(
                                  child: Text('İptal', style: TextStyle(color: Colors.white70)),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
                                  child: Text('Gönder', style: TextStyle(color: Colors.white)),
                                  onPressed: () {
                                    if (tempReason.trim().isNotEmpty) {
                                      Navigator.pop(context, tempReason.trim());
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        );
                        if (reason != null && reason.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('reports').add({
                            'petId': pet.id,
                            'petName': pet.name,
                            'reportedBy': currentUser.uid,
                            'reportedByEmail': currentUser.email,
                            'reason': reason,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Raporunuz iletildi. Teşekkürler.'),
                              backgroundColor: primaryOrange,
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryOrange, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Raporla',
                        style: TextStyle(
                          color: primaryOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
