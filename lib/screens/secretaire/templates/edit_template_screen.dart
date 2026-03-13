import 'package:flutter/material.dart';
import '../../../models/horaires_template.dart';
import '../../../services/secretaire_service.dart';
import '../../../theme/app_theme.dart';

class EditTemplateScreen extends StatefulWidget {
  final String medecinId;
  final HorairesTemplate? template;

  const EditTemplateScreen({super.key, required this.medecinId, this.template});

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen> {
  final SecretaireService _service = SecretaireService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final List<TemplateInterval> _intervalles = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _nameCtrl.text = widget.template!.nom;
      _intervalles.addAll(widget.template!.intervalles);
    } else {
      // Add a default interval
      _intervalles.add(TemplateInterval(heureDebut: '08:00', heureFin: '12:00'));
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

  Future<void> _selectTime(int index, bool isStart) async {
    final currentStr = isStart ? _intervalles[index].heureDebut : _intervalles[index].heureFin;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.navyDark),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _intervalles[index] = TemplateInterval(heureDebut: newTime, heureFin: _intervalles[index].heureFin);
        } else {
          _intervalles[index] = TemplateInterval(heureDebut: _intervalles[index].heureDebut, heureFin: newTime);
        }
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_intervalles.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final t = HorairesTemplate(
        id: widget.template?.id ?? '',
        nom: _nameCtrl.text.trim(),
        medecinId: widget.medecinId,
        intervalles: _intervalles,
      );

      if (widget.template == null) {
        await _service.addTemplate(t);
      } else {
        await _service.updateTemplate(t);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.template != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le modèle' : 'Nouveau modèle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Informations générales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du modèle (ex: Matin, Journée complète)',
                hintText: 'Entrez un nom',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Intervalles horaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addInterval,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_intervalles.length, (index) {
              final interval = _intervalles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(index, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18, color: AppColors.navyDark),
                                    const SizedBox(width: 8),
                                    Text('Début: ${interval.heureDebut}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(index, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18, color: AppColors.navyDark),
                                    const SizedBox(width: 8),
                                    Text('Fin: ${interval.heureFin}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeInterval(index),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ENREGISTRER LE MODÈLE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
