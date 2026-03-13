import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/doctor_service.dart';
import '../../models/creneau_horaire.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';

/// Écran Planning du médecin :
/// - Navigation semaine par semaine en haut
/// - Créneaux + rendez-vous du jour sélectionné en bas
class PlanningMedecinScreen extends StatefulWidget {
  final String medecinId;
  final Future<String> Function(String) getPatientName;

  const PlanningMedecinScreen({
    super.key,
    required this.medecinId,
    required this.getPatientName,
  });

  @override
  State<PlanningMedecinScreen> createState() => _PlanningMedecinScreenState();
}

class _PlanningMedecinScreenState extends State<PlanningMedecinScreen> {
  late DateTime _today;
  late DateTime _selectedDay;
  late DateTime _weekStart; // lundi de la semaine affichée

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(DateTime.now());
    _selectedDay = _today;
    // Trouver le lundi de la semaine courante
    _weekStart = _mondayOf(_today);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Retourne le lundi de la semaine contenant [d].
  DateTime _mondayOf(DateTime d) {
    return d.subtract(Duration(days: d.weekday - 1));
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  void _previousWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekHeader(),
        _buildDayRow(),
        const Divider(height: 1),
        Expanded(child: _buildContent()),
      ],
    );
  }

  // ── En-tête semaine (flèches + plage de dates) ───────────────────────

  Widget _buildWeekHeader() {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    final sameMonth = _weekStart.month == weekEnd.month;
    final sameYear = _weekStart.year == weekEnd.year;

    String rangeLabel;
    if (sameMonth) {
      rangeLabel =
          '${_weekStart.day} – ${DateFormat('d MMM yyyy', 'fr_FR').format(weekEnd)}';
    } else if (sameYear) {
      rangeLabel =
          '${DateFormat('d MMM', 'fr_FR').format(_weekStart)} – ${DateFormat('d MMM yyyy', 'fr_FR').format(weekEnd)}';
    } else {
      rangeLabel =
          '${DateFormat('d MMM yyyy', 'fr_FR').format(_weekStart)} – ${DateFormat('d MMM yyyy', 'fr_FR').format(weekEnd)}';
    }

    return Container(
      color: AppColors.navyDark,
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            onPressed: _previousWeek,
            tooltip: 'Semaine précédente',
          ),
          Expanded(
            child: Text(
              rangeLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
            onPressed: _nextWeek,
            tooltip: 'Semaine suivante',
          ),
        ],
      ),
    );
  }

  // ── Rangée des 7 jours ───────────────────────────────────────────────

  Widget _buildDayRow() {
    return Container(
      color: AppColors.navyDark,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      child: Row(
        children: _weekDays.map((day) => Expanded(child: _buildDayItem(day))).toList(),
      ),
    );
  }

  Widget _buildDayItem(DateTime day) {
    final isSelected = _dateOnly(day) == _selectedDay;
    final isToday = _dateOnly(day) == _today;

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = _dateOnly(day)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday && !isSelected
              ? Border.all(
                  color: AppColors.lightBlue.withValues(alpha: 0.6), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('E', 'fr_FR').format(day).substring(0, 3),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.navyDark
                    : isToday
                        ? AppColors.lightBlue
                        : Colors.white60,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.navyDark : Colors.white,
              ),
            ),
            if (isToday && !isSelected)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(top: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightBlue,
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Contenu principal (créneaux + RDV du jour) ───────────────────────

  Widget _buildContent() {
    return StreamBuilder<List<CreneauHoraire>>(
      stream: DoctorService.getCreneauxStream(widget.medecinId),
      builder: (context, creneauxSnap) {
        return StreamBuilder<List<RendezVous>>(
          stream: DoctorService.getRendezVousStream(widget.medecinId),
          builder: (context, rdvSnap) {
            if (creneauxSnap.connectionState == ConnectionState.waiting ||
                rdvSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allCreneaux = creneauxSnap.data ?? [];
            final allRdv = rdvSnap.data ?? [];

            // Filtrer les créneaux pour le jour sélectionné
            final creneaux = allCreneaux
                .where((c) =>
                    c.dateJour != null &&
                    _dateOnly(c.dateJour!) == _selectedDay)
                .toList()
              ..sort((a, b) => a.heureDebut.compareTo(b.heureDebut));

            // Filtrer les RDV pour le jour sélectionné
            final rdvDuJour = allRdv
                .where((r) =>
                    r.dateHeure != null &&
                    _dateOnly(r.dateHeure!) == _selectedDay)
                .toList();

            // En-tête du jour sélectionné
            final header = Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedDay == _today)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Aujourd'hui",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.navyDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );

            if (creneaux.isEmpty) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded,
                              size: 64,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 14),
                          Text(
                            'Aucun créneau ce jour',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: creneaux.length + 1, // +1 pour le header
              itemBuilder: (context, i) {
                if (i == 0) return header;
                final creneau = creneaux[i - 1];

                // Chercher un RDV qui correspond à ce créneau
                final rdv = rdvDuJour.cast<RendezVous?>().firstWhere(
                  (r) {
                    if (r == null || r.dateHeure == null) return false;
                    final heureRdv =
                        DateFormat('HH:mm').format(r.dateHeure!);
                    return heureRdv == creneau.heureDebut;
                  },
                  orElse: () => null,
                );

                return _CreneauTile(
                  creneau: creneau,
                  rdv: rdv,
                  getPatientName: widget.getPatientName,
                  onTap: rdv != null
                      ? () => Navigator.pushNamed(
                            context,
                            '/medecin-detail-rdv',
                            arguments: {'rdv': rdv},
                          )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ── Tuile créneau ──────────────────────────────────────────────────────

class _CreneauTile extends StatelessWidget {
  final CreneauHoraire creneau;
  final RendezVous? rdv;
  final Future<String> Function(String) getPatientName;
  final VoidCallback? onTap;

  const _CreneauTile({
    required this.creneau,
    required this.rdv,
    required this.getPatientName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRdv = rdv != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Colonne heure ──────────────────────
            SizedBox(
              width: 52,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    creneau.heureDebut,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasRdv ? AppColors.navyDark : Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    creneau.heureFin,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Ligne verticale + point ────────────
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasRdv
                        ? _statutColor(rdv!.statut)
                        : creneau.disponible
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                    border: Border.all(
                      color: hasRdv
                          ? _statutColor(rdv!.statut)
                          : creneau.disponible
                              ? Colors.green.shade500
                              : Colors.grey.shade400,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // ── Carte du créneau ───────────────────
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: hasRdv
                        ? _statutColor(rdv!.statut).withValues(alpha: 0.08)
                        : creneau.disponible
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasRdv
                          ? _statutColor(rdv!.statut).withValues(alpha: 0.3)
                          : creneau.disponible
                              ? Colors.green.shade200
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: hasRdv
                      ? _buildRdvContent(context)
                      : _buildLibreContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibreContent() {
    return Row(
      children: [
        Icon(
          creneau.disponible
              ? Icons.check_circle_outline_rounded
              : Icons.lock_outline_rounded,
          size: 16,
          color: creneau.disponible
              ? Colors.green.shade600
              : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          creneau.disponible ? 'Créneau libre' : 'Réservé',
          style: TextStyle(
            fontSize: 13,
            color: creneau.disponible
                ? Colors.green.shade700
                : Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRdvContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: FutureBuilder<String>(
                future: getPatientName(rdv!.patientId),
                builder: (context, snap) => Text(
                  snap.data ?? '...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.navyDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _StatutBadge(statut: rdv!.statut),
          ],
        ),
        if (rdv!.motif.isNotEmpty || rdv!.notes.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            rdv!.motif.isNotEmpty ? rdv!.motif : rdv!.notes,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(_typeIcon(rdv!.typeVisite),
                size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              _typeLabel(rdv!.typeVisite),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Color _statutColor(StatutRDV s) {
    switch (s) {
      case StatutRDV.confirme:
        return Colors.green;
      case StatutRDV.annule:
        return Colors.red;
      case StatutRDV.termine:
        return Colors.grey;
      case StatutRDV.absent:
        return Colors.deepOrange;
    }
  }

  IconData _typeIcon(TypeVisite t) {
    switch (t) {
      case TypeVisite.cabinet:
        return Icons.local_hospital_outlined;
      case TypeVisite.teleconsultation:
        return Icons.video_camera_front_outlined;
      case TypeVisite.domicile:
        return Icons.home_outlined;
    }
  }

  String _typeLabel(TypeVisite t) {
    switch (t) {
      case TypeVisite.cabinet:
        return 'Cabinet';
      case TypeVisite.teleconsultation:
        return 'Téléconsultation';
      case TypeVisite.domicile:
        return 'Domicile';
    }
  }
}

// ── Badge statut compact ────────────────────────────────────────────────

class _StatutBadge extends StatelessWidget {
  final StatutRDV statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (statut) {
      StatutRDV.confirme => ('Confirmé', Colors.green),
      StatutRDV.annule => ('Annulé', Colors.red),
      StatutRDV.termine => ('Terminé', Colors.grey),
      StatutRDV.absent => ('Absent', Colors.deepOrange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color.shade700,
        ),
      ),
    );
  }
}
