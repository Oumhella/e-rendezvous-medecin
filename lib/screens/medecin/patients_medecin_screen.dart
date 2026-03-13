import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/doctor_service.dart';
import '../../models/rendez_vous.dart';
import '../../models/patient.dart';
import '../../models/utilisateur.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';

/// Écran Patients du médecin : liste des patients uniques avec nb de visites.
class PatientsMedecinScreen extends StatefulWidget {
  final String medecinId;

  const PatientsMedecinScreen({super.key, required this.medecinId});

  @override
  State<PatientsMedecinScreen> createState() => _PatientsMedecinScreenState();
}

class _PatientsMedecinScreenState extends State<PatientsMedecinScreen> {
  // Cache : patientId → (Patient, Utilisateur)
  final Map<String, _PatientInfo> _cache = {};

  String _searchQuery = '';

  /// Construit la liste agrégée à partir des RDV.
  Future<List<_PatientSummary>> _buildPatientList(
      List<RendezVous> rdvList) async {
    // Grouper les RDV par patientId
    final Map<String, List<RendezVous>> byPatient = {};
    for (final rdv in rdvList) {
      if (rdv.patientId.isEmpty) continue;
      byPatient.putIfAbsent(rdv.patientId, () => []).add(rdv);
    }

    final summaries = <_PatientSummary>[];

    for (final entry in byPatient.entries) {
      final patientId = entry.key;
      final rdvs = entry.value;

      // Charger depuis le cache ou Firestore
      if (!_cache.containsKey(patientId)) {
        final patient = await DoctorService.getPatientById(patientId);
        Utilisateur? utilisateur;
        if (patient != null && patient.utilisateurId.isNotEmpty) {
          utilisateur =
              await DoctorService.getUtilisateurById(patient.utilisateurId);
        }
        _cache[patientId] = _PatientInfo(patient: patient, utilisateur: utilisateur);
      }

      final info = _cache[patientId]!;
      final dernierRdv = (rdvs..sort((a, b) {
        if (a.dateHeure == null) return 1;
        if (b.dateHeure == null) return -1;
        return b.dateHeure!.compareTo(a.dateHeure!);
      })).first;

      summaries.add(_PatientSummary(
        patientId: patientId,
        info: info,
        nombreVisites: rdvs.length,
        rdvs: rdvs,
        dernierRdv: dernierRdv.dateHeure,
      ));
    }

    // Trier par nombre de visites décroissant
    summaries.sort((a, b) => b.nombreVisites.compareTo(a.nombreVisites));
    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Barre de recherche ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Rechercher un patient…',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.navyDark, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // ── Liste ────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<RendezVous>>(
            stream: DoctorService.getRendezVousStream(widget.medecinId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur : ${snapshot.error}'));
              }

              final rdvList = snapshot.data ?? [];

              return FutureBuilder<List<_PatientSummary>>(
                future: _buildPatientList(rdvList),
                builder: (context, futureSnap) {
                  if (futureSnap.connectionState == ConnectionState.waiting &&
                      _cache.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final patients = (futureSnap.data ?? []).where((p) {
                    if (_searchQuery.isEmpty) return true;
                    final nom = p.info.utilisateur?.nomComplet.toLowerCase() ?? '';
                    return nom.contains(_searchQuery);
                  }).toList();

                  if (patients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 14),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Aucun patient pour le moment'
                                : 'Aucun résultat pour "$_searchQuery"',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: patients.length,
                    itemBuilder: (context, i) => _PatientTile(
                      summary: patients[i],
                      onTap: () => _showPatientDetail(context, patients[i]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPatientDetail(BuildContext context, _PatientSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientDetailSheet(summary: summary),
    );
  }
}

// ── Tuile patient ───────────────────────────────────────────────────────

class _PatientTile extends StatelessWidget {
  final _PatientSummary summary;
  final VoidCallback onTap;

  const _PatientTile({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final util = summary.info.utilisateur;
    final nomComplet = util?.nomComplet ?? 'Patient inconnu';
    final initiales = util != null
        ? '${util.prenom.isNotEmpty ? util.prenom[0] : ''}${util.nom.isNotEmpty ? util.nom[0] : ''}'
            .toUpperCase()
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.lightBlue,
                child: Text(
                  initiales,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomComplet,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.navyDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (util != null && util.telephone.isNotEmpty)
                      Text(
                        util.telephone,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    if (summary.dernierRdv != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Dernière visite : ${DateFormat('dd/MM/yyyy', 'fr_FR').format(summary.dernierRdv!)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),

              // Badge visites
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${summary.nombreVisites}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.nombreVisites == 1 ? 'visite' : 'visites',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),

              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet détail patient ─────────────────────────────────────────

class _PatientDetailSheet extends StatelessWidget {
  final _PatientSummary summary;

  const _PatientDetailSheet({required this.summary});

  @override
  Widget build(BuildContext context) {
    final util = summary.info.utilisateur;
    final patient = summary.info.patient;
    final nomComplet = util?.nomComplet ?? 'Patient inconnu';
    final initiales = util != null
        ? '${util.prenom.isNotEmpty ? util.prenom[0] : ''}${util.nom.isNotEmpty ? util.nom[0] : ''}'
            .toUpperCase()
        : '?';

    // Trier les RDV du plus récent au plus ancien
    final rdvs = [...summary.rdvs]..sort((a, b) {
        if (a.dateHeure == null) return 1;
        if (b.dateHeure == null) return -1;
        return b.dateHeure!.compareTo(a.dateHeure!);
      });

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            // ── Poignée ─────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Avatar + nom ─────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.lightBlue,
                    child: Text(
                      initiales,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nomComplet,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.navyDark.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${summary.nombreVisites} ${summary.nombreVisites == 1 ? 'visite' : 'visites'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── Informations personnelles ────
            Text(
              'Informations',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            if (util != null) ...[
              _infoRow(Icons.phone_outlined, 'Téléphone', util.telephone),
              const SizedBox(height: 8),
              _infoRow(Icons.email_outlined, 'Email', util.email),
            ],
            if (patient != null) ...[
              const SizedBox(height: 8),
              _infoRow(Icons.credit_card_outlined, 'CIN', patient.cin),
              if (patient.dateNaissance != null) ...[
                const SizedBox(height: 8),
                _infoRow(
                  Icons.cake_outlined,
                  'Âge',
                  '${DateTime.now().year - patient.dateNaissance!.year} ans — né(e) le ${DateFormat('dd/MM/yyyy').format(patient.dateNaissance!)}',
                ),
              ],
              if (patient.adresse.isNotEmpty) ...[
                const SizedBox(height: 8),
                _infoRow(Icons.location_on_outlined, 'Adresse',
                    patient.adresse),
              ],
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ── Historique des visites ────────
            Text(
              'Historique des visites',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            ...rdvs.map((rdv) => _RdvHistoryItem(rdv: rdv)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ── Item d'historique dans la fiche patient ─────────────────────────────

class _RdvHistoryItem extends StatelessWidget {
  final RendezVous rdv;
  const _RdvHistoryItem({required this.rdv});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (rdv.statut) {
      StatutRDV.confirme => ('Confirmé', Colors.green),
      StatutRDV.termine => ('Terminé', Colors.grey),
      StatutRDV.annule => ('Annulé', Colors.red),
      StatutRDV.absent => ('Absent', Colors.deepOrange),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rdv.dateHeure != null
                      ? DateFormat('EEEE d MMM yyyy – HH:mm', 'fr_FR')
                          .format(rdv.dateHeure!)
                      : 'Date inconnue',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.navyDark),
                ),
                if (rdv.motif.isNotEmpty || rdv.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    rdv.motif.isNotEmpty ? rdv.motif : rdv.notes,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modèles internes ────────────────────────────────────────────────────

class _PatientInfo {
  final Patient? patient;
  final Utilisateur? utilisateur;
  const _PatientInfo({this.patient, this.utilisateur});
}

class _PatientSummary {
  final String patientId;
  final _PatientInfo info;
  final int nombreVisites;
  final List<RendezVous> rdvs;
  final DateTime? dernierRdv;

  const _PatientSummary({
    required this.patientId,
    required this.info,
    required this.nombreVisites,
    required this.rdvs,
    this.dernierRdv,
  });
}
