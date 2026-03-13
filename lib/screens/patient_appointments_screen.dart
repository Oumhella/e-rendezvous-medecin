import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rendez_vous.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'add_avis_screen.dart';
import 'patient_profile_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  Stream<List<RendezVous>> _getAppointments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('rendezVous')
        .where('patient_id', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) => RendezVous.fromFirestore(doc)).toList();
      docs.sort((a, b) {
        if (a.dateHeure == null && b.dateHeure == null) return 0;
        if (a.dateHeure == null) return 1;
        if (b.dateHeure == null) return -1;
        return b.dateHeure!.compareTo(a.dateHeure!); // Descending
      });
      return docs;
    });
  }

  Future<Map<String, dynamic>> _getDoctorMap(String medecinId) async {
    final docRef = _db.collection('medecin').doc(medecinId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      return docSnap.data() as Map<String, dynamic>;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      bottomNavigationBar: _buildBottomNavigation(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<RendezVous>>(
              stream: _getAppointments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.tealDark));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }

                final appointments = snapshot.data ?? [];

                if (appointments.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final rdv = appointments[index];
                    return _buildAppointmentCard(rdv);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 40),
        decoration: const BoxDecoration(color: AppColors.tealDark),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text(
                'Mes Rendez-vous',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFamily: 'Serif',
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
              ],
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.orangeAccent,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Pas encore de rendez-vous',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.tealDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prenez votre premier rendez-vous en quelques clics.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealDark,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Prendre un rendez-vous',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(RendezVous rdv) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDoctorMap(rdv.medecinId),
      builder: (context, snapshot) {
        String doctorName = 'Médecin inconnu';
        String specialite = '';
        
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final data = snapshot.data!;
          final nom = data['nom'] ?? '';
          final prenom = data['prenom'] ?? '';
          // Try fetching from user doc if missing
          if (nom.isEmpty && prenom.isEmpty && data['utilisateur_id'] != null) {
             doctorName = 'Dr. $nom $prenom'; 
             // Without another query it's hard, we assume medecin has it or we just display as is
             // The Doctor model enrichment does it, but here we can just show what's available
          } else {
             doctorName = 'Dr. $prenom $nom'.trim();
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(rdv.statut.name).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusTranslation(rdv.statut.name),
                        style: TextStyle(
                          color: _getStatusColor(rdv.statut.name),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      rdv.typeVisite.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person_outline, color: AppColors.tealDark, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tealDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rdv.motif.isNotEmpty ? rdv.motif : 'Consultation standard',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (rdv.dateHeure != null) ...[
                      _buildInfoItem(Icons.calendar_today_outlined, DateFormat('dd MMM yyyy', 'fr_FR').format(rdv.dateHeure!)),
                      _buildInfoItem(Icons.access_time_outlined, DateFormat('HH:mm').format(rdv.dateHeure!)),
                    ]
                  ],
                ),
                if (rdv.statut.name.toLowerCase() == 'termine') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final doctorData = snapshot.data ?? {};
                        final prenom = doctorData['prenom'] ?? '';
                        final nom = doctorData['nom'] ?? '';
                        final medecinNom = 'Dr. $prenom $nom'.trim();

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddAvisScreen(
                              medecinId: rdv.medecinId,
                              medecinNom: medecinNom,
                              rendezVousId: rdv.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star_outline, color: Colors.black87, size: 18),
                      label: const Text(
                        'Ajouter un avis',
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.orangeAccent),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.tealDark,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'confirme':
        return const Color(0xFF2E7D32); // Deep Green
      case 'enattente':
        return AppColors.orangeAccent;
      case 'annule':
        return const Color(0xFFD32F2F); // Red
      case 'termine':
        return AppColors.tealDark;
      case 'absent':
        return AppColors.textGray;
      default:
        return Colors.black;
    }
  }

  String _getStatusTranslation(String statut) {
    switch (statut.toLowerCase()) {
      case 'confirme':
        return 'Confirmé';
      case 'enattente':
        return 'En Attente';
      case 'annule':
        return 'Annulé';
      case 'termine':
        return 'Terminé';
      case 'absent':
        return 'Absent';
      default:
        return statut;
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Accueil', false, () => Navigator.of(context).popUntil((route) => route.isFirst)),
            _buildNavItem(Icons.search, 'Recherche', false, () => Navigator.of(context).popUntil((route) => route.isFirst)),
            _buildCentralNavItem(),
            _buildNavItem(Icons.calendar_today, 'Mes RDV', true, () {}),
            _buildNavItem(Icons.person_outline, 'Profil', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralNavItem() {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.orangeAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.tealDark : AppColors.inactiveGray,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.tealDark : AppColors.inactiveGray,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2.25, size.height - 30);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 3.25), size.height - 65);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
