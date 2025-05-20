import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/pet.dart';
import 'pet_detail_screen.dart';

class AdminReportsScreen extends StatelessWidget {
  final Color darkGrey = const Color(0xFF2C2C2C);
  final Color primaryOrange = const Color(0xFFFF6B00);

  AdminReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Gelen Raporlar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: \\${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data!.docs;
          if (reports.isEmpty) {
            return const Center(
              child: Text('Hiç rapor yok', style: TextStyle(color: Colors.white70)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index].data() as Map<String, dynamic>;
              final date = (report['timestamp'] as Timestamp?)?.toDate();
              final formattedDate = date != null ? DateFormat('dd.MM.yyyy HH:mm').format(date) : '';
              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  title: Text(
                    report['petName'] != null ? 'İlan: ' + report['petName'] : 'İlan Raporu',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('Raporlayan: ' + (report['reportedByEmail'] ?? ''), style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text('Sebep: ' + (report['reason'] ?? ''), style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(formattedDate, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  onTap: () async {
                    final petId = report['petId'];
                    if (petId != null) {
                      final doc = await FirebaseFirestore.instance.collection('pets').doc(petId).get();
                      if (doc.exists) {
                        final pet = Pet.fromFirestore(doc);
                        // ignore: use_build_context_synchronously
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetDetailScreen(pet: pet),
                          ),
                        );
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('İlan bulunamadı.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 