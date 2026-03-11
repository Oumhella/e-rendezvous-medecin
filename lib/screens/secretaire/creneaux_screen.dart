import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_medecinId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _medecinId = args;
      } else {
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
      appBar: AppBar(
        title: const Text('Gestion des Créneaux'),
      ),
      body: StreamBuilder<List<CreneauHoraire>>(
        stream: _service.getCreneauxStream(_medecinId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final creneaux = snapshot.data ?? [];
          if (creneaux.isEmpty) {
            return const Center(
              child: Text(
                'Aucun créneau configuré.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Sort by date then start time
          creneaux.sort((a, b) {
            final dateA = a.dateJour ?? DateTime(2000);
            final dateB = b.dateJour ?? DateTime(2000);
            int dateComp = dateA.compareTo(dateB);
            if (dateComp != 0) return dateComp;
            return a.heureDebut.compareTo(b.heureDebut);
          });

          // Group by Date
          Map<String, List<CreneauHoraire>> grouped = {};
          final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
          
          for (var c in creneaux) {
            if (c.dateJour == null) continue;
            final dateKey = dateFormat.format(c.dateJour!);
            if (!grouped.containsKey(dateKey)) {
              grouped[dateKey] = [];
            }
            grouped[dateKey]!.add(c);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.keys.length,
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.elementAt(index);
              final slots = grouped[dateKey]!;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateKey.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: slots.map((c) {
                          return _buildSlotChip(c);
                        }).toList(),
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
        onPressed: () {
          Navigator.pushNamed(context, '/add-creneau', arguments: _medecinId);
        },
        icon: const Icon(Icons.add),
        label: const Text('Générer'),
        backgroundColor: AppColors.navyDark,
      ),
    );
  }

  Widget _buildSlotChip(CreneauHoraire c) {
    bool isPast = false;
    if (c.dateJour != null) {
      try {
        final parts = c.heureDebut.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final slotTime = DateTime(c.dateJour!.year, c.dateJour!.month, c.dateJour!.day, h, m);
        isPast = slotTime.isBefore(DateTime.now());
      } catch (_) {}
    }

    final color = !c.disponible
        ? Colors.grey.shade300
        : isPast 
          ? Colors.red.shade100 
          : AppColors.lightBlue.withValues(alpha: 0.4);

    return InkWell(
      onLongPress: () => _afficherOptionsCreneau(c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !c.disponible ? Colors.grey : AppColors.navyDark.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              '${c.heureDebut} - ${c.heureFin}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: !c.disponible ? Colors.grey.shade600 : AppColors.navyDark,
              ),
            ),
            if (!c.disponible)
              const Text(
                'Réservé',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  void _afficherOptionsCreneau(CreneauHoraire c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  c.disponible ? Icons.block : Icons.check_circle,
                  color: AppColors.navyDark,
                ),
                title: Text(c.disponible ? 'Marquer indisponible' : 'Marquer disponible'),
                onTap: () {
                  Navigator.pop(ctx);
                  _basculerDisponibilite(c, !c.disponible);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _supprimerCreneau(c.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
