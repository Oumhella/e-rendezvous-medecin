import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterRoleScreen extends StatefulWidget {
  const RegisterRoleScreen({super.key});

  @override
  State<RegisterRoleScreen> createState() => _RegisterRoleScreenState();
}

class _RegisterRoleScreenState extends State<RegisterRoleScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBEBDC), // warm cream
      body: Column(
        children: [
          // TOP HEADER with wave
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 180,
              color: const Color(0xFF1B4A4A), // dark teal
              child: Column(
                children: [
                  const SizedBox(height: 50), // status bar space
                  Expanded(
                    child: Center(
                      child: Text(
                        "Rejoindre Medico",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENT BELOW HEADER
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // PATIENT CARD
                  _buildRoleCard(
                    icon: Icons.person_outline,
                    title: "Je suis Patient",
                    subtitle: "Réservez vos rendez-vous",
                    isSelected: _selectedRole == 'patient',
                    onTap: () => setState(() => _selectedRole = 'patient'),
                  ),

                  const SizedBox(height: 16),

                  // MÉDECIN CARD
                  _buildRoleCard(
                    icon: Icons.medical_services_outlined,
                    title: "Je suis Médecin",
                    subtitle: "Gérez votre cabinet en ligne",
                    isSelected: _selectedRole == 'medecin',
                    onTap: () => setState(() => _selectedRole = 'medecin'),
                  ),

                  const Spacer(),

                  // CONTINUER BUTTON
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedRole != null
                              ? const Color(0xFFF9B90E)
                              : const Color(0xFFE0D0C0), // disabled = darker cream
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        icon: const SizedBox.shrink(),
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Continuer",
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                        onPressed: _selectedRole != null
                            ? () => Navigator.pushNamed(
                                context,
                                _selectedRole == 'patient'
                                    ? '/register-patient'
                                    : '/register-medecin',
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B4A4A) // teal border when selected
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // ICON CIRCLE
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0EF), // light teal gray
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: const Color(0xFF1B4A4A), // dark teal
              ),
            ),

            const SizedBox(width: 16),

            // TEXTS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A9BB0),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 40,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
