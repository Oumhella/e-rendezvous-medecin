import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/secretaire_service.dart';
import '../../models/creneau_horaire.dart';
import '../../theme/app_theme.dart';
import './templates/templates_list_screen.dart';

class WeeklyPlannerScreen extends StatefulWidget {
  final String medecinId;

  const WeeklyPlannerScreen({super.key, required this.medecinId});

  @override
  State<WeeklyPlannerScreen> createState() => _WeeklyPlannerScreenState();
}

class _WeeklyPlannerScreenState extends State<WeeklyPlannerScreen> {
  final SecretaireService _service = SecretaireService();
  DateTime _focusedDate = DateTime.now();
  final Set<DateTime> _selectedDays = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Normalize to start of current week (Monday)
    _focusedDate = _getMonday(_focusedDate);
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  List<DateTime> _getWeekDays(DateTime monday) {
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  void _toggleDay(DateTime day) {
    setState(() {
      final d = DateTime(day.year, day.month, day.day);
      if (_selectedDays.contains(d)) {
        _selectedDays.remove(d);
      } else {
        _selectedDays.add(d);
      }
    });
  }

  Future<void> _applyTemplate() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un jour.')),
      );
      return;
    }

    // Fetch templates to show a picker
    final templates = await _service.getTemplatesStream(widget.medecinId).first;
    if (templates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun modèle disponible. Créez-en un d\'abord.')),
        );
      }
      return;
    }

    if (!mounted) return;

    // 1. Choose Template
    final selectedTemplateId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Sélectionner un modèle'),
        children: templates.map((t) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, t.id),
          child: Text(t.nom),
        )).toList(),
      ),
    );

    if (selectedTemplateId == null) return;
    if (!mounted) return;

    // 2. Choose Number of Weeks
    final numWeeks = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Combien de semaines ?'),
        children: [1, 2, 4, 8, 12, 24].map((n) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, n),
          child: Text('$n semaine(s)'),
        )).toList(),
      ),
    );

    if (numWeeks != null) {
      setState(() => _isProcessing = true);
      try {
        final List<DateTime> allDates = [];
        for (var date in _selectedDays) {
          for (int i = 0; i < numWeeks; i++) {
            allDates.add(date.add(Duration(days: i * 7)));
          }
        }

        if (!mounted) return;
        await _service.applyTemplateToDays(
          medecinId: widget.medecinId,
          dates: allDates,
          templateId: selectedTemplateId,
        );
        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Modèle appliqué sur $numWeeks semaine(s) !'), 
              backgroundColor: Colors.green
            ),
          );
          setState(() => _selectedDays.clear());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un jour.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la sélection ?'),
        content: const Text('Cela supprimera tous les créneaux disponibles. \n\nATTENTION : Si des rendez-vous sont déjà pris, ils seront annulés automatiquement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CONFIRMER LA SUPPRESSION'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _service.bulkDeleteCreneaux(
          medecinId: widget.medecinId,
          dates: _selectedDays.toList(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sélection vidée !'), backgroundColor: Colors.orange),
          );
          setState(() => _selectedDays.clear());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _duplicateWeek() async {
    final targetWeekStart = _focusedDate.add(const Duration(days: 7));
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dupliquer la semaine ?'),
        content: Text('Copier tous les créneaux de cette semaine vers la semaine du ${DateFormat('dd/MM').format(targetWeekStart)} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DUPLIQUER')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _service.duplicateWeekAvailability(
          medecinId: widget.medecinId,
          sourceWeekStart: _focusedDate,
          targetWeekStart: targetWeekStart,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semaine dupliquée !'), backgroundColor: Colors.green),
          );
          setState(() => _focusedDate = targetWeekStart);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _getWeekDays(_focusedDate);
    final weekRange = '${DateFormat('dd MMM', 'fr').format(days.first)} - ${DateFormat('dd MMM yyyy', 'fr').format(days.last)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planification Hebdomadaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Gérer les modèles',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TemplatesListScreen(medecinId: widget.medecinId)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: AppColors.lightBlue.withValues(alpha: 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _focusedDate = _focusedDate.subtract(const Duration(days: 7))),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Column(
                      children: [
                        const Text('Semaine du', style: TextStyle(color: Colors.grey)),
                        Text(weekRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    IconButton(
                      onPressed: () => setState(() => _focusedDate = _focusedDate.add(const Duration(days: 7))),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
              StreamBuilder<List<CreneauHoraire>>(
                stream: _service.getCreneauxForRangeStream(
                  widget.medecinId, 
                  days.first, 
                  days.last.add(const Duration(days: 1))
                ),
                builder: (context, slotSnapshot) {
                  if (slotSnapshot.hasError) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          'Erreur de chargement des indices: ${slotSnapshot.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final allSlots = slotSnapshot.data ?? [];
                  
                  return Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final dateKey = DateTime(day.year, day.month, day.day);
                        final isSelected = _selectedDays.contains(dateKey);
                        final isToday = dateKey == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                        final daySlots = allSlots.where((s) {
                          final dj = s.dateJour;
                          return dj != null && 
                                 dj.year == day.year && 
                                 dj.month == day.month && 
                                 dj.day == day.day;
                        }).toList();

                        return Card(
                          color: isSelected ? AppColors.navyDark.withValues(alpha: 0.1) : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected ? const BorderSide(color: AppColors.navyDark, width: 2) : BorderSide.none,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isToday ? AppColors.navyDark : Colors.grey.shade200,
                              foregroundColor: isToday ? Colors.white : Colors.black,
                              child: Text(DateFormat('d').format(day)),
                            ),
                            title: Text(DateFormat('EEEE', 'fr').format(day).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Row(
                              children: [
                                Text(DateFormat('dd MMMM', 'fr').format(day)),
                                if (daySlots.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.navyDark,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.navyDark.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      '${daySlots.length} CRÉNEAUX',
                                      style: const TextStyle(
                                        fontSize: 9, 
                                        fontWeight: FontWeight.w900, 
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'LIBRE / CONGÉ',
                                      style: TextStyle(
                                        fontSize: 9, 
                                        fontWeight: FontWeight.w900, 
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleDay(day),
                              activeColor: AppColors.navyDark,
                            ),
                            onTap: () {
                              final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day);
                              Navigator.pushNamed(
                                context,
                                '/creneaux',
                                arguments: {
                                  'medecinId': widget.medecinId,
                                  'initialDate': dateStr,
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _processing ? null : _applyTemplate,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('APPLIQUER UN MODÈLE AUX JOURS SÉLECTIONNÉS'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyDark,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _bulkDelete,
                        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
                        label: const Text('VIDER LES JOURS SÉLECTIONNÉS', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _processing ? null : _duplicateWeek,
                        icon: const Icon(Icons.copy_all),
                        label: const Text('DUPLIQUER CETTE SEMAINE VERS LA SUIVANTE'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyDark,
                          side: const BorderSide(color: AppColors.navyDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isProcessing)
            const Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Traitement en cours...', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _processing => _isProcessing;
}
