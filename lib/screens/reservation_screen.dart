import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor.dart';
import '../theme/app_theme.dart';

class ReservationScreen extends StatefulWidget {
  final Doctor doctor;
  final String dateStr;
  final DateTime date;
  final String time;
  final String creneauId;

  const ReservationScreen({
    super.key,
    required this.doctor,
    required this.dateStr,
    required this.date,
    required this.time,
    required this.creneauId,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _motifController = TextEditingController();
  
  String _selectedTypeVisite = 'Cabinet';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';
      
      final doc = await FirebaseFirestore.instance.collection('utilisateur').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = '${doc.data()?['prenom'] ?? ''} ${doc.data()?['nom'] ?? ''}'.trim();
          }
          _phoneController.text = doc.data()?['telephone'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _motifController.dispose();
    super.dispose();
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Utilisateur non connecté");

      final db = FirebaseFirestore.instance;
      
      final parts = widget.time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dateHeure = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        hour,
        minute,
      );

      await db.collection('rendezVous').add({
        'creneau_id': widget.creneauId,
        'dateHeure': Timestamp.fromDate(dateHeure),
        'dateReservation': FieldValue.serverTimestamp(),
        'medecin_id': widget.doctor.id,
        'motif': _motifController.text.trim(),
        'note': _motifController.text.trim(),
        'patient_id': user.uid,
        'rappelEnvoye': false,
        'reservePar': user.uid,
        'statut': 'Confirmé ',
        'typeVisite': _selectedTypeVisite,
        'nomPatient': _nameController.text.trim(),
        'telephonePatient': _phoneController.text.trim(),
      });
      
      if (widget.creneauId.isNotEmpty) {
        await db.collection('creneaux').doc(widget.creneauId).update({
          'disponible': false,
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre rendez-vous a été réservé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to home or appointments
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      debugPrint("Error making reservation: \$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la réservation.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDoctorSummary(),
                    const SizedBox(height: 20),
                    _buildForm(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(),
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
                'Réserver un rendez-vous',
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

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangeAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2),
                  )
                : const Text(
                    'Confirmer la réservation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorSummary() {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.doctor.photoUrl != null ? NetworkImage(widget.doctor.photoUrl!) : null,
                  child: widget.doctor.photoUrl == null
                      ? Text(
                          widget.doctor.fullName.substring(0, 2).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tealDark),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctor.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.tealDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.doctor.specialite,
                      style: const TextStyle(color: AppColors.textGray, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _buildSummaryInfo(Icons.calendar_today, 'DATE', widget.dateStr),
          const SizedBox(height: 16),
          _buildSummaryInfo(Icons.access_time, 'HEURE', widget.time),
        ],
      ),
    );
  }

  Widget _buildSummaryInfo(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.orangeAccent, size: 18),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGray, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.tealDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
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
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInputField('Nom complet', 'Ex: Jean Dupont', _nameController, Icons.person_outline),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('Email', 'jean@example.com', _emailController, Icons.email_outlined, TextInputType.emailAddress),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField('Téléphone', '+212 6...', _phoneController, Icons.phone_android_outlined, TextInputType.phone),
            const SizedBox(height: 24),
            const Text(
              'Type de visite',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeVisiteChip('Cabinet'),
                const SizedBox(width: 8),
                _buildTypeVisiteChip('Téléconsultation'),
                const SizedBox(width: 8),
                _buildTypeVisiteChip('Domicile'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Motif de consultation',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _motifController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Expliquez brièvement la raison de votre visite...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: AppColors.offWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) => value!.isEmpty ? 'Veuillez préciser le motif' : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Pièce jointe (optionnel)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.offWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.upload_file, color: Color(0xFF8B9EB4), size: 28),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquez ou glissez vos documents médicaux ici (Ordonnance,\nAnalyse...)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, IconData icon, [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.tealDark.withOpacity(0.5), size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: AppColors.offWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.tealDark, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
        ),
      ],
    );
  }

  Widget _buildTypeVisiteChip(String label) {
    bool isSelected = _selectedTypeVisite == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTypeVisite = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.orangeAccent : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.tealDark : AppColors.textGray,
            ),
          ),
        ),
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
