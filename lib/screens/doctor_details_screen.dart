import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/doctor.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart' as common;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reservation_screen.dart';
import 'patient_appointments_screen.dart';
import 'patient_profile_screen.dart';
import 'reclamation_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailsScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  int _selectedDateIndex = 0;
  bool _isLoading = true;
  String _doctorEmail = 'Chargement...';
  List<Map<String, dynamic>> _availableDates = [];
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  Map<int, int> _ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  int _patientsCount = 0;
  String? _selectedTime;
  
  @override
  void initState() {
    super.initState();
    _fetchBackendData();
  }

  Future<void> _fetchBackendData() async {
    try {
      final db = FirebaseFirestore.instance;
      
      final medecinDoc = await db.collection('medecin').doc(widget.doctor.id).get();
      if (medecinDoc.exists) {
        final data = medecinDoc.data()!;
        final userId = data['utilisateur_id'];
        
        if (userId != null) {
          final userDoc = await db.collection('utilisateur').doc(userId).get();
          if (userDoc.exists && mounted) {
            setState(() {
              _doctorEmail = userDoc.data()!['email'] ?? 'Non spécifié';
            });
          }
        } else {
          if (mounted) setState(() => _doctorEmail = 'Non spécifié');
        }
      } else {
        if (mounted) setState(() => _doctorEmail = 'Non spécifié');
      }

      final today = DateTime.now();
      
      try {
        final creneauxQuery = await db.collection('creneaux')
            .where('medecin_id', isEqualTo: db.doc('medecin/${widget.doctor.id}'))
            .get();

        Map<DateTime, List<Map<String, dynamic>>> groupedSlots = {};
        
        for (var doc in creneauxQuery.docs) {
          final data = doc.data();
          if (data['dateJour'] == null || data['heureDebut'] == null) continue;
          
          final timestamp = data['dateJour'] as Timestamp;
          final date = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
          
          // Only keep slots from today onwards
          if (date.isBefore(DateTime(today.year, today.month, today.day))) continue;

          final heureDebut = data['heureDebut'] as String;
          final isDisponible = data['disponible'] == true;
          
          if (!groupedSlots.containsKey(date)) {
            groupedSlots[date] = [];
          }
          bool exists = groupedSlots[date]!.any((s) => s['time'] == heureDebut);
          if (!exists) {
            groupedSlots[date]!.add({
              'id': doc.id,
              'time': heureDebut,
              'isAvailable': isDisponible,
            });
          }
        }

        final List<String> weekDays = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
        List<Map<String, dynamic>> availableDates = [];
        
        final sortedDates = groupedSlots.keys.toList()..sort();
        for (var date in sortedDates) {
          final slots = groupedSlots[date]!..sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
          availableDates.add({
            'day': weekDays[date.weekday - 1],
            'date': date.day.toString(),
            'fullDate': date,
            'slots': slots,
          });
        }

        if (mounted) {
          setState(() {
            _availableDates = availableDates;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching creneaux data: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }

      // Fetch Reviews (Avis)
      try {
        final medecinRef = db.doc('medecin/${widget.doctor.id}');
        final avisQuery = await db.collection('avis')
            .where('medecin_id', isEqualTo: medecinRef)
            .get();

        // Also try with string id just in case
        final avisQueryString = await db.collection('avis')
            .where('medecin_id', isEqualTo: widget.doctor.id)
            .get();

        final allAvisDocs = [...avisQuery.docs, ...avisQueryString.docs];
        // Remove duplicates if any
        final uniqueAvisDocs = <String, QueryDocumentSnapshot>{};
        for (var doc in allAvisDocs) {
          uniqueAvisDocs[doc.id] = doc;
        }

        List<Map<String, dynamic>> fetchedReviews = [];
        double totalRating = 0;
        Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

        for (var doc in uniqueAvisDocs.values) {
          final data = doc.data() as Map<String, dynamic>;
          final note = (data['note'] as num?)?.toInt() ?? 5;
          totalRating += note;
          if (ratingCounts.containsKey(note)) {
            ratingCounts[note] = ratingCounts[note]! + 1;
          }

          String dateStr = '';
          if (data['datePublication'] is Timestamp) {
            final date = (data['datePublication'] as Timestamp).toDate();
            dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          }

          fetchedReviews.add({
            'name': data['patientNom'] ?? 'Patient',
            'date': dateStr,
            'content': data['commentaire'] ?? '',
            'rating': note,
            'initial': (data['patientNom'] ?? 'P').isNotEmpty ? (data['patientNom'] as String)[0].toUpperCase() : 'P',
          });
        }

        if (mounted) {
          setState(() {
            _reviews = fetchedReviews;
            if (fetchedReviews.isNotEmpty) {
              _averageRating = totalRating / fetchedReviews.length;
            }
            _ratingCounts = ratingCounts;
          });
        }
      } catch (e) {
        debugPrint('Error fetching avis data: $e');
      }

      // Fetch Patients Count (unique from rendezVous)
      try {
        final medecinRef = db.doc('medecin/${widget.doctor.id}');
        final rdvQuery = await db.collection('rendezVous')
            .where('medecin_id', isEqualTo: medecinRef)
            .get();
        final rdvQueryStr = await db.collection('rendezVous')
            .where('medecin_id', isEqualTo: widget.doctor.id)
            .get();
            
        final Set<String> uniquePatients = {};
        for (var doc in [...rdvQuery.docs, ...rdvQueryStr.docs]) {
          final data = doc.data();
          if (data['patient_id'] != null) {
            String pId = data['patient_id'].toString();
            if (pId.contains('/')) pId = pId.split('/').last;
            uniquePatients.add(pId);
          }
        }
        
        if (mounted) {
          setState(() {
            _patientsCount = uniquePatients.length;
          });
        }
      } catch (e) {
        debugPrint('Error fetching patients count: $e');
      }

    } catch (e) {
      debugPrint('Error fetching doctor backend data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_doctorEmail == 'Chargement...') {
            _doctorEmail = 'Erreur chargement';
          }
        });
      }
    }
  }

  void _requireLogin() {
    showDialog(
      context: context,
      builder: (context) => common.LoginPromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildAboutSection(),
                  const SizedBox(height: 16),
                  _buildInformationSection(),
                  const SizedBox(height: 16),
                  _buildMapSection(),
                  const SizedBox(height: 16),
                  _buildAvailabilitySection(),
                  const SizedBox(height: 16),
                  _buildReviewsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }


  Widget _buildHeader() {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 60),
        decoration: const BoxDecoration(color: AppColors.tealDark),
        child: Column(
          children: [
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Avatar with Orange Border
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.orangeAccent,
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: widget.doctor.photoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Image.network(
                            widget.doctor.photoUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Text(
                          widget.doctor.prenom.isNotEmpty && widget.doctor.nom.isNotEmpty
                              ? widget.doctor.prenom[0] + widget.doctor.nom[0]
                              : 'DR',
                          style: const TextStyle(
                            color: AppColors.tealDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              'Dr. ${widget.doctor.prenom} ${widget.doctor.nom}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 4),
            // Specialty
            Text(
              widget.doctor.specialite,
              style: TextStyle(
                color: AppColors.lightBlue.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Badges Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderBadge(
                  icon: Icons.star_border,
                  label: _averageRating > 0 ? _averageRating.toStringAsFixed(1) : widget.doctor.noteText,
                  color: AppColors.orangeAccent,
                ),
                const SizedBox(width: 12),
                _buildHeaderBadge(
                  icon: Icons.verified_user_outlined,
                  label: 'Validé',
                  color: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Price Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.orangeAccent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${widget.doctor.tarifText} MAD',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Bouton Signaler un problème
            GestureDetector(
              onTap: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  _requireLogin();
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReclamationScreen(doctor: widget.doctor),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.report_problem_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Signaler un problème',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Column(
      children: [
        const SizedBox(height: 55),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.doctor.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.beigePeach,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.doctor.specialite,
            style: const TextStyle(
              color: AppColors.tealDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 20),
            const SizedBox(width: 4),
            Text(
              _averageRating > 0 ? _averageRating.toStringAsFixed(1) : widget.doctor.noteText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              '(${_reviews.length} avis)',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.doctor.actif)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, color: Colors.green, size: 12),
                SizedBox(width: 6),
                Text(
                  'Disponible aujourd\'hui',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (widget.doctor.actif) const SizedBox(height: 24),
        if (!widget.doctor.actif) const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(
              icon: Icons.access_time,
              title: '${widget.doctor.anneesExperience} ans',
              subtitle: 'Expérience',
            ),
            _buildStatCard(
              icon: Icons.people_outline,
              title: '$_patientsCount',
              subtitle: 'Patients',
            ),
            _buildStatCard(
              icon: Icons.star_border,
              title: '${_reviews.length}',
              subtitle: 'Avis',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      child: Column(
        children: [
          Icon(icon, color: AppColors.tealDark, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return const SizedBox.shrink(); // Replaced by Section Tabs in this new design
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppColors.tealDark,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(color: Colors.grey[200], thickness: 1),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biographie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.tealDark),
          ),
          const SizedBox(height: 12),
          Text(
            widget.doctor.biographies.isNotEmpty
                ? widget.doctor.biographies
                : 'Spécialiste expérimenté(e). Technologies de pointe pour des soins de qualité supérieure.',
            style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.tealDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.doctor.adresse}, ${widget.doctor.ville}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de contact',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.tealDark),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email_outlined, _doctorEmail),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.phone_outlined,
            widget.doctor.telephone.isNotEmpty ? widget.doctor.telephone : '+212 539 234 567',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.access_time, '${widget.doctor.anneesExperience} ans d\'expérience'),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Localisation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.tealDark),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.offWhite, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _getDoctorCoordinates(),
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'e_rendezvous_medecin',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _getDoctorCoordinates(),
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.orangeAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6),
                            ],
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.doctor.adresse,
            style: const TextStyle(fontSize: 14, color: AppColors.textGray, height: 1.4),
          ),
        ],
      ),
    );
  }

  LatLng _getDoctorCoordinates() {
    // Simulation de coordonnées basées sur la ville (comme dans home_screen)
    if (widget.doctor.adresse.toLowerCase().contains('casablanca')) {
      return const LatLng(33.5731, -7.5898);
    } else if (widget.doctor.adresse.toLowerCase().contains('rabat')) {
      return const LatLng(34.0209, -6.8416);
    } else if (widget.doctor.adresse.toLowerCase().contains('marrakech')) {
      return const LatLng(31.6295, -7.9811);
    }
    return const LatLng(33.9716, -6.8428); // Position par défaut
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8B9EB4), size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Disponibilités',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    if (_availableDates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Disponibilités',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Text('Aucun créneau disponible pour le moment.'),
          ],
        ),
      );
    }

    final slotsForSelectedDate = _selectedDateIndex < _availableDates.length 
        ? _availableDates[_selectedDateIndex]['slots'] as List<Map<String, dynamic>>
        : <Map<String, dynamic>>[];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Disponibilités',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedDateIndex;
                final dateData = _availableDates[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                      _selectedTime = null;
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.orangeAccent : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? null : Border.all(color: AppColors.beigeGray),
                      boxShadow: isSelected ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dateData['day'],
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.white70 : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateData['date'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // A little timeline indicator
          Row(
            children: [
              const Icon(Icons.arrow_left, color: Colors.grey),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const Icon(Icons.arrow_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 24),
          // Time slots
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: slotsForSelectedDate.isEmpty 
                ? [const Text('Aucun créneau pour cette date')]
                : slotsForSelectedDate.map((slot) => _buildTimeSlot(slot)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(Map<String, dynamic> slotData) {
    String time = slotData['time'];
    bool isAvailable = slotData['isAvailable'];
    bool isSelected = _selectedTime == time;
    return GestureDetector(
      onTap: isAvailable ? () {
        setState(() {
          _selectedTime = time;
        });
      } : null,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: !isAvailable 
              ? Colors.grey[200] 
              : isSelected ? AppColors.orangeAccent : AppColors.beigePeach,
          borderRadius: BorderRadius.circular(16),
          border: !isAvailable ? Border.all(color: Colors.grey[300]!) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          time,
          style: TextStyle(
            color: !isAvailable 
                ? Colors.grey[400] 
                : isSelected ? Colors.white : AppColors.tealDark,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            decoration: !isAvailable ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    int totalReviews = _reviews.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avis patients',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_reviews.isEmpty)
            const Text(
              'Aucun avis pour ce médecin.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < _averageRating.round() ? Icons.star : Icons.star_border,
                            color: AppColors.orangeAccent,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalReviews avis',
                        style: const TextStyle(color: Color(0xFF8B9EB4), fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar(5, totalReviews > 0 ? _ratingCounts[5]! / totalReviews : 0.0),
                        const SizedBox(height: 4),
                        _buildRatingBar(4, totalReviews > 0 ? _ratingCounts[4]! / totalReviews : 0.0),
                        const SizedBox(height: 4),
                        _buildRatingBar(3, totalReviews > 0 ? _ratingCounts[3]! / totalReviews : 0.0),
                        const SizedBox(height: 4),
                        _buildRatingBar(2, totalReviews > 0 ? _ratingCounts[2]! / totalReviews : 0.0),
                        const SizedBox(height: 4),
                        _buildRatingBar(1, totalReviews > 0 ? _ratingCounts[1]! / totalReviews : 0.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._reviews.map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildReviewCard(
                  review['name'],
                  review['date'],
                  review['content'],
                  review['rating'],
                  review['initial'],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingBar(int star, double percentage) {
    return Row(
      children: [
        Text(
          '★$star',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (percentage * 100).toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.orangeAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - (percentage * 100).toInt(),
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '${(percentage * 100).toInt()}%',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B9EB4)),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    String name,
    String date,
    String content,
    int rating,
    String initial,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.beigePeach,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF8B9EB4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: AppColors.orangeAccent,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF8B9EB4),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      _requireLogin();
                      return;
                    }
                    if (_selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez d\'abord sélectionner un horaire.')),
                      );
                      return;
                    }

                    final selectedDateMap = _availableDates[_selectedDateIndex];
                    final rawDate = selectedDateMap['fullDate'] as DateTime;
                    
                    final months = [
                      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
                      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
                    ];
                    
                    final day = rawDate.day.toString().padLeft(2, '0');
                    final monthStr = months[rawDate.month - 1];
                    final dateStr = '$day $monthStr ${rawDate.year}';
                    
                    final slots = selectedDateMap['slots'] as List<Map<String, dynamic>>;
                    final matchingSlot = slots.firstWhere((s) => s['time'] == _selectedTime, orElse: () => {});
                    final creneauId = matchingSlot['id'] ?? '';
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReservationScreen(
                          doctor: widget.doctor,
                          dateStr: dateStr,
                          date: rawDate,
                          time: _selectedTime!,
                          creneauId: creneauId as String,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedTime != null ? AppColors.orangeAccent : AppColors.inactiveGray,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Réserver un rendez-vous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Container(height: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_outlined, 'Accueil', false, () => Navigator.of(context).popUntil((route) => route.isFirst)),
                  _buildNavItem(Icons.search, 'Recherche', false, () => Navigator.of(context).popUntil((route) => route.isFirst)),
                  _buildCentralNavItem(),
                  _buildNavItem(Icons.calendar_today_outlined, 'Mes RDV', false, () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      _requireLogin();
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen()));
                    }
                  }),
                  _buildNavItem(Icons.person_outline, 'Profil', false, () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      _requireLogin();
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientProfileScreen()));
                    }
                  }),
                ],
              ),
            ),
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

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
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
