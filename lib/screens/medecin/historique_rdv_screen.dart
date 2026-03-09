import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/doctor_service.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';

class HistoriqueRdvScreen extends StatefulWidget {
  final String medecinId;
  final Future<String> Function(String) getPatientName;

  const HistoriqueRdvScreen({
    super.key,
    required this.medecinId,
    required this.getPatientName,
  });

  @override
  State<HistoriqueRdvScreen> createState() => _HistoriqueRdvScreenState();
}

class _HistoriqueRdvScreenState extends State<HistoriqueRdvScreen> {
  StatutRDV? _selectedStatutFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filtres ──────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('Tous', null),
              const SizedBox(width: 8),
              _buildFilterChip(
                'En attente',
                StatutRDV.enAttente,
                Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildFilterChip('Confirmés', StatutRDV.confirme, Colors.green),
              const SizedBox(width: 8),
              _buildFilterChip('Terminés', StatutRDV.termine, Colors.grey),
              const SizedBox(width: 8),
              _buildFilterChip('Annulés', StatutRDV.annule, Colors.red),
              const SizedBox(width: 8),
              _buildFilterChip('Absents', StatutRDV.absent, Colors.deepOrange),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Liste ────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<RendezVous>>(
            stream: DoctorService.getRendezVousStream(widget.medecinId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var rdvList = snapshot.data ?? [];

              // Appliquer le filtre de statut
              if (_selectedStatutFilter != null) {
                rdvList = rdvList
                    .where((r) => r.statut == _selectedStatutFilter)
                    .toList();
              }

              // Trier par date décroissante (plus récent au plus ancien)
              rdvList.sort((a, b) {
                final dateA =
                    a.dateHeure ?? DateTime.fromMillisecondsSinceEpoch(0);
                final dateB =
                    b.dateHeure ?? DateTime.fromMillisecondsSinceEpoch(0);
                return dateB.compareTo(dateA);
              });

              if (rdvList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun rendez-vous trouvé',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Grouper par mois/année pour un meilleur affichage (optionnel,
              // on fait simple avec une liste continue pour l'instant)
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                itemCount: rdvList.length,
                itemBuilder: (context, i) {
                  final rdv = rdvList[i];
                  return _HistoryCard(
                    rdv: rdv,
                    getPatientName: widget.getPatientName,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/medecin-detail-rdv',
                        arguments: {'rdv': rdv},
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    StatutRDV? statut, [
    Color? activeColor,
  ]) {
    final isSelected = _selectedStatutFilter == statut;
    final color = activeColor ?? AppColors.navyDark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatutFilter = selected ? statut : null;
        });
      },
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: isSelected
          ? BorderSide(color: color.withValues(alpha: 0.5))
          : const BorderSide(color: Colors.black12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RendezVous rdv;
  final Future<String> Function(String) getPatientName;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.rdv,
    required this.getPatientName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date/Time badge
              Container(
                width: 65,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.offWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  children: [
                    Text(
                      rdv.dateHeure != null
                          ? DateFormat('dd MMM').format(rdv.dateHeure!)
                          : '--',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rdv.dateHeure != null
                          ? DateFormat('HH:mm').format(rdv.dateHeure!)
                          : '--:--',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: getPatientName(rdv.patientId),
                      builder: (context, snap) {
                        return Text(
                          snap.data ?? 'Chargement...',
                          style: Theme.of(context).textTheme.titleMedium,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _typeLabel(rdv.typeVisite),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status Arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChipSimple(statut: rdv.statut),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black26,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(TypeVisite type) {
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

class _StatusChipSimple extends StatelessWidget {
  final StatutRDV statut;
  const _StatusChipSimple({required this.statut});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
