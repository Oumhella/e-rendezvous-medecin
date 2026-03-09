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
  String _currentLocation = 'France';

  Map<String, String> _filters = {};
  String _selectedHeaderTab = 'nos_medecins';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ─── Couleurs inspirées CliniQ ───────────────────────────────────────────
  static const Color _bg        = Color(0xFFF0F4F8);
  static const Color _white     = Colors.white;
  static const Color _navy      = Color(0xFF1A2B4A);
  static const Color _blue      = Color(0xFF4A90D9);
  static const Color _blueLight = Color(0xFFE8F1FB);
  static const Color _accent    = Color(0xFF2DD4BF); // teal accent
  static const Color _textSub   = Color(0xFF8A9BB0);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadDoctors();
    _searchController.addListener(_onSearchChanged);
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _slideController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await DoctorService.getDoctors();
      setState(() { _doctors = doctors; _filteredDoctors = doctors; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() => _applyFilters();

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
        noteMin: _filters['noteMin'] != null ? double.tryParse(_filters['noteMin']!) : null,
      );
      setState(() { _filteredDoctors = filtered; _isLoading = false; });
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
          setState(() => _filters = newFilters);
          _applyFilters();
        },
      ),
    );
  }

  void _onDoctorTapped(Doctor doctor) {
    Navigator.push(context, MaterialPageRoute(
        builder: (context) => DoctorDetailsScreen(doctor: doctor)));
  }

  void _onAppointmentRequested(Doctor doctor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(context: context, builder: (_) => common.LoginPromptDialog());
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
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadDoctors,
                color: _navy,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyDark,
            AppColors.navyDark.withOpacity(0.95),
            AppColors.lightBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo et navigation
          Row(
            children: [
              // Logo
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.lightBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const ClipOval(
                  child: Image(
                    image: AssetImage('assets/images/logo.png'),
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                  children: [
                    const TextSpan(text: 'E-', style: TextStyle(color: Colors.white)),
                    TextSpan(
                      text: 'RDV',
                      style: TextStyle(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Colors.white, AppColors.lightBlue],
                          ).createShader(const Rect.fromLTWH(0, 0, 80, 30)),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snap) {
                  final user = snap.data;
                  if (user == null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: AppColors.lightBlue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.login_rounded, color: AppColors.navyDark, size: 18),
                          SizedBox(width: 8),
                          Text('Connexion', style: TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  return Row(
                    children: [
                      _iconBtn(Icons.notifications_outlined, () {}, badge: true),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppColors.lightBlue, Colors.white]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AppColors.lightBlue.withOpacity(0.3), blurRadius: 8)],
                          ),
                          child: const Icon(Icons.person_rounded, color: AppColors.navyDark, size: 22),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Hero headline
          const Text(
            'Votre santé,\nnotre priorité',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Prenez rendez-vous avec les meilleurs médecins',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          // Search bar
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), 
                  blurRadius: 32, 
                  spreadRadius: 2,
                  offset: const Offset(0, 12)
                )
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(Icons.search_rounded, color: AppColors.lightBlue, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 18, color: AppColors.navyDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un médecin, spécialité...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w400),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.lightBlue, AppColors.navyDark]
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightBlue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          // Location chip + active filters
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _locChip(),
                ..._filters.entries.map((e) => _filterChip(e.key, e.value)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Tab row
          _buildTabRow(),
        ],
      ),
    );
  }

  // ─── TAB ROW ──────────────────────────────────────────────────────────────
  Widget _buildTabRow() {
    final tabs = [
      {'id': 'nos_medecins', 'label': 'Médecins',    'icon': Icons.people_outline},
      {'id': 'carte',        'label': 'Carte',        'icon': Icons.map_outlined},
      {'id': 'specialites',  'label': 'Spécialités',  'icon': Icons.category_outlined},
    ];
    return Row(
      children: tabs.map((t) {
        final active = _selectedHeaderTab == t['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedHeaderTab = t['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: active ? _navy : _white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: active ? [
                  BoxShadow(color: _navy.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 4)),
                ] : [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t['icon'] as IconData, size: 18,
                      color: active ? _white : _textSub),
                  const SizedBox(height: 4),
                  Text(
                    t['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? _white : _textSub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── BODY ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading && _filteredDoctors.isEmpty) return _buildSkeleton();
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (_selectedHeaderTab == 'nos_medecins') _buildDoctorsContent(),
          if (_selectedHeaderTab == 'carte')        _buildMapSection(),
          if (_selectedHeaderTab == 'specialites')  _buildSpecialitiesSection(),
          const SizedBox(height: 20),
          _buildHowItWorks(),
          const SizedBox(height: 24),
          _buildFeaturedDoctors(),
          const SizedBox(height: 100),
          _buildFooter(),
        ],
      ),
    );
  }

  // ─── FOOTER ──────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navyDark,
            AppColors.navyDark.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        children: [
          // Logo et description
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ClipOval(
                  child: Image(
                    image: AssetImage('assets/images/logo.png'),
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'E-RDV',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre plateforme de rendez-vous médical en ligne',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Liens rapides
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _footerLink('Prendre RDV', () {}),
                    _footerLink('Médecins', () {}),
                    _footerLink('Spécialités', () {}),
                    _footerLink('Urgences', () {}),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'À propos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _footerLink('Qui sommes-nous', () {}),
                    _footerLink('Mentions légales', () {}),
                    _footerLink('Confidentialité', () {}),
                    _footerLink('CGU', () {}),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _footerLink('support@e-rdv.fr', () {}),
                    _footerLink('01 23 45 67 89', () {}),
                    _footerLink('FAQ', () {}),
                    _footerLink('Aide', () {}),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Réseaux sociaux
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(Icons.facebook_rounded),
              const SizedBox(width: 16),
              _socialIcon(Icons.message_rounded),
              const SizedBox(width: 16),
              _socialIcon(Icons.camera_alt_rounded),
              const SizedBox(width: 16),
              _socialIcon(Icons.link_rounded),
            ],
          ),
          const SizedBox(height: 24),
          // Copyright
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© 2024 E-RDV. Tous droits réservés',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Made with ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.favorite_rounded,
                      color: Colors.red,
                      size: 14,
                    ),
                    Text(
                      ' in France',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
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

  Widget _footerLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ─── DOCTORS ──────────────────────────────────────────────────────────────
  Widget _buildDoctorsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('${_filteredDoctors.length} médecins',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _navy)),
              const Spacer(),
              // List / Map toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
                child: Row(children: [
                  _toggleBtn(Icons.list_rounded, _isListView, () => setState(() => _isListView = true)),
                  _toggleBtn(Icons.grid_view_rounded, !_isListView, () => setState(() => _isListView = false)),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_isListView) _buildListView() else _buildCompactMap(),
      ],
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65, // Format vertical compact
            ),
            itemCount: _filteredDoctors.length,
            itemBuilder: (context, index) {
              final doctor = _filteredDoctors[index];
              return DoctorCard(
                doctor: doctor,
                onTap: () => _onDoctorTapped(doctor),
                onAppointment: () => _onAppointmentRequested(doctor),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── SPECIALITIES ─────────────────────────────────────────────────────────
  Widget _buildSpecialitiesSection() {
    final specialities = [
      {'name': 'Généraliste',       'icon': Icons.local_hospital_rounded,  'count': 45, 'color': Colors.blue},
      {'name': 'Cardiologue',       'icon': Icons.favorite_rounded,         'count': 12, 'color': Colors.red},
      {'name': 'Dermatologue',      'icon': Icons.face_retouching_natural,  'count': 18, 'color': Colors.purple},
      {'name': 'Pédiatre',          'icon': Icons.child_care_rounded,       'count': 22, 'color': Colors.orange},
      {'name': 'Gynécologue',       'icon': Icons.female_rounded,           'count': 15, 'color': Colors.pink},
      {'name': 'Ophtalmologue',     'icon': Icons.visibility_rounded,       'count': 8, 'color': Colors.teal},
      {'name': 'Psychiatre',        'icon': Icons.psychology_rounded,       'count': 10, 'color': Colors.indigo},
      {'name': 'Kinésithérapeute',  'icon': Icons.fitness_center_rounded,   'count': 25, 'color': Colors.green},
      {'name': 'Dentiste',          'icon': Icons.medical_services_rounded, 'count': 20, 'color': Colors.cyan},
      {'name': 'ORL',               'icon': Icons.hearing_rounded,          'count': 6, 'color': Colors.amber},
      {'name': 'Rhumatologue',      'icon': Icons.healing_rounded,          'count': 9, 'color': Colors.brown},
      {'name': 'Endocrinologue',    'icon': Icons.science_rounded,          'count': 7, 'color': Colors.deepPurple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header avec filtres
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Spécialités',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A2B4A),
                ),
              ),
              const Spacer(),
              // Filtres rapides
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 16, color: AppColors.navyDark),
                    const SizedBox(width: 6),
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2B4A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grille de spécialités améliorée
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 16, 
              mainAxisSpacing: 16, 
              childAspectRatio: 1.0,
            ),
            itemCount: specialities.length,
            itemBuilder: (context, i) {
              final s = specialities[i];
              final sel = _selectedSpeciality == s['name'];
              final color = s['color'] as Color;
              
              return GestureDetector(
                onTap: () => _onSpecialitySelected(s['name'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: sel ? color : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? color : color.withOpacity(0.2),
                      width: sel ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: sel ? color.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                        blurRadius: sel ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                      if (sel)
                        BoxShadow(
                          color: color.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône avec fond
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: sel ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          s['icon'] as IconData, 
                          size: 24,
                          color: sel ? Colors.white : color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Nom de spécialité
                      Text(
                        s['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : const Color(0xFF1A2B4A),
                        ),
                        textAlign: TextAlign.center, 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Nombre de médecins
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${s['count']} médecins',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Filtres actifs
        if (_selectedSpeciality.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.lightBlue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 20, color: AppColors.navyDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Filtre actif: $_selectedSpeciality',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2B4A),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _onSpecialitySelected(''),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── HOW IT WORKS ─────────────────────────────────────────────────────────
  Widget _buildHowItWorks() {
    final steps = [
      {'icon': Icons.search_rounded,       'title': 'Cherchez',  'sub': 'Spécialité ou symptôme'},
      {'icon': Icons.calendar_today_rounded,'title': 'Choisissez','sub': 'Un créneau dispo'},
      {'icon': Icons.check_circle_rounded, 'title': 'Confirmez',  'sub': 'RDV instantané'},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [_navy, Color(0xFF2A3F6A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Comment ça marche ?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _white)),
          const SizedBox(height: 16),
          Row(
            children: steps.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: _white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(s['icon'] as IconData, color: _white, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(s['title'] as String,
                              style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text(s['sub'] as String,
                              style: TextStyle(color: _white.withOpacity(0.6), fontSize: 10),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: _white.withOpacity(0.3)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── FEATURED DOCTORS (CliniQ horizontal cards) ───────────────────────────
  Widget _buildFeaturedDoctors() {
    if (_filteredDoctors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('À la une', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _navy)),
              const Spacer(),
              Text('Voir tout', style: TextStyle(fontSize: 13, color: _blue, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: _filteredDoctors.take(6).length,
            itemBuilder: (context, i) {
              final d = _filteredDoctors[i];
              return _FeaturedCard(
                doctor: d,
                onTap: () => _onDoctorTapped(d),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── MAP ──────────────────────────────────────────────────────────────────
  Widget _buildMapSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildMapView(),
    );
  }

  Widget _buildCompactMap() {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(33.5731, -7.5898), initialZoom: 12.0,
            minZoom: 3.0, maxZoom: 18.0,
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'e_rendezvous_medecin', maxZoom: 19),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _navy.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(33.5731, -7.5898), initialZoom: 13.0,
                minZoom: 3.0, maxZoom: 18.0,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'e_rendezvous_medecin', maxZoom: 19),
                MarkerLayer(markers: _buildMarkers()),
                RichAttributionWidget(attributions: [
                  TextSourceAttribution('OpenStreetMap contributors',
                      textStyle: const TextStyle(fontSize: 10, color: _textSub)),
                ]),
              ],
            ),
            // Badge count overlay
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_filteredDoctors.length} médecins',
                    style: const TextStyle(color: _white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _filteredDoctors.take(15).map((doctor) {
      LatLng pos;
      final addr = doctor.adresseCabinet.toLowerCase();
      if (addr.contains('casablanca')) pos = const LatLng(33.5731, -7.5898);
      else if (addr.contains('rabat')) pos = const LatLng(34.0209, -6.8416);
      else if (addr.contains('marrakech')) pos = const LatLng(31.6295, -7.9811);
      else pos = const LatLng(33.9716, -6.8428);
      return Marker(
        point: pos, width: 40, height: 40,
        child: GestureDetector(
          onTap: () => _onDoctorTapped(doctor),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [_blue, _accent]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_hospital_rounded, size: 20, color: _white),
          ),
        ),
      );
    }).toList();
  }

  // ─── SKELETON ─────────────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (_) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 110,
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(18),
          ),
        )),
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(children: [
            _navItem(Icons.home_rounded, 'Accueil', true, () {}),
            _navItem(Icons.search_rounded, 'Recherche', false, () {}),
            _navItem(Icons.calendar_today_rounded, 'Mes RDV', false, () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                showDialog(context: context, builder: (_) => common.LoginPromptDialog());
              } else {
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PatientAppointmentsScreen()));
              }
            }),
            _navItem(Icons.person_rounded, 'Profil', false, () {
              showDialog(context: context, builder: (_) => common.LoginPromptDialog());
            }),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS / MICRO-WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _pill({required String label, required IconData icon,
    required VoidCallback onTap, bool filled = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: filled ? const LinearGradient(colors: [_blue, _accent]) : null,
          color: filled ? null : _white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: filled ? _white : _navy),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: filled ? _white : _navy)),
        ]),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {bool badge = false}) {
    return Stack(children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
          child: Icon(icon, size: 20, color: _navy),
        ),
      ),
      if (badge)
        Positioned(right: 8, top: 8,
          child: Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
    ]);
  }

  Widget _locChip() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _blueLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.location_on_rounded, size: 14, color: _blue),
        const SizedBox(width: 5),
        Text(_currentLocation,
            style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _filterChip(String key, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_blue, _accent]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontSize: 12, color: _white, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            setState(() {
              _filters.remove(key);
              if (key == 'specialite') _selectedSpeciality = '';
            });
            _applyFilters();
          },
          child: const Icon(Icons.close_rounded, size: 13, color: _white),
        ),
      ]),
    );
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? _navy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: active ? _white : _textSub),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: active ? _navy : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: active ? _white : _textSub),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _navy : _textSub)),
        ]),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {Color color = _navy}) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DOCTOR TILE — ligne compacte style CliniQ
