import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rendez_vous.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'add_avis_screen.dart';

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
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text(
          'Mes Rendez-vous',
          style: TextStyle(
            color: AppColors.navyDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navyDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<RendezVous>>(
        stream: _getAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final rdv = appointments[index];
              return _buildAppointmentCard(rdv);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppColors.lightBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucun rendez-vous',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous n\'avez pas encore pris de rendez-vous.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(rdv.statut.name).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusTranslation(rdv.statut.name),
                        style: TextStyle(
                          color: _getStatusColor(rdv.statut.name),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      rdv.typeVisite.name.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC7E0EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person, color: AppColors.navyDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rdv.motif.isNotEmpty ? rdv.motif : 'Consultation',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (rdv.dateHeure != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.lightBlue),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy', 'fr_FR').format(rdv.dateHeure!),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: AppColors.lightBlue),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(rdv.dateHeure!),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
                // Bouton "Ajouter un avis" pour les RDV terminés
                if (rdv.statut.name.toLowerCase() == 'termine') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Récupère le nom du médecin
                        final doctorData = snapshot.data ?? {};
                        final prenom = doctorData['prenom'] ?? '';
                        final nom = doctorData['nom'] ?? '';
                        final medecinNom =
                            'Dr. $prenom $nom'.trim();

                        final result = await Navigator.push(
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
                      icon: const Icon(Icons.star_outline,
                          color: Colors.white, size: 18),
                      label: const Text(
                        'Ajouter un avis',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
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

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'confirme':
        return Colors.green;
      case 'enattente':
        return Colors.orange;
      case 'annule':
        return Colors.red;
      case 'termine':
        return Colors.blue;
      case 'absent':
        return Colors.grey;
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
}
