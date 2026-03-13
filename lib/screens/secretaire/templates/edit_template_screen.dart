import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.tealDark, onPrimary: Colors.white),
        ),
        child: child!,
      ),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.template != null;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier le modèle' : 'Nouveau modèle', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.tealDark,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionTitle('NOM DU MODÈLE'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Ex: Matin, Journée complète...',
                fillColor: AppColors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.style_rounded, color: AppColors.orangeAccent),
              ),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('INTERVALLES HORAIRES'),
                TextButton.icon(
                  onPressed: _addInterval,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('AJOUTER'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.tealDark,
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_intervalles.length, (index) {
              final interval = _intervalles[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTimeBox(interval.heureDebut, () => _selectTime(index, true))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('À', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: _buildTimeBox(interval.heureFin, () => _selectTime(index, false))),
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
            }),
            const SizedBox(height: 48),
            SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orangeAccent,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: AppColors.orangeAccent.withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('ENREGISTRER LE MODÈLE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
              ),
            ),
          ],
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
}
