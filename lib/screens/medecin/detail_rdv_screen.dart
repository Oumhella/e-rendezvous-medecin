import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/doctor_service.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../models/patient.dart';
import '../../models/utilisateur.dart';
import '../../theme/app_theme.dart';

class DetailRdvScreen extends StatefulWidget {
  const DetailRdvScreen({super.key});

  @override
  State<DetailRdvScreen> createState() => _DetailRdvScreenState();
}

class _DetailRdvScreenState extends State<DetailRdvScreen> {
  late RendezVous _rdv;
  bool _initialized = false;
  bool _isLoading = false;

  Patient? _patient;
  Utilisateur? _utilisateur;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('rdv')) {
        _rdv = args['rdv'] as RendezVous;
        _loadPatientDetails();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pop(context);
        });
      }
      _initialized = true;
    }
  }

  Future<void> _loadPatientDetails() async {
    setState(() => _isLoading = true);
    try {
      final patient = await DoctorService.getPatientById(_rdv.patientId);
      if (patient != null) {
        final utilisateur = await DoctorService.getUtilisateurById(
          patient.utilisateurId,
        );
        setState(() {
          _patient = patient;
          _utilisateur = utilisateur;
        });
      }
    } catch (e) {
      debugPrint('Error loading patient: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatut(StatutRDV newStatut) async {
    setState(() => _isLoading = true);
    try {
      await DoctorService.updateRendezVousStatut(_rdv.id, newStatut);
      setState(() {
        _rdv = _rdv.copyWith(statut: newStatut);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(title: const Text('Détails du Rendez-vous')),
      body: _isLoading && _patient == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPatientDetails,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildPatientCard(),
                  const SizedBox(height: 16),
                  _buildRdvDetailsCard(),
                  const SizedBox(height: 24),
                  _buildActionsButtons(),
                ],
              ),
            ),
    );
  }

  // ── Header (Date & Statut) ─────────────────────────────────────────

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date du rendez-vous',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _rdv.dateHeure != null
                          ? DateFormat.yMMMMd('fr_FR').format(_rdv.dateHeure!)
                          : 'Non définie',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                _StatusChipDetailed(statut: _rdv.statut),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: AppColors.navyDark),
                const SizedBox(width: 8),
                Text(
                  _rdv.dateHeure != null
                      ? DateFormat('HH:mm').format(_rdv.dateHeure!)
                      : '--:--',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  _getTypeIcon(_rdv.typeVisite),
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  _getTypeLabel(_rdv.typeVisite),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Patient Info ───────────────────────────────────────────────────

  Widget _buildPatientCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_rounded, color: AppColors.navyDark),
                const SizedBox(width: 8),
                Text(
                  'Informations du Patient',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_utilisateur == null)
              const Text(
                'Chargement des informations...',
                style: TextStyle(color: Colors.grey),
              )
            else ...[
              _buildInfoRow(
                Icons.badge_outlined,
                'Nom',
                _utilisateur!.nomComplet,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.phone_outlined,
                'Téléphone',
                _utilisateur!.telephone,
              ),
              const SizedBox(height: 12),
              if (_patient != null)
                _buildInfoRow(Icons.credit_card_outlined, 'CIN', _patient!.cin),
              const SizedBox(height: 12),
              if (_patient != null)
                _buildInfoRow(
                  Icons.cake_outlined,
                  'Âge',
                  _patient!.dateNaissance != null
                      ? '${DateTime.now().year - _patient!.dateNaissance!.year} ans'
                      : 'Non renseigné',
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Rendez-vous Details ────────────────────────────────────────────

  Widget _buildRdvDetailsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: AppColors.navyDark),
                const SizedBox(width: 8),
                Text(
                  'Détails',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Créé le',
              _rdv.dateReservation != null
                  ? DateFormat(
                      'dd/MM/yyyy HH:mm',
                      'fr_FR',
                    ).format(_rdv.dateReservation!)
                  : 'Inconnue',
            ),
            if (_rdv.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(_rdv.notes),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── Actions Buttons ────────────────────────────────────────────────

  Widget _buildActionsButtons() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Selon le statut actuel, on affiche différents boutons
    switch (_rdv.statut) {
      case StatutRDV.enAttente:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirmer le RDV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _updateStatut(StatutRDV.confirme),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Annuler le RDV'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () => _showCancelDialog(),
            ),
          ],
        );

      case StatutRDV.confirme:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Marquer comme Terminé'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _updateStatut(StatutRDV.termine),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_off_outlined),
                    label: const Text('Absent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.deepOrange),
                    ),
                    onPressed: () => _updateStatut(StatutRDV.absent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () => _showCancelDialog(),
                  ),
                ),
              ],
            ),
          ],
        );

      case StatutRDV.termine:
      case StatutRDV.annule:
      case StatutRDV.absent:
        // Statuts finaux, pas d'actions (ou option de révoquer l'annulation si voulu)
        return Center(
          child: Text(
            'Ce rendez-vous est ${_rdv.statut.name}. Aucune action possible.',
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le rendez-vous'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ce rendez-vous ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non, retour'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatut(StatutRDV.annule);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(TypeVisite type) {
    switch (type) {
      case TypeVisite.cabinet:
        return Icons.local_hospital_outlined;
      case TypeVisite.teleconsultation:
        return Icons.video_camera_front_outlined;
      case TypeVisite.domicile:
        return Icons.home_outlined;
    }
  }

  String _getTypeLabel(TypeVisite type) {
    switch (type) {
      case TypeVisite.cabinet:
        return 'Cabinet';
      case TypeVisite.teleconsultation:
        return 'Téléconsultation';
      case TypeVisite.domicile:
        return 'Domicile';
    }
  }
}

class _StatusChipDetailed extends StatelessWidget {
  final StatutRDV statut;
  const _StatusChipDetailed({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (statut) {
      StatutRDV.enAttente => ('En attente', Colors.orange),
      StatutRDV.confirme => ('Confirmé', Colors.green),
      StatutRDV.annule => ('Annulé', Colors.red),
      StatutRDV.termine => ('Terminé', Colors.grey),
      StatutRDV.absent => ('Absent', Colors.deepOrange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
