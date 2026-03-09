import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart' as common;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reservation_screen.dart';

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
            .where('medecin_id', isEqualTo: widget.doctor.id)
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  _buildDivider(),
                  _buildAboutSection(),
                  _buildDivider(),
                  _buildInformationSection(),
                  _buildDivider(),
                  _buildAvailabilitySection(),
                  _buildDivider(),
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
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7A949A), // grayish blue top
                Color(0xFFD3E7ED), // light blue bottom
              ],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -45, // half of the avatar size (90)
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
                      widget.doctor.prenom.isNotEmpty &&
                              widget.doctor.nom.isNotEmpty
                          ? widget.doctor.prenom[0] + widget.doctor.nom[0]
                          : 'DR',
                      style: const TextStyle(
                        color: AppColors.navyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
            ),
          ),
        ),
        // Spacer below to accommodate the avatar
        const Positioned(bottom: -70, child: SizedBox.shrink()),
      ],
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
            color: const Color(0xFFC7E0EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.doctor.specialite,
            style: const TextStyle(
              color: AppColors.navyDark,
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
          Icon(icon, color: AppColors.navyDark, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(Icons.phone_outlined, _requireLogin),
        const SizedBox(width: 24),
        _buildCircleButton(Icons.videocam_outlined, _requireLogin),
        const SizedBox(width: 24),
        _buildCircleButton(Icons.chat_bubble_outline, _requireLogin),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFC7E0EB), // light grayish blue
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'À propos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.doctor.biographies.isNotEmpty
                ? widget.doctor.biographies
                : 'Spécialiste en soins dentaires esthétiques et restaurateurs. Technologies de pointe pour des soins de qualité supérieure.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Text(
                'Voir plus',
                style: TextStyle(
                  color: AppColors.navyDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.navyDark,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
            const Text(
              'Informations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, _doctorEmail),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.phone_outlined,
              widget.doctor.telephone.isNotEmpty
                  ? widget.doctor.telephone
                  : '+212 539 234 567',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on_outlined, widget.doctor.adresse),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_city_outlined, widget.doctor.ville),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.description_outlined,
              '${widget.doctor.tarifText} / consultation',
            ),
          ],
        ),
      ),
    );
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
                      color: isSelected ? const Color(0xFF2B3A4A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? null : Border.all(color: Colors.grey[200]!),
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
              : isSelected ? const Color(0xFF2B3A4A) : const Color(0xFFC7E0EB), // Light blue background
          borderRadius: BorderRadius.circular(16),
          border: !isAvailable ? Border.all(color: Colors.grey[300]!) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          time,
          style: TextStyle(
            color: !isAvailable 
                ? Colors.grey[400] 
                : isSelected ? Colors.white : const Color(0xFF2B3A4A),
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
                            color: Colors.orange,
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
                      color: Colors.orange,
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
                backgroundColor: const Color(0xFFC7E0EB),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF2B3A4A),
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
                    color: Colors.orange,
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
                    backgroundColor: _selectedTime != null ? const Color(0xFF1B2A36) : const Color(0xFF8B9EB4),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    Icons.home_outlined,
                    'Accueil',
                    false,
                    () => Navigator.pop(context),
                  ),
                  _buildNavItem(Icons.search, 'Recherche', false, () {}),
                  _buildNavItem(
                    Icons.calendar_today,
                    'Mes RDV',
                    false,
                    _requireLogin,
                  ),
                  _buildNavItem(
                    Icons.person_outline,
                    'Profil',
                    false,
                    _requireLogin,
                  ),
                ],
              ),
            ),
          ],
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
            color: isActive ? AppColors.navyDark : const Color(0xFF8B9EB4),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppColors.navyDark : const Color(0xFF8B9EB4),
            ),
          ),
        ],
      ),
    );
  }
}
