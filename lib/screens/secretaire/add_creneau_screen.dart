import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/secretaire_service.dart';
import '../../models/horaires_template.dart';
import '../../theme/app_theme.dart';

class AddCreneauScreen extends StatefulWidget {
  const AddCreneauScreen({super.key});

  @override
  State<AddCreneauScreen> createState() => _AddCreneauScreenState();
}

class _AddCreneauScreenState extends State<AddCreneauScreen> {
  String? _medecinId;
  final _service = SecretaireService();

  DateTime? _selectedDate;
  final List<TemplateInterval> _intervalles = [
    TemplateInterval(heureDebut: '08:00', heureFin: '12:00'),
  ];
  int _dureeMinutes = 30;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_medecinId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _medecinId = args;
        _loadMedecinDefaultDuration();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
      }
    }
  }

  Future<void> _loadMedecinDefaultDuration() async {
    if (_medecinId == null) return;
    final data = await _service.getMedecinData(_medecinId!);
    if (data != null && data.containsKey('dureeConsultationMin')) {
      if (mounted) {
        setState(() {
          _dureeMinutes = (data['dureeConsultationMin'] as num).toInt();
        });
      }
    }
  }

  void _addInterval() {
    setState(() {
      _intervalles.add(TemplateInterval(heureDebut: '14:00', heureFin: '18:00'));
    });
  }

  void _removeInterval(int index) {
    if (_intervalles.length > 1) {
      setState(() => _intervalles.removeAt(index));
    }
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final interval = _intervalles[index];
    final currentStr = isStart ? interval.heureDebut : interval.heureFin;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.tealDark, onPrimary: Colors.white, surface: Colors.white),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _intervalles[index] = TemplateInterval(
          heureDebut: isStart ? newTime : interval.heureDebut,
          heureFin: isStart ? interval.heureFin : newTime,
        );
      });
    }
  }

  Future<void> _confirmAndExecute({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );

    if (confirmed == true) onConfirm();
  }

  void _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez choisir une date')));
      return;
    }

    _confirmAndExecute(
      title: 'Générer le planning',
      message: 'Attention : Cela va écraser les créneaux existants pour cette journée. Les rendez-vous déjà pris seront annulés.',
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await _service.batchCreateCreneaux(
            medecinId: _medecinId!,
            dateJour: _selectedDate!,
            intervalles: _intervalles,
            dureeMinutes: _dureeMinutes,
            clearFirst: true,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Planning mis à jour avec succès !'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
          }
        }
      },
    );
  }

  void _clearDay() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez choisir une date')));
      return;
    }

    _confirmAndExecute(
      title: 'Vider la journée',
      message: 'Voulez-vous marquer cette journée comme indisponible ? Tous les créneaux seront supprimés et les rendez-vous annulés.',
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await _service.bulkDeleteCreneaux(
            medecinId: _medecinId!,
            dates: [_selectedDate!],
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Journée vidée et marquée indisponible.'), backgroundColor: Colors.orange),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_medecinId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Gestion Journalière', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.tealDark,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('1. DATE DU PLANNING'),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 32),

                _buildSectionTitle('2. OUTILS RAPIDES'),
                const SizedBox(height: 16),
                _ActionCard(
                  onTap: _isLoading ? null : _clearDay,
                  icon: Icons.event_busy_rounded,
                  label: 'MARQUER COMME INDISPONIBLE',
                  subLabel: 'Vider et annuler les RDV',
                  color: Colors.red,
                ),
                const SizedBox(height: 32),
                
                _buildSectionTitle('3. GÉNÉRER DES CRÉNEAUX'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tealDark.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.tealDark.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.tealDark, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Les anciens créneaux de cette date seront écrasés.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.tealDark, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ..._intervalles.asMap().entries.map((entry) => _buildIntervalRow(entry.key, entry.value)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _addInterval,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('AJOUTER UNE PLAGE'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.tealDark,
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 24),
                _buildDurationDropdown(),
                
                const SizedBox(height: 48),
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeAccent,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: AppColors.orangeAccent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text('GÉNÉRER ET ÉCRASER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const _LoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.orangeAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.tealDark, fontSize: 12, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
             data: Theme.of(context).copyWith(
               colorScheme: const ColorScheme.light(primary: AppColors.tealDark, onPrimary: Colors.white),
             ),
             child: child!,
          ),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.orangeAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedDate == null ? 'Sélectionner une date...' : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!),
                style: GoogleFonts.inter(
                  fontSize: 16, 
                  fontWeight: FontWeight.w600,
                  color: _selectedDate == null ? AppColors.textGray : AppColors.textBlack,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalRow(int index, TemplateInterval interval) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTimeBox(interval.heureDebut, () => _pickTime(index, true))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('À', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: _buildTimeBox(interval.heureFin, () => _pickTime(index, false))),
          if (_intervalles.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                onPressed: () => _removeInterval(index),
                icon: const Icon(Icons.remove_circle_rounded, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          time, 
          textAlign: TextAlign.center, 
          style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.tealDark, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonFormField<int>(
        value: _dureeMinutes,
        decoration: InputDecoration(
          labelText: 'DURÉE DU CRÉNEAU',
          labelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          border: InputBorder.none,
        ),
        items: [15, 20, 30, 45, 60].map((m) => DropdownMenuItem(value: m, child: Text('$m MINUTES'))).toList(),
        onChanged: (v) => v != null ? setState(() => _dureeMinutes = v) : null,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;

  const _ActionCard({this.onTap, required this.icon, required this.label, required this.subLabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: color, fontSize: 12, letterSpacing: 1)),
                  Text(subLabel, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.tealDark),
              const SizedBox(height: 20),
              Text('Action en cours...', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
