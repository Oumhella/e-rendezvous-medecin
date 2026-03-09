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

  const ReservationScreen({
    super.key,
    required this.doctor,
    required this.dateStr,
    required this.date,
    required this.time,
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
        'creneau_id': '', // Will need to be mapped to full creneau logic if needed
        'dateHeure': Timestamp.fromDate(dateHeure),
        'dateReservation': FieldValue.serverTimestamp(),
        'medecin_id': widget.doctor.id,
        'motif': _motifController.text.trim(),
        'note': _motifController.text.trim(),
        'patient_id': user.uid,
        'rappelEnvoye': false,
        'reservePar': user.uid,
        'statut': 'enAttente',
        'typeVisite': _selectedTypeVisite,
        'nomPatient': _nameController.text.trim(),
        'telephonePatient': _phoneController.text.trim(),
      });
      
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
      backgroundColor: const Color(0xFFF9FAFA),
      appBar: AppBar(
        title: const Text(
          'Réserver un rendez-vous',
          style: TextStyle(
            color: AppColors.navyDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDoctorSummary(),
              const SizedBox(height: 24),
              _buildForm(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2A36), // Deep dark blue
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Confirmer la réservation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF1B2A36), // Top dark area of card
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Transform.translate(
              offset: const Offset(0, 30),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: widget.doctor.photoUrl != null
                      ? NetworkImage(widget.doctor.photoUrl!)
                      : null,
                  child: widget.doctor.photoUrl == null
                      ? Text(
                          widget.doctor.fullName.substring(0, 2).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyDark),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.doctor.specialite,
                  style: const TextStyle(color: Color(0xFF5CA3B3), fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DATE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(widget.dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HEURE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(widget.time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildInputField('Nom complet', 'Ex: Jean Dupont', _nameController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField('Email', 'jean@example.com', _emailController, TextInputType.emailAddress),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField('Téléphone', '+212 6...', _phoneController, TextInputType.phone),
            const SizedBox(height: 24),
            const Text(
              'Type de visite',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyDark),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyDark),
                ),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Color(0xFF8B9EB4)),
                    SizedBox(width: 4),
                    Text('Assistant IA', style: TextStyle(color: Color(0xFF8B9EB4), fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                )
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
                fillColor: const Color(0xFFF9FAFA),
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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyDark),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFA),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
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

  Widget _buildInputField(String label, String hint, TextEditingController controller, [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyDark),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey[200]!),
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
              color: isSelected ? const Color(0xFF1B2A36) : Colors.grey[300]!,
              width: isSelected ? 1.5 : 1.0,
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
              color: isSelected ? const Color(0xFF1B2A36) : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
