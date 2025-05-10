import 'package:flutter/material.dart';
import '../screens/chat_list_screen.dart';
import '../screens/home_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final Function showProfileMenu;
  final Color darkGrey;
  final Color primaryOrange;

  const CustomBottomNavBar({
    Key? key,
    required this.showProfileMenu,
    required this.darkGrey,
    required this.primaryOrange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: darkGrey,
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
              icon: const Icon(Icons.favorite, color: Colors.white),
              onPressed: () {},
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
              onPressed: () => showProfileMenu(),
            ),
          ],
        ),
      ),
    );
  }
}
