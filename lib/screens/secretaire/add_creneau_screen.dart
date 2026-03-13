import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.navyDark)),
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message),
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
            clearFirst: true, // Mandatory overwrite
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
      appBar: AppBar(title: const Text('Gestion Journalière')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('1. CHOIX DE LA DATE'),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 32),

            _buildSectionTitle('2. OUTILS RAPIDES'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _clearDay,
              icon: const Icon(Icons.event_busy, color: Colors.red),
              label: const Text('VIDER CETTE JOURNÉE (CONGÉ / IMPRÉVU)', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSectionTitle('3. GÉNÉRER UN NOUVEAU PLANNING'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.navyDark, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'La génération écrasera automatiquement les anciens créneaux de cette journée.',
                      style: TextStyle(fontSize: 12, color: AppColors.navyDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._intervalles.asMap().entries.map((entry) => _buildIntervalRow(entry.key, entry.value)),
            TextButton.icon(
              onPressed: _addInterval,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('AJOUTER UNE PLAGE HORAIRE'),
              style: TextButton.styleFrom(foregroundColor: AppColors.navyDark),
            ),
            const SizedBox(height: 24),
            _buildDurationDropdown(),
            
            const SizedBox(height: 48),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyDark, foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GÉNÉRER ET ÉCRASER LE PLANNING'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyDark, fontSize: 12, letterSpacing: 1.2));
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 1)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.navyDark.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.navyDark),
            const SizedBox(width: 12),
            Text(_selectedDate == null ? 'Choisir la date...' : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!),
                style: TextStyle(fontSize: 16, color: _selectedDate == null ? Colors.grey : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalRow(int index, TemplateInterval interval) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: _buildTimeBox(interval.heureDebut, () => _pickTime(index, true))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('à', style: TextStyle(color: Colors.grey))),
          Expanded(child: _buildTimeBox(interval.heureFin, () => _pickTime(index, false))),
          if (_intervalles.length > 1)
            IconButton(onPressed: () => _removeInterval(index), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.lightBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(time, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyDark)),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _dureeMinutes,
      decoration: const InputDecoration(labelText: 'Durée par consultation', border: OutlineInputBorder()),
      items: [15, 20, 30, 45, 60].map((m) => DropdownMenuItem(value: m, child: Text('$m minutes'))).toList(),
      onChanged: (v) => v != null ? setState(() => _dureeMinutes = v) : null,
    );
  }
}