// ═══════════════════════════════════════════════════════════════════════════
class _DoctorTile extends StatelessWidget {
  const _DoctorTile({
    required this.doctor,
    required this.onTap,
    required this.onBook,
  });
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onBook;

  static const Color _navy      = Color(0xFF1A2B4A);
  static const Color _blue      = Color(0xFF4A90D9);
  static const Color _blueLight = Color(0xFFE8F1FB);
  static const Color _accent    = Color(0xFF2DD4BF);
  static const Color _textSub   = Color(0xFF8A9BB0);
  static const Color _white     = Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.04),
              blurRadius: 20, 
              spreadRadius: 2,
              offset: const Offset(0, 8),
            )
          ],
          border: Border.all(color: _navy.withOpacity(0.02)),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [_navy, _blue]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: _blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.person_outline_rounded, size: 36, color: _white),
              ),
              if (doctor.disponibleAujourdhui)
                Positioned(right: -2, bottom: -2,
                  child: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981), // Emerald green
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 3),
                    ),
                  )),
            ]),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dr. ${doctor.prenom} ${doctor.nom}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _navy)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _blueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(doctor.specialite,
                        style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 4),
                            Text(doctor.note.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_rounded, color: _textSub, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(doctor.adresseCabinet,
                            style: TextStyle(fontSize: 12, color: _textSub, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            Column(
              children: [
                GestureDetector(
                  onTap: onBook,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_blue, _accent]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Text('RDV',
                        style: TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(doctor.tarifText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _navy)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FEATURED CARD — horizontal card style CliniQ
// ═══════════════════════════════════════════════════════════════════════════
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.doctor, required this.onTap});
  final Doctor doctor;
  final VoidCallback onTap;

  static const Color _navy      = Color(0xFF1A2B4A);
  static const Color _blue      = Color(0xFF4A90D9);
  static const Color _blueLight = Color(0xFFE8F1FB);
  static const Color _accent    = Color(0xFF2DD4BF);
  static const Color _textSub   = Color(0xFF8A9BB0);
  static const Color _white     = Colors.white;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + statut
            Stack(children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [_navy, _blue]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: _blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.person_outline_rounded, size: 32, color: _white),
              ),
              if (doctor.disponibleAujourdhui)
                Positioned(right: -2, bottom: -2,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: _white, width: 2),
                    ),
                  )),
            ]),
            const SizedBox(height: 12),
            // Info
            Text('Dr. ${doctor.prenom}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _navy)),
            const SizedBox(height: 2),
            Text(doctor.specialite,
                style: const TextStyle(fontSize: 12, color: _textSub, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            // Rating + distance
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 2),
                Text(doctor.note.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
                const SizedBox(width: 8),
                Icon(Icons.location_on_rounded, color: _textSub, size: 14),
                const SizedBox(width: 2),
                Text(doctor.distanceText,
                    style: const TextStyle(fontSize: 11, color: _textSub, fontWeight: FontWeight.w500)),
              ],
            ),
            if (doctor.disponibleAujourdhui)
              const SizedBox(height: 8),
            if (doctor.disponibleAujourdhui)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Disponible',
                    style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }
}
