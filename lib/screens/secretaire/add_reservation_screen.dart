import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../services/secretaire_service.dart';
import '../../theme/app_theme.dart';

/// Screen to add a new appointment.
/// Receives `medecinId` as a route argument (auto-linked doctor).
/// Patient info is filled manually instead of selected from a dropdown.
class AddReservationScreen extends StatefulWidget {
  const AddReservationScreen({super.key});

  @override
  State<AddReservationScreen> createState() => _AddReservationScreenState();
}

class _AddReservationScreenState extends State<AddReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SecretaireService();

  // Patient form controllers
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  final _cinCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // Auto-linked doctor
  late String _medecinId;
  bool _initialized = false;

  // Selected values
  DateTime? _selectedDate;
  String? _selectedCreneau;
  TypeVisite _selectedType = TypeVisite.cabinet;

  bool _saving = false;

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
      _medecinId = args as String;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telephoneCtrl.dispose();
    _cinCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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
      setState(() {
        _selectedDate = picked;
        _selectedCreneau = null; // reset slot when date changes
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez choisir une date pour le rendez-vous')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // 1. Find or create the patient
      final patientId = await _service.findOrCreatePatient(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        telephone: _telephoneCtrl.text.trim(),
        cin: _cinCtrl.text.trim(),
      );

      // 2. Combine date + time from selected slot
      DateTime dateHeure = _selectedDate!;
      if (_selectedCreneau != null && _selectedCreneau!.isNotEmpty) {
        final parts = _selectedCreneau!.split(':');
        dateHeure = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      // 3. Create the appointment
      final rdv = RendezVous(
        id: '',
        dateHeure: dateHeure,
        typeVisite: _selectedType,
        statut: StatutRDV.confirme,
        notes: _notesCtrl.text.trim(),
        medecinId: _medecinId, // auto-linked doctor
        patientId: patientId,
      );

      await _service.addRendezVous(
        rdv,
        creneauHeureDebut: _selectedCreneau,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous ajouté avec succès ✓'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau Rendez-vous')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Patient Info ─────────────────────────
              _SectionHeader(
                  icon: Icons.person_add_rounded,
                  title: 'Informations du patient'),
              const SizedBox(height: 10),

              // CIN
              TextFormField(
                controller: _cinCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'CIN du patient',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'Ex: BK123456',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Veuillez entrer le CIN du patient';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Nom & Prénom side by side
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nomCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requis';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _prenomCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Requis';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Téléphone
              TextFormField(
                controller: _telephoneCtrl,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: 'Ex: 0612345678',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Veuillez entrer le téléphone';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              // ── Date & Time ─────────────────────────
              _SectionHeader(
                  icon: Icons.calendar_today_rounded,
                  title: 'Date & Créneau'),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date du rendez-vous',
                    prefixIcon: Icon(Icons.date_range_rounded),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('EEEE dd MMMM yyyy', 'fr_FR')
                            .format(_selectedDate!)
                        : 'Choisir une date',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? AppColors.black
                          : AppColors.navyDark.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),

              if (_selectedDate != null) ...[
                const SizedBox(height: 14),
                _CreneauxSelector(
                  service: _service,
                  medecinId: _medecinId,
                  date: _selectedDate!,
                  selected: _selectedCreneau,
                  onSelected: (v) =>
                      setState(() => _selectedCreneau = v),
                ),
              ],

              const SizedBox(height: 28),

              // ── Type de visite ──────────────────────
              _SectionHeader(
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

              const SizedBox(height: 28),

              // ── Notes ───────────────────────────────
              _SectionHeader(
                  icon: Icons.note_alt_outlined, title: 'Notes'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notes supplémentaires (facultatif)',
                ),
              ),

              const SizedBox(height: 36),

              // ── Submit ──────────────────────────────
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
                      : const Text('Ajouter le rendez-vous'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

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

// ── Créneaux Selector ──────────────────────────────────────────────

class _CreneauxSelector extends StatelessWidget {
  final SecretaireService service;
  final String medecinId;
  final DateTime date;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _CreneauxSelector({
    required this.service,
    required this.medecinId,
    required this.date,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: service.getCreneauxDisponibles(medecinId, date),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final creneaux = snapshot.data ?? [];
        if (creneaux.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Aucun créneau disponible pour cette date',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: creneaux.map((c) {
            final isSelected = selected == c.heureDebut;
            return ChoiceChip(
              label: Text('${c.heureDebut} - ${c.heureFin}'),
              selected: isSelected,
              onSelected: (_) => onSelected(c.heureDebut),
              selectedColor: AppColors.navyDark,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
