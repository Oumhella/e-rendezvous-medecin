import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import '../app_home_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.gradient,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image(
                      image: AssetImage('assets/images/logo.png'),
                      width: 120,
                      height: 120,
                      errorBuilder: _logoFallback,
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(color: AppColors.white),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          return const AppHomePage();
        }
        return const LoginScreen();
      },
    );
  }

  static Widget _logoFallback(
      BuildContext context, Object error, StackTrace? stack) {
    return const Icon(Icons.local_hospital, size: 80, color: AppColors.white);
  }
}