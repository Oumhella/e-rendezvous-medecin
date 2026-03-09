import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/common_widgets.dart' as common;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;
  bool _isListView = true;
  String _selectedSpeciality = '';
  String _currentLocation = 'Paris, France';
  
  Map<String, String> _filters = {};
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeApp() async {
    // D'abord initialiser les données, puis charger les médecins
    await _initializeData();
    await _loadDoctors();
  }

  Future<void> _initializeData() async {
    // Initialiser les données mockées dans Firestore si nécessaire
    await DoctorService.initializeMockData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await DoctorService.getDoctors();
      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    
    try {
      final filtered = await DoctorService.getDoctors(
        query: _searchController.text,
        specialite: _filters['specialite'],
        disponibilite: _filters['disponibilite'],
        typeConsultation: _filters['typeConsultation'],
        secteur: _filters['secteur'],
        tarifRange: _filters['tarif'],
        noteMin: _filters['noteMin'] != null 
            ? double.tryParse(_filters['noteMin']!) 
            : null,
      );
      
      setState(() {
        _filteredDoctors = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        currentFilters: _filters,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filters = newFilters;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _onDoctorTapped(Doctor doctor) {
    // Naviguer vers le profil du médecin
    showDialog(
      context: context,
      builder: (context) => common.LoginPromptDialog(),
    );
  }

  void _onAppointmentRequested(Doctor doctor) {
    showDialog(
      context: context,
      builder: (context) => common.LoginPromptDialog(),
    );
  }

  void _onSpecialitySelected(String speciality) {
    setState(() {
      _selectedSpeciality = _selectedSpeciality == speciality ? '' : speciality;
      if (_selectedSpeciality.isNotEmpty) {
        _filters['specialite'] = _selectedSpeciality;
      } else {
        _filters.remove('specialite');
      }
    });
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header fixe
            _buildHeader(),
            
            // Contenu scrollable
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDoctors,
                color: AppColors.navyDark,
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: AppColors.navyDark,
                        size: 24,
                      ),
                    );
                  },
                ),
                const Spacer(),
                // Bouton de connexion prominent
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    icon: const Icon(
                      Icons.login,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Connexion',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.navyDark,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => common.LoginPromptDialog(),
                    );
                  },
                  icon: const Icon(
                    Icons.person_outline,
                    color: AppColors.navyDark,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          common.SearchBar(
            controller: _searchController,
            onFilterTap: _showFilterBottomSheet,
            onChanged: (value) => _onSearchChanged(),
          ),
          const SizedBox(height: 8),
          common.LocationChip(
            location: _currentLocation,
            onTap: () {
              // Ouvrir le sélecteur de localisation
            },
          ),
          const SizedBox(height: 16),
          if (_filters.isNotEmpty) _buildActiveFilters(),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    if (_filters.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filterKey = _filters.keys.elementAt(index);
          final filterValue = _filters[filterKey]!;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.navyDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filterValue,
                  style: const TextStyle(
                    color: AppColors.navyDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _filters.remove(filterKey);
                      if (filterKey == 'specialite') {
                        _selectedSpeciality = '';
                      }
                    });
                    _applyFilters();
                  },
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.navyDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _filteredDoctors.isEmpty) {
      return _buildSkeletonLoader();
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle vue
              common.ViewToggle(
                isListView: _isListView,
                onChanged: (value) => setState(() => _isListView = value),
              ),
              
              const SizedBox(height: 16),
              
              if (_isListView) _buildListView() else _buildMapView(),
              
              const SizedBox(height: 24),
              
              // Spécialités populaires
              _buildPopularSpecialities(),
              
              const SizedBox(height: 24),
              
              // Comment ça marche
              _buildHowItWorks(),
              
              const SizedBox(height: 100), // Espace pour la bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                '${_filteredDoctors.length} médecins trouvés',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sort,
                      size: 16,
                      color: AppColors.navyDark,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Pertinence',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.navyDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.navyDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: _filteredDoctors.map((doctor) {
              return DoctorCard(
                doctor: doctor,
                onTap: () => _onDoctorTapped(doctor),
                onAppointment: () => _onAppointmentRequested(doctor),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Vue carte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Carte interactive en cours de développement',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSpecialities() {
    final specialities = [
      {'name': 'Généraliste', 'icon': Icons.local_hospital},
      {'name': 'Cardio', 'icon': Icons.favorite},
      {'name': 'Dermato', 'icon': Icons.face},
      {'name': 'Pédiatrie', 'icon': Icons.child_care},
      {'name': 'Gynéco', 'icon': Icons.female},
      {'name': 'Ophtalmo', 'icon': Icons.visibility},
      {'name': 'Psychiatrie', 'icon': Icons.psychology},
      {'name': 'Kiné', 'icon': Icons.fitness_center},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Spécialités populaires',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: specialities.length,
            itemBuilder: (context, index) {
              final speciality = specialities[index];
              final isSelected = _selectedSpeciality == speciality['name'];
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: common.SpecialityCard(
                  speciality: speciality['name'] as String,
                  icon: speciality['icon'] as IconData,
                  onTap: () => _onSpecialitySelected(speciality['name'] as String),
                  isSelected: isSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      {
        'step': 'Étape 1',
        'title': 'Cherchez',
        'description': 'Par spécialité ou symptôme',
        'icon': Icons.search,
      },
      {
        'step': 'Étape 2',
        'title': 'Choisissez',
        'description': 'Un créneau disponible',
        'icon': Icons.calendar_today,
      },
      {
        'step': 'Étape 3',
        'title': 'Recevez',
        'description': 'Votre confirmation',
        'icon': Icons.check_circle,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Comment ça marche',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navyDark,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return common.HowItWorksCard(
                step: step['step'] as String,
                title: step['title'] as String,
                description: step['description'] as String,
                icon: step['icon'] as IconData,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(3, (index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        )),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Accueil',
                isActive: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.search,
                label: 'Recherche',
                isActive: false,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.calendar_today,
                label: 'Mes RDV',
                isActive: false,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => common.LoginPromptDialog(),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profil',
                isActive: false,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => common.LoginPromptDialog(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.navyDark : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? AppColors.navyDark : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}