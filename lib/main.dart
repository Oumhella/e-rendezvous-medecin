import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_doctors_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_role_screen.dart';
import 'screens/auth/register_patient_screen.dart';
import 'screens/auth/register_medecin_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/secretaire/dashboard_screen.dart';
import 'screens/secretaire/add_reservation_screen.dart';
import 'screens/secretaire/edit_reservation_screen.dart';
import 'screens/secretaire/creneaux_screen.dart';
import 'screens/secretaire/add_creneau_screen.dart';
import 'screens/medecin/medecin_dashboard_screen.dart';
import 'screens/medecin/detail_rdv_screen.dart';
import 'screens/secretaire/weekly_planner_screen.dart';
import 'screens/secretaire/templates/templates_list_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'services/seed_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/app_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only if not already initialized
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized, continue
    print('Firebase already initialized: $e');
  }
  
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
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterRoleScreen(),
        '/register-patient': (_) => const RegisterPatientScreen(),
        '/register-medecin': (_) => const RegisterMedecinScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/admin/doctors': (_) => const AdminDoctorsScreen(),
        '/home': (_) => const AppHomePage(),
        '/dashboard': (_) => const DashboardScreen(),
        '/add-reservation': (_) => const AddReservationScreen(),
        '/edit-reservation': (_) => const EditReservationScreen(),
        '/creneaux': (_) => const CreneauxScreen(),
        '/add-creneau': (_) => const AddCreneauScreen(),
        '/medecin-dashboard': (_) => const MedecinDashboardScreen(),
        '/medecin-detail-rdv': (_) => const DetailRdvScreen(),
         '/weekly-planner': (context) {
          final medecinId = ModalRoute.of(context)!.settings.arguments as String;
          return WeeklyPlannerScreen(medecinId: medecinId);
        },
        '/templates': (context) {
          final medecinId = ModalRoute.of(context)!.settings.arguments as String;
          return TemplatesListScreen(medecinId: medecinId);
        },
      },
    );
  }
}
  class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si l'authentification est en cours
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Si l'utilisateur est connecté
        if (snapshot.hasData) {
          return const AppHomePage();
        }
        
        // Si l'utilisateur n'est pas connecté, afficher l'onboarding
        return const OnboardingScreen();
      },
    );
  }
}
