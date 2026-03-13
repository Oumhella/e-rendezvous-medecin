import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/secretaire_service.dart';
import '../../models/creneau_horaire.dart';
import '../../theme/app_theme.dart';
import './templates/templates_list_screen.dart';

class WeeklyPlannerScreen extends StatefulWidget {
  final String medecinId;
  final bool embedded;

  const WeeklyPlannerScreen({super.key, required this.medecinId, this.embedded = false});

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

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildContent();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Planification Hebdo', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.tealDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TemplatesListScreen(medecinId: widget.medecinId)),
            ),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final days = _getWeekDays(_focusedDate);
    final weekRange = '${DateFormat('dd MMM', 'fr').format(days.first)} - ${DateFormat('dd MMM yyyy', 'fr').format(days.last)}';

    return Stack(
      children: [
        Column(
          children: [
              // --- Week Selector Area ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ArrowButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: () => setState(() => _focusedDate = _focusedDate.subtract(const Duration(days: 7))),
                    ),
                    Column(
                      children: [
                        Text('SEMAINE DU', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textGray, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          weekRange.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w900, color: AppColors.tealDark, fontSize: 16),
                        ),
                      ],
                    ),
                    _ArrowButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => setState(() => _focusedDate = _focusedDate.add(const Duration(days: 7))),
                    ),
                  ],
                ),
              ),
              
              // --- Days List ---
              Expanded(
                child: StreamBuilder<List<CreneauHoraire>>(
                  stream: _service.getCreneauxForRangeStream(
                    widget.medecinId, 
                    days.first, 
                    days.last.add(const Duration(days: 1))
                  ),
                  builder: (context, snapshot) {
                    final allSlots = snapshot.data ?? [];
                    
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 150),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final dateKey = DateTime(day.year, day.month, day.day);
                        final isSelected = _selectedDays.contains(dateKey);
                        final isToday = dateKey == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

                        final daySlots = allSlots.where((s) {
                          final dj = s.dateJour;
                          return dj != null && dj.year == day.year && dj.month == day.month && dj.day == day.day;
                        }).toList();

                        return _DayCard(
                          day: day,
                          isSelected: isSelected,
                          isToday: isToday,
                          slotCount: daySlots.length,
                          onToggle: () => _toggleDay(day),
                          onTap: () {
                            final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day);
                            Navigator.pushNamed(context, '/creneaux', arguments: {
                              'medecinId': widget.medecinId,
                              'initialDate': dateStr,
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          
          // --- Quick Actions Floating Bar ---
          if (_selectedDays.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildActionPanel(),
            ),
            
          if (_isProcessing)
            const _ProcessingOverlay(),
        ],
      );
  }

  Widget _buildActionPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.tealDark,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_selectedDays.length} jours sélectionnés',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PanelButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Appliquer modèle',
                  color: AppColors.orangeAccent,
                  onTap: _applyTemplate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PanelButton(
                  icon: Icons.delete_sweep_rounded,
                  label: 'Vider',
                  color: Colors.redAccent,
                  onTap: _bulkDelete,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _PanelButton(
              icon: Icons.copy_all_rounded,
              label: 'Dupliquer toute la semaine',
              color: AppColors.white.withOpacity(0.2),
              textColor: Colors.white,
              onTap: _duplicateWeek,
            ),
          ),
        ],
      ),
    );
  }

  // Logic methods (truncated/kept from original for brevity, focusing on UI update here)
  Future<void> _applyTemplate() async {
    final templates = await _service.getTemplatesStream(widget.medecinId).first;
    if (templates.isEmpty) return;
    final selectedTemplateId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Choisir un modèle', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        children: templates.map((t) => SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, t.id),
          child: Text(t.nom),
        )).toList(),
      ),
    );
    if (selectedTemplateId == null) return;
    
    final numWeeks = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Répéter sur combien de semaines ?'),
        children: [1, 2, 4, 8].map((n) => SimpleDialogOption(
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
        await _service.applyTemplateToDays(medecinId: widget.medecinId, dates: allDates, templateId: selectedTemplateId);
        setState(() => _selectedDays.clear());
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _bulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vider la sélection ?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: const Text('Cela supprimera tous les créneaux disponibles pour ces jours.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('CONFIRMER')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await _service.bulkDeleteCreneaux(medecinId: widget.medecinId, dates: _selectedDays.toList());
        setState(() => _selectedDays.clear());
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _duplicateWeek() async {
    setState(() => _isProcessing = true);
    try {
      await _service.duplicateWeekAvailability(
        medecinId: widget.medecinId,
        sourceWeekStart: _focusedDate,
        targetWeekStart: _focusedDate.add(const Duration(days: 7)),
      );
      setState(() => _focusedDate = _focusedDate.add(const Duration(days: 7)));
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final int slotCount;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.slotCount,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? Border.all(color: AppColors.tealDark, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date Indicator
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isToday ? AppColors.orangeAccent : AppColors.cream,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      color: isToday ? Colors.white : AppColors.textBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Day Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE', 'fr').format(day).toUpperCase(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.tealDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM', 'fr').format(day),
                      style: const TextStyle(color: AppColors.textGray, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Status Badge
              _StatusBadge(count: slotCount),
              const SizedBox(width: 12),
              // Selection Checkbox
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  activeColor: AppColors.tealDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int count;
  const _StatusBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    bool isEmpty = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isEmpty ? Colors.grey.withOpacity(0.1) : AppColors.tealDark.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isEmpty ? 'LIBRE/CONGÉ' : '$count CRÉNEAUX',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isEmpty ? AppColors.textGray : AppColors.tealDark,
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.beigeGray),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.tealDark, size: 24),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _PanelButton({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor ?? Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(color: textColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.tealDark),
              SizedBox(height: 20),
              Text('Opération en cours...', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
