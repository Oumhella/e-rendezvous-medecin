import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/secretaire_service.dart';
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
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  int _dureeMinutes = 30; // default 30 mins
  bool _isLoading = false;

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

  void _submit() async {
    if (_selectedDate == null || _heureDebut == null || _heureFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final startMin = _heureDebut!.hour * 60 + _heureDebut!.minute;
    final endMin = _heureFin!.hour * 60 + _heureFin!.minute;

    if (startMin >= endMin) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'heure de fin doit être après l\'heure de début.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _service.batchCreateCreneaux(
        medecinId: _medecinId!,
        dateJour: _selectedDate!,
        heureDebut: _heureDebut!,
        heureFin: _heureFin!,
        dureeMinutes: _dureeMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Créneaux générés avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyDark,
              onPrimary: Colors.white,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart 
        ? const TimeOfDay(hour: 8, minute: 0)
        : const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isStart) {
        setState(() => _heureDebut = picked);
      } else {
        setState(() => _heureFin = picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_medecinId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Générer Créneaux'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Créez rapidement plusieurs créneaux horaires en définissant une période et la durée de consultation.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Date
            _buildPickerField(
              label: 'Date',
              value: _selectedDate == null 
                  ? 'Choisir une date' 
                  : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!),
              icon: Icons.calendar_today,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            // Heure de début
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    label: 'De',
                    value: _heureDebut == null ? 'HH:MM' : _heureDebut!.format(context),
                    icon: Icons.access_time,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerField(
                    label: 'À',
                    value: _heureFin == null ? 'HH:MM' : _heureFin!.format(context),
                    icon: Icons.access_time,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Durée dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Durée par consultation (minutes)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyDark),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _dureeMinutes,
                  decoration: const InputDecoration(),
                  items: [15, 20, 30, 45, 60].map((mins) {
                    return DropdownMenuItem<int>(
                      value: mins,
                      child: Text('$mins min'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _dureeMinutes = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 48),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Générer Créneaux',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyDark),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.navyDark.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.navyDark, size: 20),
                const SizedBox(width: 12),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
