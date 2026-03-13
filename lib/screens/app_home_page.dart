import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'secretaire/dashboard_screen.dart';
import 'medecin/medecin_dashboard_screen.dart';
import 'home_screen.dart';

class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return _buildAuthenticatedUI(context, snapshot.data!);
        }
        
        return _buildGuestUI(context);
      },
    );
  }

  Widget _buildAuthenticatedUI(BuildContext context, User user) {
    if (user.email == 'admin@test.com') {
      return const AdminDashboardScreen();
    }
    
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('utilisateur')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const LoginScreen();
        }

        final userDoc = snapshot.data!.docs.first;
        final uid = userDoc.id;
        final userData = userDoc.data() as Map<String, dynamic>;

        if (userData.containsKey('role') && userData['role'] != null) {
          final role = userData['role'] as String;
          return _routeForRole(role);
        }

        // Infer role from collections
        return FutureBuilder<String>(
          future: _inferRole(uid),
          builder: (context, roleSnapshot) {
             if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
             }
             final role = roleSnapshot.data ?? 'patient';
             return _routeForRole(role);
          }
        );
      },
    );
  }

  Future<String> _inferRole(String uid) async {
     final medecinDoc = await FirebaseFirestore.instance.collection('medecin').where('utilisateur_id', isEqualTo: uid).limit(1).get();
     if (medecinDoc.docs.isNotEmpty) return 'medecin';
     
     final secDoc = await FirebaseFirestore.instance.collection('secretaire').where('utilisateur_id', isEqualTo: uid).limit(1).get();
     if (secDoc.docs.isNotEmpty) return 'secretaire';
     
     return 'patient';
  }

  Widget _routeForRole(String role) {
     if (role == 'admin') return const AdminDashboardScreen();
     if (role == 'secretaire') return const DashboardScreen();
     if (role == 'medecin') return const MedecinDashboardScreen();
     return const HomeScreen();
  }

  Widget _buildGuestUI(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF3A9E8F),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3A9E8F).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medical_services,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Bienvenue sur',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF1E4545),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'E-Rendez-vous',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E4545),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Votre plateforme de rendez-vous médical en ligne',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: const Color(0xFF888888),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    Icons.calendar_month,
                    'Prendre rendez-vous',
                    'Réservez facilement votre consultation',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFeatureCard(
                    Icons.medical_information,
                    'Médecins qualifiés',
                    'Accédez à un réseau de professionnels',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    Icons.phone_in_talk,
                    'Téléconsultation',
                    'Consultez à distance',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFeatureCard(
                    Icons.schedule,
                    '24/7 Disponible',
                    'Prenez RDV à tout moment',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 40,
                    color: const Color(0xFF3A9E8F),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Commencez dès maintenant',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E4545),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connectez-vous pour accéder à tous nos services',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A9E8F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Se connecter',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: const Color(0xFF3A9E8F),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E4545),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF888888),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

}
