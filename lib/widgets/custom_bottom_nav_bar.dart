import 'package:flutter/material.dart';
import '../screens/chat_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/my_pets_screen.dart';
import '../screens/profile_screen.dart';
import 'profile_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomBottomNavBar extends StatelessWidget {
  final Color darkGrey;
  final Color primaryOrange;
  final Function handleSignOut;

  const CustomBottomNavBar({
    Key? key,
    required this.darkGrey,
    required this.primaryOrange,
    required this.handleSignOut,
  }) : super(key: key);

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ProfileMenu(
        handleSignOut: handleSignOut,
        darkGrey: darkGrey,
        primaryOrange: primaryOrange,
        auth: FirebaseAuth.instance,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: darkGrey,
      elevation: 8.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white24,
              width: 0.5,
            ),
          ),
        ),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.list_alt, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyPetsScreen()),
                  );
                },
              ),
              const SizedBox(width: 40), // FAB için boşluk
              IconButton(
                icon: const Icon(Icons.message, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatListScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () => _showProfileMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Kavisli üst border çizen painter
// class _CurvedTopBorderPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white24
//       ..strokeWidth = 0.5
//       ..style = PaintingStyle.stroke;
//
//     final double fabRadius = 36; // FAB'ın çapı + margin (gerekirse ayarlanabilir)
//     final double fabCenter = size.width / 2;
//     final double curveWidth = fabRadius + 16; // Kavis genişliği
//     final double curveHeight = 18; // Kavis yüksekliği
//
//     final path = Path();
//     // Soldan ortaya kadar düz çizgi
//     path.moveTo(0, 0);
//     path.lineTo(fabCenter - curveWidth / 2, 0);
//     // Kavisli boşluk (FAB için)
//     path.cubicTo(
//       fabCenter - curveWidth / 2 + 8, 0,
//       fabCenter - curveWidth / 2 + 16, curveHeight,
//       fabCenter, curveHeight,
//     );
//     path.cubicTo(
//       fabCenter + curveWidth / 2 - 16, curveHeight,
//       fabCenter + curveWidth / 2 - 8, 0,
//       fabCenter + curveWidth / 2, 0,
//     );
//     // Sağdan devam eden düz çizgi
//     path.lineTo(size.width, 0);
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
