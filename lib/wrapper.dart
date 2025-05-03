import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './screens/home_screen.dart';
import './screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı durumunu kontrol et
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı oturum açmışsa ana sayfaya, açmamışsa giriş sayfasına yönlendir
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        }

        return LoginScreen();
      },
    );
  }
}
