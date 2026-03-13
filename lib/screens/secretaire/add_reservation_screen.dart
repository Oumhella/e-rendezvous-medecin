import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../services/secretaire_service.dart';
import '../../theme/app_theme.dart';
import '../../models/creneau_horaire.dart';

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

  late String _medecinId;
  bool _initialized = false;
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
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedCreneau = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une date')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final patientId = await _service.findOrCreatePatient(
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        telephone: _telephoneCtrl.text.trim(),
        cin: _cinCtrl.text.trim(),
      );

      DateTime dateHeure = _selectedDate!;
      if (_selectedCreneau != null) {
        final parts = _selectedCreneau!.split(':');
        dateHeure = DateTime(dateHeure.year, dateHeure.month, dateHeure.day, int.parse(parts[0]), int.parse(parts[1]));
      }

      final rdv = RendezVous(
        id: '',
        dateHeure: dateHeure,
        typeVisite: _selectedType,
        statut: StatutRDV.confirme,
        notes: _notesCtrl.text.trim(),
        medecinId: _medecinId,
        patientId: patientId,
        patientNom: _nomCtrl.text.trim(),
        patientPrenom: _prenomCtrl.text.trim(),
      );

      await _service.addRendezVous(rdv, creneauHeureDebut: _selectedCreneau);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rendez-vous ajouté ✓'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          CustomPaint(
            painter: DottedBackgroundPainter(),
            child: Container(),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textBlack),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'Nouveau rendez-vous',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Stylized Search / Patient ID ---
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: TextField(
                          onChanged: (v) => _cinCtrl.text = v,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un patient...',
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textGray),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {}, // For demo/visual logic
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Nouveau patient'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.orangeAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // --- Form Part ---
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SectionHeader(title: 'Informations'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _StyledField(
                                    controller: _nomCtrl,
                                    label: 'Nom',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _StyledField(
                                    controller: _prenomCtrl,
                                    label: 'Prénom',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _StyledField(
                              controller: _telephoneCtrl,
                              label: 'Téléphone',
                              icon: Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                            ),
                            
                            const SizedBox(height: 32),
                            _SectionHeader(title: 'Date & Heure'),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: AppColors.beigeGray.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: AppColors.orangeAccent, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDate == null ? 'Choisir une date' : DateFormat('EEEE d MMMM yyyy', 'fr').format(_selectedDate!),
                                      style: TextStyle(
                                        color: _selectedDate == null ? AppColors.textGray : AppColors.textBlack,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            if (_selectedDate != null) ...[
                              const SizedBox(height: 16),
                              _CreneauxSelector(
                                service: _service,
                                medecinId: _medecinId,
                                date: _selectedDate!,
                                selected: _selectedCreneau,
                                onSelected: (v) => setState(() => _selectedCreneau = v),
                              ),
                            ],
                            
                            const SizedBox(height: 32),
                            _SectionHeader(title: 'Type de consultation'),
                            const SizedBox(height: 16),
                            _buildTypeSelector(),
                            
                            const SizedBox(height: 48),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.tealDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                child: _saving 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Confirmer le rendez-vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _TypeOption(
          label: 'Cabinet',
          icon: Icons.local_hospital_rounded,
          isSelected: _selectedType == TypeVisite.cabinet,
          onTap: () => setState(() => _selectedType = TypeVisite.cabinet),
        ),
        const SizedBox(width: 12),
        _TypeOption(
          label: 'Vidéo',
          icon: Icons.videocam_rounded,
          isSelected: _selectedType == TypeVisite.teleconsultation,
          onTap: () => setState(() => _selectedType = TypeVisite.teleconsultation),
        ),
      ],
    );
  }
}

class DottedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textGray.withOpacity(0.1)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    double spacing = 30;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.tealDark,
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;

  const _StyledField({
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.orangeAccent : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.transparent : AppColors.beigeGray),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.tealMedium, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_toggle_off_rounded, color: AppColors.tealMedium, size: 18),
            const SizedBox(width: 8),
            Text(
              'Créneaux disponibles',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.tealMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<CreneauHoraire>>(
          future: service.getCreneauxDisponibles(medecinId, date),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orangeAccent)),
              );
            }
            
            if (snapshot.hasError) {
              return Text(
                'Erreur lors du chargement des créneaux: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              );
            }
            
            final creneaux = snapshot.data ?? [];
            if (creneaux.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orangeAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.orangeAccent.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: AppColors.orangeAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aucun créneau disponible pour cette date dans votre planning.',
                        style: TextStyle(color: AppColors.tealDark, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: creneaux.map((c) {
                final isSelected = selected == c.heureDebut;
                return GestureDetector(
                  onTap: () => onSelected(c.heureDebut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.tealDark : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.tealDark : AppColors.beigeGray.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: AppColors.tealDark.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Text(
                      c.heureDebut,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
