import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/doctor.dart';
import '../services/doctor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/common_widgets.dart' as common;
import 'package:firebase_auth/firebase_auth.dart';
import 'doctor_details_screen.dart';
import 'reservation_screen.dart';
import 'patient_appointments_screen.dart';

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
  String _currentLocation = 'Casablanca, Maroc';
  
  Map<String, String> _filters = {};
  String _selectedHeaderTab = 'nos_medecins';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _heroAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeApp() async {
    print('🏠 Initialisation HomeScreen...');
    await _loadDoctors();
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
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    
    _heroAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heroController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    _heroController.forward();
  }

  Future<void> _loadDoctors() async {
    try {
      print('🔄 Début chargement des médecins...');
      final doctors = await DoctorService.getDoctors();
      print('✅ Médecins chargés: ${doctors.length}');
      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
      print('✅ setState terminé, isLoading: $_isLoading');
    } catch (e) {
      print('❌ Erreur chargement médecins: $e');
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
        tarifConsultation: _filters['tarif'],
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorDetailsScreen(doctor: doctor),
      ),
    );
  }

  void _onAppointmentRequested(Doctor doctor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (context) => common.LoginPromptDialog(),
      );
    } else {
      _onDoctorTapped(doctor);
    }
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
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header Landing Page Premium
            _buildLandingHeader(),
            
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

  Widget _buildLandingHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppColors.offWhite.withOpacity(0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Hero Section avec logo zoomé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                // Logo agrandi avec animation Hero
                AnimatedBuilder(
                  animation: _heroAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 0.8 + (_heroAnimation.value * 0.4),
                      child: Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navyDark.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 45,
                            height: 45,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.local_hospital,
                                size: 35,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),
                // Titre et slogan avec animation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: const Text(
                              'E-Rendez-vous',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyDark,
                                letterSpacing: -0.5,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: Text(
                              'Votre santé, notre priorité',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Boutons d'action modernes
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    
                    if (user == null) {
                      return // Bouton connexion premium
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navyDark.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
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
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        );
                    } else {
                      return Row(
                        children: [
                          // Notifications avec badge
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: AppColors.navyDark.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.navyDark,
                                  size: 22,
                                ),
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          // Profil Menu
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.navyDark.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: PopupMenuButton<String>(
                              offset: const Offset(0, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.person_outline,
                                  color: AppColors.navyDark,
                                  size: 22,
                                ),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  enabled: false,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName ?? 'Utilisateur',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        user.email ?? '',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Divider(),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'profil',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: AppColors.navyDark, size: 20),
                                      SizedBox(width: 12),
                                      Text('Mon profil'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'rdv',
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: AppColors.navyDark, size: 20),
                                      SizedBox(width: 12),
                                      Text('Mes rendez-vous'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.red, size: 20),
                                      SizedBox(width: 12),
                                      Text('Déconnexion', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'logout') {
                                  await FirebaseAuth.instance.signOut();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Déconnexion réussie')),
                                    );
                                  }
                                } else if (value == 'profil') {
                                  // Naviguer vers profil
                                } else if (value == 'rdv') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PatientAppointmentsScreen()),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Section de recherche hero
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Barre de recherche moderne
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        AppColors.navyDark.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: AppColors.navyDark.withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withOpacity(0.1),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _onSearchChanged(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un médecin, spécialité...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.search,
                          color: AppColors.navyDark,
                          size: 26,
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: GestureDetector(
                              onTap: _showFilterBottomSheet,
                              child: const Icon(
                                Icons.tune,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Chips de localisation et filtres actifs
                Row(
                  children: [
                    // Chip de localisation premium
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.lightBlue.withOpacity(0.15),
                            AppColors.navyDark.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppColors.lightBlue.withOpacity(0.4),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightBlue.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.navyDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentLocation,
                            style: const TextStyle(
                              color: AppColors.navyDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Filtres actifs avec design moderne
                    if (_filters.isNotEmpty) ...[
                      Expanded(
                        child: SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            itemBuilder: (context, index) {
                              final filterKey = _filters.keys.elementAt(index);
                              final filterValue = _filters[filterKey]!;
                              
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.gradient,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.navyDark.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      filterValue,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
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
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Navigation Header Premium
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedHeaderTab = 'nos_medecins'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _selectedHeaderTab == 'nos_medecins' ? AppColors.gradient : null,
                          color: _selectedHeaderTab == 'nos_medecins' ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people,
                              size: 20,
                              color: _selectedHeaderTab == 'nos_medecins' ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nos Médecins',
                              style: TextStyle(
                                color: _selectedHeaderTab == 'nos_medecins' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedHeaderTab = 'carte'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _selectedHeaderTab == 'carte' ? AppColors.gradient : null,
                          color: _selectedHeaderTab == 'carte' ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map,
                              size: 20,
                              color: _selectedHeaderTab == 'carte' ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Carte',
                              style: TextStyle(
                                color: _selectedHeaderTab == 'carte' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedHeaderTab = 'specialites'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _selectedHeaderTab == 'specialites' ? AppColors.gradient : null,
                          color: _selectedHeaderTab == 'specialites' ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category,
                              size: 20,
                              color: _selectedHeaderTab == 'specialites' ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Spécialités',
                              style: TextStyle(
                                color: _selectedHeaderTab == 'specialites' ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
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
              // Contenu selon la sélection du header
              if (_selectedHeaderTab == 'nos_medecins') ...[
                _buildDoctorsSection(),
              ] else if (_selectedHeaderTab == 'carte') ...[
                _buildMapSection(),
              ] else if (_selectedHeaderTab == 'specialites') ...[
                _buildSpecialitiesSection(),
              ],
              
              const SizedBox(height: 24),
              
              // Section "Comment ça marche" (toujours visible)
              _buildHowItWorks(),
              
              const SizedBox(height: 100), // Espace pour la bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.offWhite.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nos Médecins',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                    Text(
                      '${_filteredDoctors.length} professionnels disponibles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle vue moderne
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.navyDark.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isListView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: _isListView ? AppColors.gradient : null,
                          color: _isListView ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.list,
                          size: 18,
                          color: _isListView ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isListView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: !_isListView ? AppColors.gradient : null,
                          color: !_isListView ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.map,
                          size: 18,
                          color: !_isListView ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Contenu selon la vue
        if (_isListView) _buildListView() else _buildCompactMap(),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.offWhite.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.map,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Carte des médecins',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                    Text(
                      'OpenStreetMap • ${_filteredDoctors.length} médecins',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Carte pleine largeur
        _buildMapView(),
      ],
    );
  }

  Widget _buildSpecialitiesSection() {
    final specialities = [
      {'name': 'Généraliste', 'icon': Icons.local_hospital, 'count': 45},
      {'name': 'Cardiologue', 'icon': Icons.favorite, 'count': 12},
      {'name': 'Dermatologue', 'icon': Icons.face, 'count': 18},
      {'name': 'Pédiatre', 'icon': Icons.child_care, 'count': 22},
      {'name': 'Gynécologue', 'icon': Icons.female, 'count': 15},
      {'name': 'Ophtalmologue', 'icon': Icons.visibility, 'count': 8},
      {'name': 'Psychiatre', 'icon': Icons.psychology, 'count': 10},
      {'name': 'Kinésithérapeute', 'icon': Icons.fitness_center, 'count': 25},
      {'name': 'Dentiste', 'icon': Icons.medical_services, 'count': 20},
      {'name': 'ORL', 'icon': Icons.hearing, 'count': 6},
      {'name': 'Rhumatologue', 'icon': Icons.healing, 'count': 9},
      {'name': 'Endocrinologue', 'icon': Icons.science, 'count': 7},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.offWhite.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.category,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spécialités médicales',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyDark,
                      ),
                    ),
                    Text(
                      '${specialities.length} spécialités disponibles',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Grille des spécialités
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: specialities.length,
            itemBuilder: (context, index) {
              final speciality = specialities[index];
              final isSelected = _selectedSpeciality == speciality['name'];
              
              return GestureDetector(
                onTap: () => _onSpecialitySelected(speciality['name'] as String),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.gradient : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? Colors.transparent 
                          : AppColors.navyDark.withOpacity(0.1),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.navyDark.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        speciality['icon'] as IconData,
                        size: 24,
                        color: isSelected ? Colors.white : AppColors.navyDark,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        speciality['name'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.navyDark,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${speciality['count']}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMap() {
    return Container(
      height: 300,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(33.5731, -7.5898),
            initialZoom: 12.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'e_rendezvous_medecin',
              maxZoom: 19,
            ),
            // Marqueurs simplifiés
            MarkerLayer(
              markers: _filteredDoctors.take(10).map((doctor) {
                LatLng position;
                if (doctor.adresseCabinet.toLowerCase().contains('casablanca')) {
                  position = const LatLng(33.5731, -7.5898);
                } else if (doctor.adresseCabinet.toLowerCase().contains('rabat')) {
                  position = const LatLng(34.0209, -6.8416);
                } else {
                  position = const LatLng(33.9716, -6.8428);
                }
                
                return Marker(
                  point: position,
                  width: 30,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navyDark.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.navyDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                        fontWeight: FontWeight.w600,
                      ),
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
    print('🗺️ _buildMapView appelé - médecins: ${_filteredDoctors.length}');
    
    // Convertir les médecins en marqueurs pour OpenStreetMap
    final markers = _filteredDoctors.map((doctor) {
      // Position basée sur l'adresse du médecin
      LatLng position;
      if (doctor.adresseCabinet.toLowerCase().contains('casablanca')) {
        position = const LatLng(33.5731, -7.5898); // Casablanca
      } else if (doctor.adresseCabinet.toLowerCase().contains('rabat')) {
        position = const LatLng(34.0209, -6.8416); // Rabat  
      } else if (doctor.adresseCabinet.toLowerCase().contains('marrakech')) {
        position = const LatLng(31.6295, -7.9811); // Marrakech
      } else if (doctor.adresseCabinet.toLowerCase().contains('fès')) {
        position = const LatLng(34.0181, -5.0078); // Fès
      } else {
        position = const LatLng(33.9716, -6.8428); // Position par défaut
      }
      
      return Marker(
        point: position,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _onDoctorTapped(doctor),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.navyDark, width: 2),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 18,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                if (doctor.disponibleAujourdhui)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList();
    
    return Container(
      height: 450,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.navyDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header amélioré
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  AppColors.offWhite.withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carte des médecins',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
                      ),
                      Text(
                        'OpenStreetMap • Vue en temps réel',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.navyDark.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredDoctors.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.offWhite),
          // OpenStreetMap améliorée
          Expanded(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(33.5731, -7.5898), // Casablanca par défaut
                initialZoom: 13.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                rotationThreshold: 0.5,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // OpenStreetMap tile layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'e_rendezvous_medecin',
                  maxZoom: 19,
                ),
                // Markers layer
                MarkerLayer(markers: markers),
                // Attribution
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      textStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.offWhite.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Comment ça marche',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 140,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.navyDark.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step['step'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.navyDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['description'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    showDialog(
                      context: context,
                      builder: (context) => common.LoginPromptDialog(),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientAppointmentsScreen()),
                    );
                  }
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.gradient : null,
                  color: isActive ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.navyDark : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
