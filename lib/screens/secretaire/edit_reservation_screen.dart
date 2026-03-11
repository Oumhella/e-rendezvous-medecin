import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../services/secretaire_service.dart';
import '../../theme/app_theme.dart';

/// Screen to view and edit an existing appointment.
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.navyDark,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Preserve the original time
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous mis à jour ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce rendez-vous ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteRendezVous(_rdv.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rendez-vous supprimé'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier Rendez-vous'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Supprimer',
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Current Info Banner ──────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Informations actuelles',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Médecin ID: ${_rdv.medecinId}',
                      style: const TextStyle(color: AppColors.white, fontSize: 13),
                    ),
                    Text(
                      'Patient ID: ${_rdv.patientId}',
                      style: const TextStyle(color: AppColors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Status ──────────────────────────────
              _SectionTitle(icon: Icons.flag_rounded, title: 'Statut'),
              const SizedBox(height: 10),
              DropdownButtonFormField<StatutRDV>(
                initialValue: _selectedStatut,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.pending_actions_rounded),
                ),
                items: StatutRDV.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        _statusDot(s),
                        const SizedBox(width: 10),
                        Text(_statusLabel(s)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedStatut = v);
                },
              ),

              const SizedBox(height: 24),

              // ── Date & Time ─────────────────────────
              _SectionTitle(
                  icon: Icons.calendar_today_rounded,
                  title: 'Date & Heure'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.date_range_rounded),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(_selectedDate!)
                              : '--/--/----',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          prefixIcon: Icon(Icons.access_time_rounded),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('HH:mm').format(_selectedDate!)
                              : '--:--',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Type de visite ──────────────────────
              _SectionTitle(
                  icon: Icons.category_rounded,
                  title: 'Type de visite'),
              const SizedBox(height: 10),
              SegmentedButton<TypeVisite>(
                segments: const [
                  ButtonSegment(
                    value: TypeVisite.cabinet,
                    label: Text('Cabinet'),
                    icon: Icon(Icons.local_hospital_rounded),
                  ),
                  ButtonSegment(
                    value: TypeVisite.teleconsultation,
                    label: Text('Télé'),
                    icon: Icon(Icons.videocam_rounded),
                  ),
                  ButtonSegment(
                    value: TypeVisite.domicile,
                    label: Text('Domicile'),
                    icon: Icon(Icons.home_rounded),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (s) =>
                    setState(() => _selectedType = s.first),
                style: ButtonStyle(
                  backgroundColor:
                      WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.navyDark;
                    }
                    return AppColors.white;
                  }),
                  foregroundColor:
                      WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.white;
                    }
                    return AppColors.navyDark;
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // ── Notes ───────────────────────────────
              _SectionTitle(
                  icon: Icons.note_alt_outlined, title: 'Notes'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notes supplémentaires',
                ),
              ),

              const SizedBox(height: 36),

              // ── Actions ─────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Enregistrer les modifications'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusDot(StatutRDV s) {
    final color = switch (s) {
      StatutRDV.confirme => Colors.green,
      StatutRDV.annule => Colors.red,
      StatutRDV.termine => Colors.grey,
      StatutRDV.absent => Colors.deepOrange,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.navyDark),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
