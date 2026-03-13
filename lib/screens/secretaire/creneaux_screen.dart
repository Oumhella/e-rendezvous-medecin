import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/creneau_horaire.dart';
import '../../services/secretaire_service.dart';
import '../../theme/app_theme.dart';

class CreneauxScreen extends StatefulWidget {
  const CreneauxScreen({super.key});

  @override
  State<CreneauxScreen> createState() => _CreneauxScreenState();
}

class _CreneauxScreenState extends State<CreneauxScreen> {
  final _service = SecretaireService();
  String? _medecinId;
  String? _initialDateKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_medecinId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _medecinId = args;
      } else if (args is Map<String, dynamic>) {
        _medecinId = args['medecinId'];
        _initialDateKey = args['initialDate'];
      }
      
      if (_medecinId == null || _medecinId!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    }
  }

  void _supprimerCreneau(String id) async {
    try {
      await _service.deleteCreneau(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Créneau supprimé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _basculerDisponibilite(CreneauHoraire creneau, bool isDisponible) async {
    try {
      final updated = CreneauHoraire(
        id: creneau.id,
        heureDebut: creneau.heureDebut,
        heureFin: creneau.heureFin,
        dateJour: creneau.dateJour,
        medecinId: creneau.medecinId,
        disponible: isDisponible,
      );
      await _service.updateCreneau(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de mise à jour: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_medecinId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          _initialDateKey != null 
            ? 'Créneaux du ${_initialDateKey!.split(' ').sublist(1).join(' ')}' 
            : 'Gestion des Créneaux',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.tealDark,
        foregroundColor: Colors.white,
        actions: [
          if (_initialDateKey != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              onPressed: () => setState(() => _initialDateKey = null),
            ),
        ],
      ),
      body: StreamBuilder<List<CreneauHoraire>>(
        stream: _service.getCreneauxStream(_medecinId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.tealDark));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final creneaux = snapshot.data ?? [];
          if (creneaux.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textGray.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    _initialDateKey != null ? 'Aucun créneau pour ce jour.' : 'Aucun créneau configuré.',
                    style: GoogleFonts.inter(fontSize: 16, color: AppColors.textGray),
                  ),
                ],
              ),
            );
          }

          // Sort & Group
          creneaux.sort((a, b) {
            final dateA = a.dateJour ?? DateTime(2000);
            final dateB = b.dateJour ?? DateTime(2000);
            int dateComp = dateA.compareTo(dateB);
            if (dateComp != 0) return dateComp;
            return a.heureDebut.compareTo(b.heureDebut);
          });

          Map<String, List<CreneauHoraire>> grouped = {};
          final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
          for (var c in creneaux) {
            if (c.dateJour == null) continue;
            final dateKey = dateFormat.format(c.dateJour!);
            if (_initialDateKey != null && dateKey != _initialDateKey) continue;
            grouped.putIfAbsent(dateKey, () => []).add(c);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: grouped.keys.length,
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.elementAt(index);
              final slots = grouped[dateKey]!;

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.orangeAccent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dateKey.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.tealDark,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: slots.map((c) => _SlotChip(
                          creneau: c,
                          onTap: () => _afficherOptionsCreneau(c),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-creneau', arguments: _medecinId),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('GÉNÉRER'),
        backgroundColor: AppColors.orangeAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _afficherOptionsCreneau(CreneauHoraire c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SlotOptionsSheet(
        creneau: c,
        onToggle: () => _basculerDisponibilite(c, !c.disponible),
        onDelete: () => _supprimerCreneau(c.id),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final CreneauHoraire creneau;
  final VoidCallback onTap;

  const _SlotChip({required this.creneau, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isPast = false;
    if (creneau.dateJour != null) {
      try {
        final parts = creneau.heureDebut.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final slotTime = DateTime(creneau.dateJour!.year, creneau.dateJour!.month, creneau.dateJour!.day, h, m);
        isPast = slotTime.isBefore(DateTime.now());
      } catch (_) {}
    }

    final isReserved = !creneau.disponible;
    final bgColor = isReserved 
        ? AppColors.tealDark.withOpacity(0.1)
        : isPast 
          ? Colors.red.withOpacity(0.05)
          : AppColors.cream;
    
    final textColor = isReserved ? AppColors.tealDark : isPast ? Colors.red : AppColors.textBlack;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isReserved ? AppColors.tealDark.withOpacity(0.2) : AppColors.beigeGray,
          ),
        ),
        child: Column(
          children: [
            Text(
              '${creneau.heureDebut} - ${creneau.heureFin}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 13,
              ),
            ),
            if (isReserved)
              Text(
                'RÉSERVÉ',
                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.tealDark.withOpacity(0.5)),
              ),
            if (isPast && !isReserved)
              Text(
                'PASSÉ',
                style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.red.withOpacity(0.5)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SlotOptionsSheet extends StatelessWidget {
  final CreneauHoraire creneau;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SlotOptionsSheet({required this.creneau, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.beigeGray, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            Text(
              '${creneau.heureDebut} - ${creneau.heureFin}',
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(creneau.disponible ? Icons.block_rounded : Icons.check_circle_rounded, color: AppColors.tealDark),
              title: Text(creneau.disponible ? 'Marquer indisponible' : 'Marquer disponible', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                onToggle();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text('Supprimer ce créneau', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
