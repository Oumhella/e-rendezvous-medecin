import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF5BC4BF),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        // Connecté → Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Non connecté → Login
        return const LoginScreen();
      },
    );
  }
}