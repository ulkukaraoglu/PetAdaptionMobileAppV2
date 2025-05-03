import 'package:flutter/material.dart';

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
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 40), // FAB için boşluk
            IconButton(
              icon: const Icon(Icons.message, color: Colors.white),
              onPressed: () {},
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
