import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../services/secretaire_service.dart';
import '../../theme/app_theme.dart';

class EditReservationScreen extends StatefulWidget {
  const EditReservationScreen({super.key});

  @override
  State<EditReservationScreen> createState() => _EditReservationScreenState();
}

class _EditReservationScreenState extends State<EditReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SecretaireService();
  final _notesCtrl = TextEditingController();

  late RendezVous _rdv;
  bool _initialized = false;
  bool _saving = false;

  StatutRDV _selectedStatut = StatutRDV.confirme;
  TypeVisite _selectedType = TypeVisite.cabinet;
  DateTime? _selectedDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/login');
        });
        return;
      }
      _rdv = args as RendezVous;
      _notesCtrl.text = _rdv.notes;
      _selectedStatut = _rdv.statut;
      _selectedType = _rdv.typeVisite;
      _selectedDate = _rdv.dateHeure;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.tealDark, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate?.hour ?? 0,
          _selectedDate?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.tealDark, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && _selectedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = _rdv.copyWith(
        statut: _selectedStatut,
        typeVisite: _selectedType,
        dateHeure: _selectedDate,
        notes: _notesCtrl.text.trim(),
      );
      await _service.updateRendezVous(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Succès ✓'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _quickUpdateStatus(StatutRDV newStatus) async {
    setState(() {
      _selectedStatut = newStatus;
      _saving = true;
    });
    try {
      final updated = _rdv.copyWith(statut: newStatus);
      await _service.updateRendezVous(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statut mis à jour ✓'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Supprimer le RDV', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: const Text('Cette action est irréversible. Confirmer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteRendezVous(_rdv.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Modifier Rendez-vous', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.tealDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Info Header ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppColors.tealDark.withOpacity(0.1),
                      child: const Icon(Icons.person_rounded, color: AppColors.tealDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RÉSUMÉ DU RDV', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textGray, letterSpacing: 1)),
                          Text(
                            _selectedDate != null ? DateFormat('EEEE d MMMM HH:mm', 'fr_FR').format(_selectedDate!) : '...',
                            style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _buildSectionTitle('STATUT DU RENDEZ-VOUS'),
              const SizedBox(height: 16),
              _buildStatusSelector(),

              const SizedBox(height: 32),

              _buildSectionTitle('DATE ET HEURE'),
              const SizedBox(height: 16),
              _buildDateRow(),

              const SizedBox(height: 32),

              _buildSectionTitle('TYPE DE CONSULTATION'),
              const SizedBox(height: 16),
              _buildTypeSelector(),

              const SizedBox(height: 32),

              _buildSectionTitle('NOTES COMPLÉMENTAIRES'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ajouter une note...',
                  fillColor: AppColors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                style: GoogleFonts.inter(fontSize: 14),
              ),

              const SizedBox(height: 48),

              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 4,
                  ),
                  child: _saving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text('ENREGISTRER LES MODIFICATIONS', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 80), // Space for scrolling under FAB if needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.orangeAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.tealDark, fontSize: 11, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonFormField<StatutRDV>(
        value: _selectedStatut,
        decoration: const InputDecoration(border: InputBorder.none),
        items: StatutRDV.values.map((s) => DropdownMenuItem(
          value: s,
          child: Row(
            children: [
              _statusDot(s),
              const SizedBox(width: 12),
              Text(_statusLabel(s), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
        onChanged: (v) => v != null ? setState(() => _selectedStatut = v) : null,
      ),
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: _ActionBox(
            icon: Icons.calendar_today_rounded,
            label: _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : '...',
            onTap: _pickDate,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionBox(
            icon: Icons.access_time_rounded,
            label: _selectedDate != null ? DateFormat('HH:mm').format(_selectedDate!) : '...',
            onTap: _pickTime,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: TypeVisite.values.map((t) {
          final isSelected = _selectedType == t;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedType = t),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.tealDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      switch (t) {
                        TypeVisite.cabinet => Icons.local_hospital_rounded,
                        TypeVisite.teleconsultation => Icons.videocam_rounded,
                        TypeVisite.domicile => Icons.home_rounded,
                      },
                      color: isSelected ? Colors.white : AppColors.textGray,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      switch (t) {
                        TypeVisite.cabinet => 'CABINET',
                        TypeVisite.teleconsultation => 'TÉLÉ',
                        TypeVisite.domicile => 'DOMICILE',
                      },
                      style: GoogleFonts.inter(
                        fontSize: 9, 
                        fontWeight: FontWeight.bold, 
                        color: isSelected ? Colors.white : AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusDot(StatutRDV s) {
    final color = switch (s) {
      StatutRDV.confirme => Colors.green,
      StatutRDV.annule => Colors.red,
      StatutRDV.termine => Colors.blue,
      StatutRDV.absent => Colors.orange,
    };
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }

  String _statusLabel(StatutRDV s) {
    return switch (s) {
      StatutRDV.confirme => 'Confirmé',
      StatutRDV.annule => 'Annulé',
      StatutRDV.termine => 'Terminé',
      StatutRDV.absent => 'Absent',
    };
  }
}

class _ActionBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBox({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orangeAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
