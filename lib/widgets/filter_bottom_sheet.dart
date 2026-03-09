import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final Map<String, String> currentFilters;
  final Function(Map<String, String>) onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedSpecialite;
  late String _selectedDisponibilite;
  late String _selectedTypeConsultation;
  late String _selectedSecteur;
  late String _selectedTarif;
  late double _selectedNoteMin;

  final List<String> _specialites = [
    'Généraliste',
    'Cardiologue',
    'Dermatologue',
    'Pédiatre',
    'Gynécologue',
    'Ophtalmologue',
    'Psychiatre',
    'Autre',
  ];

  final List<String> _disponibilites = [
    'Aujourd\'hui',
    'Cette semaine',
    'Ce mois',
  ];

  final List<String> _typesConsultation = [
    'Présentiel',
    'Téléconsultation',
    'Les deux',
  ];

  final List<String> _secteurs = [
    'Secteur 1',
    'Secteur 2',
    'Secteur 3',
  ];

  final List<String> _tarifs = [
    '< 30€',
    '30–60€',
    '60€+',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSpecialite = widget.currentFilters['specialite'] ?? '';
    _selectedDisponibilite = widget.currentFilters['disponibilite'] ?? '';
    _selectedTypeConsultation = widget.currentFilters['typeConsultation'] ?? '';
    _selectedSecteur = widget.currentFilters['secteur'] ?? '';
    _selectedTarif = widget.currentFilters['tarif'] ?? '';
    _selectedNoteMin = widget.currentFilters['noteMin'] != null
        ? double.tryParse(widget.currentFilters['noteMin']!) ?? 0.0
        : 0.0;
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedSpecialite.isNotEmpty) count++;
    if (_selectedDisponibilite.isNotEmpty) count++;
    if (_selectedTypeConsultation.isNotEmpty) count++;
    if (_selectedSecteur.isNotEmpty) count++;
    if (_selectedTarif.isNotEmpty) count++;
    if (_selectedNoteMin > 0) count++;
    return count;
  }

  void _applyFilters() {
    final filters = <String, String>{};
    if (_selectedSpecialite.isNotEmpty) filters['specialite'] = _selectedSpecialite;
    if (_selectedDisponibilite.isNotEmpty) filters['disponibilite'] = _selectedDisponibilite;
    if (_selectedTypeConsultation.isNotEmpty) filters['typeConsultation'] = _selectedTypeConsultation;
    if (_selectedSecteur.isNotEmpty) filters['secteur'] = _selectedSecteur;
    if (_selectedTarif.isNotEmpty) filters['tarif'] = _selectedTarif;
    if (_selectedNoteMin > 0) filters['noteMin'] = _selectedNoteMin.toString();
    
    widget.onFiltersChanged(filters);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedSpecialite = '';
      _selectedDisponibilite = '';
      _selectedTypeConsultation = '';
      _selectedSecteur = '';
      _selectedTarif = '';
      _selectedNoteMin = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.offWhite, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Spécialité
                  _buildSectionTitle('Spécialité'),
                  _buildChipGrid(_specialites, _selectedSpecialite, (value) {
                    setState(() => _selectedSpecialite = value);
                  }),
                  const SizedBox(height: 24),

                  // Disponibilité
                  _buildSectionTitle('Disponibilité'),
                  _buildChipGrid(_disponibilites, _selectedDisponibilite, (value) {
                    setState(() => _selectedDisponibilite = value);
                  }),
                  const SizedBox(height: 24),

                  // Type de consultation
                  _buildSectionTitle('Type de consultation'),
                  _buildChipGrid(_typesConsultation, _selectedTypeConsultation, (value) {
                    setState(() => _selectedTypeConsultation = value);
                  }),
                  const SizedBox(height: 24),

                  // Secteur
                  _buildSectionTitle('Secteur'),
                  _buildChipGrid(_secteurs, _selectedSecteur, (value) {
                    setState(() => _selectedSecteur = value);
                  }),
                  const SizedBox(height: 24),

                  // Tarif
                  _buildSectionTitle('Tarif'),
                  _buildChipGrid(_tarifs, _selectedTarif, (value) {
                    setState(() => _selectedTarif = value);
                  }),
                  const SizedBox(height: 24),

                  // Note minimum
                  _buildSectionTitle('Note minimum'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _selectedNoteMin,
                              min: 0.0,
                              max: 5.0,
                              divisions: 10,
                              activeColor: AppColors.navyDark,
                              inactiveColor: Colors.grey[300],
                              onChanged: (value) {
                                setState(() => _selectedNoteMin = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedNoteMin > 0
                                  ? AppColors.navyDark.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _selectedNoteMin > 0
                                  ? '⭐ ${_selectedNoteMin.toStringAsFixed(1)}+'
                                  : 'Toutes',
                              style: TextStyle(
                                color: _selectedNoteMin > 0
                                    ? AppColors.navyDark
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.offWhite, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.navyDark),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Réinitialiser',
                      style: TextStyle(
                        color: AppColors.navyDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Appliquer${_getActiveFiltersCount() > 0 ? ' (${_getActiveFiltersCount()})' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.navyDark,
        ),
      ),
    );
  }

  Widget _buildChipGrid(List<String> options, String selectedValue, Function(String) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return InkWell(
          onTap: () => onTap(isSelected ? '' : option),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navyDark : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
