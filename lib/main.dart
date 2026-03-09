import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/secretaire/dashboard_screen.dart';
import 'screens/secretaire/add_reservation_screen.dart';
import 'screens/secretaire/edit_reservation_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'services/seed_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize French locale for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Seed test data on first run (safe to call multiple times)
  await SeedData.seedTestData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Rendez-vous Médecin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
      initialRoute: '/home',
      routes: {
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/add-reservation': (_) => const AddReservationScreen(),
        '/edit-reservation': (_) => const EditReservationScreen(),
      },
    );
  }
}
        
     
