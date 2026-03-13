import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class AddAvisScreen extends StatefulWidget {
  final String medecinId;
  final String medecinNom;
  final String rendezVousId;

  const AddAvisScreen({
    super.key,
    required this.medecinId,
    required this.medecinNom,
    required this.rendezVousId,
  });

  @override
  State<AddAvisScreen> createState() => _AddAvisScreenState();
}

class _AddAvisScreenState extends State<AddAvisScreen> {
  final _commentaireController = TextEditingController();
  int _note = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_commentaireController.text.trim().isEmpty) {
      _showError('Veuillez rédiger un commentaire.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      final medecinRef = db.collection('medecin').doc(widget.medecinId);
      final patientRef = db.collection('utilisateur').doc(user.uid);

      String patientNom = user.displayName ?? 'Patient';
      try {
        final q = await db.collection('utilisateur').doc(user.uid).get();
        if (q.exists) {
          final d = q.data()!;
          final prenom = d['prenom'] ?? '';
          final nom = d['nom'] ?? '';
          if (prenom.isNotEmpty || nom.isNotEmpty) {
            patientNom = '$prenom $nom'.trim();
          }
        }
      } catch (_) {}

      await db.collection('avis').add({
        'medecin_id': medecinRef,
        'patient_id': patientRef,
        'patientNom': patientNom,
        'note': _note,
        'commentaire': _commentaireController.text.trim(),
        'datePublication': FieldValue.serverTimestamp(),
        'rendezVous_id': widget.rendezVousId,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Avis publié avec succès !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la publication : $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildDoctorSummary(),
                  const SizedBox(height: 20),
                  _buildRatingSection(),
                  const SizedBox(height: 20),
                  _buildCommentSection(),
                  const SizedBox(height: 40),
                ],
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
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Text(
                'Donner mon avis',
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

  Widget _buildDoctorSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
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
                  widget.medecinNom,
                  style: const TextStyle(
                    color: AppColors.tealDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Votre médecin consulté',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          const Text(
            'Quelle est votre note ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.tealDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _note = star),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      star <= _note ? Icons.star : Icons.star_border,
                      color: star <= _note ? Colors.amber : Colors.grey[300],
                      size: 40,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          _buildNoteLabel(_note),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre commentaire',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.tealDark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentaireController,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Partagez votre expérience avec ce médecin...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: AppColors.cream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.tealDark, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
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
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangeAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                : const Text(
                    'Publier mon avis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteLabel(int note) {
    IconData icon;
    Color color;
    String label;

    switch (note) {
      case 1:
        icon = Icons.sentiment_very_dissatisfied;
        color = Colors.red;
        label = 'Très mauvais';
        break;
      case 2:
        icon = Icons.sentiment_dissatisfied;
        color = Colors.orange;
        label = 'Mauvais';
        break;
      case 3:
        icon = Icons.sentiment_neutral;
        color = Colors.amber;
        label = 'Moyen';
        break;
      case 4:
        icon = Icons.sentiment_satisfied;
        color = Colors.lightGreen;
        label = 'Bien';
        break;
      case 5:
        icon = Icons.sentiment_very_satisfied;
        color = Colors.green;
        label = 'Excellent !';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
