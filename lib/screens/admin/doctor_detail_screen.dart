import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doctor.dart';
import '../../services/doctor_service.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  bool _isLoading = false;
  bool _isApproving = false;
  bool _isRejecting = false;

  // Couleurs
  static const cream = Color(0xFFF5F0E8);
  static const tealDark = Color(0xFF1E4545);
  static const teal = Color(0xFF3A9E8F);
  static const orange = Color(0xFFE8900A);
  static const green = Color(0xFF4CAF50);
  static const red = Color(0xFFF44336);
  static const white = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF888888);

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
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: white),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Détails du médecin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: white,
                          ),
                        ),
                      ),
                    ],
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
                          _buildDoctorInfo(),
                          const SizedBox(height: 30),
                          _buildProfessionalInfo(),
                          const SizedBox(height: 30),
                          _buildDocumentsInfo(),
                          const SizedBox(height: 30),
                          if (widget.doctor.statutMedecin == 'en_attente')
                            _buildActionButtons(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorInfo() {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    '${widget.doctor.nom[0]}${widget.doctor.prenom[0]}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: teal,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${widget.doctor.prenom} ${widget.doctor.nom}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.doctor.specialite,
                      style: const TextStyle(
                        fontSize: 16,
                        color: textGrey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildStatusBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Téléphone', widget.doctor.telephone),
          _buildInfoRow('Adresse', widget.doctor.adresseCabinet),
          _buildInfoRow('Expérience', '${widget.doctor.anneesExperience} ans'),
          _buildInfoRow('Consultation en ligne', 
              widget.doctor.consultationEnLigne ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;
    
    switch (widget.doctor.statutMedecin) {
      case 'valide':
        badgeColor = green;
        statusText = 'Validé';
        break;
      case 'en_attente':
        badgeColor = orange;
        statusText = 'En attente';
        break;
      case 'rejete':
        badgeColor = red;
        statusText = 'Rejeté';
        break;
      default:
        badgeColor = textGrey;
        statusText = 'Inconnu';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfo() {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations professionnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 15),
          _buildInfoRow('Numéro d\'ordre', widget.doctor.cin ?? 'Non spécifié'),
          _buildInfoRow('Tarif consultation', '${widget.doctor.tarif} DH'),
          _buildInfoRow('Durée consultation', '${widget.doctor.dureConsultationMin} minutes'),
          _buildInfoRow('Note moyenne', '${widget.doctor.noteMoyenne.toStringAsFixed(1)}/5'),
          if (widget.doctor.dateCreation != null)
            _buildInfoRow(
              'Date de création', 
              '${(widget.doctor.dateCreation!.toDate()).day}/${(widget.doctor.dateCreation!.toDate()).month}/${(widget.doctor.dateCreation!.toDate()).year}'
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentsInfo() {
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 15),
          _buildDocumentRow('Diplôme', widget.doctor.diplome),
          _buildDocumentRow('Certificat d\'exercice', widget.doctor.certificatExercice),
          _buildDocumentRow('CV', widget.doctor.cv),
          _buildDocumentRow('CIN', widget.doctor.cin),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.description, color: teal, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: ${value ?? 'Non fourni'}',
              style: const TextStyle(
                fontSize: 14,
                color: textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isApproving ? null : _approveDoctor,
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isApproving
                ? const CircularProgressIndicator(color: white)
                : const Text(
                    'Approuver le médecin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isRejecting ? null : _rejectDoctor,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isRejecting
                ? const CircularProgressIndicator(color: red)
                : const Text(
                    'Rejeter le médecin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: red,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveDoctor() async {
    setState(() => _isApproving = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('medecin')
          .doc(widget.doctor.id)
          .update({
        'statutMedecin': 'valide',
        'dateValidationCompte': Timestamp.now(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médecin approuvé avec succès'),
            backgroundColor: green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: red,
          ),
        );
      }
    } finally {
      setState(() => _isApproving = false);
    }
  }

  Future<void> _rejectDoctor() async {
    setState(() => _isRejecting = true);
    
    try {
      await FirebaseFirestore.instance
          .collection('medecin')
          .doc(widget.doctor.id)
          .update({
        'statutMedecin': 'rejete',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médecin rejeté'),
            backgroundColor: red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: red,
          ),
        );
      }
    } finally {
      setState(() => _isRejecting = false);
    }
  }
}

// Custom painters réutilisés
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

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
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
