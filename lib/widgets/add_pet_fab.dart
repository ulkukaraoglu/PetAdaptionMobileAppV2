import 'package:flutter/material.dart';
import '../screens/add_pet_screen.dart';

class AddPetFAB extends StatelessWidget {
  final Color primaryOrange;

  const AddPetFAB({
    Key? key,
    required this.primaryOrange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPetScreen()),
        );
      },
      child: Container(
        height: 60,
        width: 60,
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: primaryOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 34),
      ),
    );
  }
}
