import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';
import '../../models/doctor.dart';
import 'admin_doctors_screen.dart';
import 'doctor_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Doctor> _pendingDoctors = [];
  List<Doctor> _allDoctors = [];
  int _totalPatients = 0;
  int _totalReclamations = 0;
  bool _isLoading = true;

  // Couleurs
  static const cream = Color(0xFFF5F0E8);
  static const tealDark = Color(0xFF1E4545);
  static const teal = Color(0xFF3A9E8F);
  static const orange = Color(0xFFE8900A);
  static const green = Color(0xFF4CAF50);
  static const white = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doctors = await DoctorService.getDoctors();
      final patients = await _getTotalPatients();
      final reclamations = await _getTotalReclamations();
      
      setState(() {
        _allDoctors = doctors;
        _pendingDoctors = doctors.where((d) => d.statutMedecin == 'en_attente').toList();
        _totalPatients = patients;
        _totalReclamations = reclamations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getTotalPatients() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('patient').get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getTotalReclamations() async {
    try {
      // Simuler des réclamations (à remplacer avec vraie collection si existante)
      final snapshot = await FirebaseFirestore.instance
          .collection('rendezVous')
          .where('statut', isEqualTo: 'enAttente')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: CustomPaint(
        painter: DotPainter(),
        child: Column(
          children: [
            // Header avec wave
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                width: double.infinity,
                height: 120,
                color: tealDark,
                child: const Center(
                  child: Text(
                    'Administration',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: white,
                    ),
                  ),
                ),
              ),
            ),
            
            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats cards grid
                          _buildStatsGrid(),
                          const SizedBox(height: 30),
                          
                          // Demandes urgentes
                          _buildUrgentSection(),
                          const SizedBox(height: 30),
                          
                          // Réclamations récentes
                          _buildComplaintsSection(),
                          const SizedBox(height: 100), // Space for bottom nav
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildStatsGrid() {
    final validDoctors = _allDoctors.where((d) => d.statutMedecin == 'valide').length;
    final pendingDoctors = _allDoctors.where((d) => d.statutMedecin == 'en_attente').length;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(Icons.verified_user, '$validDoctors', 'Médecins validés', false)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard(Icons.access_time, '$pendingDoctors', 'En attente', false)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildStatCard(Icons.people, '$_totalPatients', 'Patients', true)),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard(Icons.warning, '$_totalReclamations', 'Réclamations', false, isGreen: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String number, String title, bool isOrange, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isOrange
            ? const Border(top: BorderSide(color: orange, width: 3))
            : isGreen
                ? const Border(top: BorderSide(color: green, width: 3))
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: teal, size: 28),
          const SizedBox(height: 10),
          Text(
            number,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Demandes urgentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ..._pendingDoctors.take(3).map((doctor) => _buildUrgentCard(doctor)),
      ],
    );
  }

  Widget _buildUrgentCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        border: const Border(left: BorderSide(color: orange, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${doctor.nom} ${doctor.prenom}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          color: white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${doctor.specialite} • Il y a ${DateTime.now().difference((doctor.dateCreation ?? Timestamp.now()).toDate()).inDays} jours',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorDetailScreen(doctor: doctor),
                ),
              );
            },
            child: const Text(
              'Examiner →',
              style: TextStyle(
                color: teal,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réclamations récentes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        const SizedBox(height: 15),
        // Afficher les rendez-vous en attente comme réclamations
        ..._buildRecentComplaints(),
      ],
    );
  }

  List<Widget> _buildRecentComplaints() {
    if (_totalReclamations == 0) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Aucune réclamation récente',
              style: TextStyle(
                fontSize: 16,
                color: textGrey,
              ),
            ),
          ),
        )
      ];
    }
    
    // Simuler 2-3 réclamations basées sur les rendez-vous en attente
    return [
      _buildComplaintCard('Patient A', 'Rendez-vous en attente de confirmation', 'Il y a 2 jours'),
      if (_totalReclamations > 1)
        _buildComplaintCard('Patient B', 'Modification de rendez-vous demandée', 'Il y a 5 jours'),
    ];
  }

  Widget _buildComplaintCard(String patient, String issue, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$issue • $time',
                  style: const TextStyle(
                    fontSize: 13,
                    color: textGrey,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Voir →',
            style: TextStyle(
              color: teal,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.grid_view, 'Accueil', true),
            _buildNavItem(Icons.description, 'Médecins', false),
            _buildNavItem(Icons.group, 'Utilisateurs', false),
            _buildNavItem(Icons.security, 'Réclam.', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'Accueil') return; // Already here
        if (label == 'Médecins') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminDoctorsScreen()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? orange : textGrey,
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: orange,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? orange : textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper pour wave header
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    
    final firstControlPoint = Offset(size.width / 4, size.height);
    final firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    
    final secondControlPoint = Offset(3 * size.width / 4, size.height - 60);
    final secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// Custom painter pour dot pattern
class DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    const dotSize = 2.0;
    const spacing = 20.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
