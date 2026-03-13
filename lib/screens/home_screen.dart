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

// ── Palette (inchangée) ────────────────────────────────────────────────────
class _C {
  static const cream      = Color(0xFFF5F0E8);
  static const teal       = Color(0xFF3A9E8F);
  static const tealDark   = Color(0xFF2D7A6E);
  static const orange     = Color(0xFFE8900A);
  static const cardBeige  = Color(0xFFFAEDD8);
  static const cardMint   = Color(0xFFDCEDE8);
  static const greenDot   = Color(0xFF4CAF50);
  static const greenText  = Color(0xFF3A8A5A);
  static const textDark   = Color(0xFF1A1A1A);
  static const textGrey   = Color(0xFF888888);
  static const white      = Colors.white;
  static const beigeBorder= Color(0xFFE0D0B8);
  static const iconBeige  = Color(0xFFBB9A60);
  static const chipBg     = Color(0xFFF0E8D5);
}

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
  String _selectedSpeciality = 'Tous';
  String _currentLocation = 'Casablanca, Maroc';
  Map<String, String> _filters = {};
  String _selectedTab = 'medecins'; // medecins | carte | specialites

  // animations
  late AnimationController _heroCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _heroAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _specs = [
    {'name': 'Tous',       'icon': Icons.grid_view,          'emoji': '🏥'},
    {'name': 'Cardio',     'icon': Icons.favorite,           'emoji': '❤️'},
    {'name': 'Dentiste',   'icon': Icons.medical_services,   'emoji': '🦷'},
    {'name': 'Ophtalmo',   'icon': Icons.visibility,         'emoji': '👁️'},
    {'name': 'Neuro',      'icon': Icons.psychology,         'emoji': '🧠'},
    {'name': 'Orthopédie', 'icon': Icons.accessibility_new,  'emoji': '🦴'},
    {'name': 'Pédiatre',   'icon': Icons.child_care,         'emoji': '👶'},
    {'name': 'Général',    'icon': Icons.local_hospital,     'emoji': '🩺'},
  ];

  @override
  void initState() {
    super.initState();
    _heroCtrl  = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeCtrl  = AnimationController(duration: const Duration(milliseconds: 700),  vsync: this);
    _pulseCtrl = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this)..repeat(reverse: true);
    _heroAnim  = CurvedAnimation(parent: _heroCtrl,  curve: Curves.easeOutBack);
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeIn);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _heroCtrl.forward();
    _fadeCtrl.forward();
    _loadDoctors();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadDoctors() async {
    try {
      final doctors = await DoctorService.getDoctors();
      setState(() { _doctors = doctors; _filteredDoctors = doctors; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
        noteMin: _filters['noteMin'] != null ? double.tryParse(_filters['noteMin']!) : null,
      );
      setState(() { _filteredDoctors = filtered; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _pickSpeciality(String name) {
    setState(() {
      _selectedSpeciality = name;
      if (name == 'Tous') _filters.remove('specialite');
      else _filters['specialite'] = name;
    });
    _applyFilters();
  }

  void _onDoctorTapped(Doctor d) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctor: d)));

  void _onBook(Doctor d) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) showDialog(context: context, builder: (_) => common.LoginPromptDialog());
    else _onDoctorTapped(d);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _heroCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.cream,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── SLIVER APP BAR / HERO ──────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeroSection()),

          // ── STICKY SEARCH + TABS ───────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchDelegate(
              searchController: _searchController,
              filters: _filters,
              selectedTab: _selectedTab,
              onFilterTap: _showFilters,
              onTabChanged: (t) => setState(() => _selectedTab = t),
              onFilterRemoved: (k) {
                setState(() { _filters.remove(k); if (k == 'specialite') _selectedSpeciality = 'Tous'; });
                _applyFilters();
              },
            ),
          ),

          // ── BODY ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── HERO SECTION ─────────────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.tealDark, _C.teal, _C.teal.withOpacity(0.85)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative circles background
            Positioned(top: -30, right: -40,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06)))),
            Positioned(top: 60, right: 20,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04)))),
            Positioned(bottom: 10, left: -30,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _C.orange.withOpacity(0.12)))),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: logo + auth
                  Row(children: [
                    // Logo pill
                    ScaleTransition(
                      scale: _heroAnim,
                      child: Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Image.asset('assets/images/logo.png', width: 22, height: 22,
                                errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, size: 20, color: Colors.white)),
                            const SizedBox(width: 7),
                            const Text('E-Rendez-vous',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Auth buttons
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (_, snap) {
                        if (snap.data == null) {
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/login'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _C.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Connexion',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          );
                        }
                        return Row(children: [
                          _heroIconBtn(Icons.notifications_outlined, badge: true),
                          const SizedBox(width: 8),
                          _heroProfileMenu(snap.data!),
                        ]);
                      },
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // Headline
                  ScaleTransition(
                    scale: _heroAnim,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15),
                          children: [
                            TextSpan(text: 'Votre santé,\n'),
                            TextSpan(text: 'entre '),
                            TextSpan(text: 'de bonnes\nmains',
                                style: TextStyle(color: _C.orange)),
                            TextSpan(text: ' 🩺'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Trouvez et réservez un médecin\nen quelques secondes.',
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13, height: 1.5)),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Row(children: [
                      _statPill('${_doctors.length}+', 'Médecins'),
                      const SizedBox(width: 10),
                      _statPill('8', 'Spécialités'),
                      const SizedBox(width: 10),
                      _statPill('24/7', 'Disponible'),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
      ]),
    );
  }

  Widget _heroIconBtn(IconData icon, {bool badge = false}) {
    return Stack(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
      if (badge) Positioned(right: 7, top: 7,
          child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
    ]);
  }

  Widget _heroProfileMenu(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(padding: EdgeInsets.all(9), child: Icon(Icons.person_outline, color: Colors.white, size: 19)),
        itemBuilder: (_) => [
          PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.displayName ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(user.email ?? '', style: const TextStyle(color: _C.textGrey, fontSize: 12)),
            const Divider(),
          ])),
          const PopupMenuItem(value: 'rdv', child: Row(children: [Icon(Icons.calendar_today, size: 18), SizedBox(width: 10), Text('Mes rendez-vous')])),
          const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red, size: 18), SizedBox(width: 10), Text('Déconnexion', style: TextStyle(color: Colors.red))])),
        ],
        onSelected: (v) async {
          if (v == 'logout') {
            await FirebaseAuth.instance.signOut();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnexion réussie')));
          } else if (v == 'rdv') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen()));
          }
        },
      ),
    );
  }

  // ─── BODY ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(children: [
      if (_selectedTab == 'medecins') ...[
        _buildSpecialitiesRow(),
        const SizedBox(height: 4),
        _buildDoctorsSection(),
      ] else if (_selectedTab == 'carte') ...[
        _buildMapSection(),
      ] else ...[
        _buildSpecialitiesGrid(),
      ],
      const SizedBox(height: 20),
      _buildHowItWorksStrip(),
      const SizedBox(height: 16),
      _buildAstuceSante(),
      const SizedBox(height: 12),
      _buildSignupBanner(),
      const SizedBox(height: 100),
    ]);
  }

  // ─── SPÉCIALITÉS ROW ──────────────────────────────────────────────────────
  Widget _buildSpecialitiesRow() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(children: [
          const Text('Spécialités', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.textDark)),
          const SizedBox(width: 6),
          const Text('✨'),
        ]),
      ),
      Container(margin: const EdgeInsets.only(left: 20, top: 3), height: 3, width: 44,
          decoration: BoxDecoration(color: _C.orange, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 12),
      SizedBox(
        height: 85,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _specs.length,
          itemBuilder: (_, i) {
            final sp = _specs[i];
            final sel = _selectedSpeciality == sp['name'];
            return GestureDetector(
              onTap: () => _pickSpeciality(sp['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 64,
                margin: const EdgeInsets.only(right: 10),
                child: Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: sel ? _C.teal : _C.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: sel ? _C.teal : _C.beigeBorder, width: 1.5),
                      boxShadow: sel ? [BoxShadow(color: _C.teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                    ),
                    child: Center(
                      child: Text(sp['emoji'], style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(sp['name'],
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
                          color: sel ? _C.teal : _C.textDark),
                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ─── DOCTORS SECTION ──────────────────────────────────────────────────────
  Widget _buildDoctorsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Section header with count badge
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Médecins recommandés',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.textDark)),
            Container(margin: const EdgeInsets.only(top: 3), height: 3, width: 50,
                decoration: BoxDecoration(color: _C.orange, borderRadius: BorderRadius.circular(2))),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _C.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${_filteredDoctors.length} médecins',
                style: const TextStyle(fontSize: 11, color: _C.teal, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      if (_isLoading && _filteredDoctors.isEmpty)
        _buildSkeletonGrid()
      else if (_filteredDoctors.isEmpty)
        Padding(
          padding: const EdgeInsets.all(40),
          child: Center(child: Column(children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text('Aucun médecin trouvé', style: TextStyle(color: _C.textGrey, fontWeight: FontWeight.w600)),
          ])),
        )
      else
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildTwoColGrid(),
        ),
    ]);
  }

  // ─── 2-COL GRID ──────────────────────────────────────────────────────────
  Widget _buildTwoColGrid() {
    final rows = <Widget>[];
    for (int i = 0; i < _filteredDoctors.length; i += 2) {
      final left  = _filteredDoctors[i];
      final right = i + 1 < _filteredDoctors.length ? _filteredDoctors[i + 1] : null;
      final leftMint = i % 4 == 0 || i % 4 == 3; // alternate color pattern

      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 55, child: _doctorCard(left, bg: leftMint ? _C.cardMint : _C.cardBeige, tall: true)),
          const SizedBox(width: 10),
          Expanded(flex: 45, child: right != null
              ? _doctorCard(right, bg: leftMint ? _C.cardBeige : _C.cardMint, tall: false)
              : const SizedBox()),
        ]),
      ));
    }
    return Column(children: rows);
  }

  // ─── DOCTOR CARD ─────────────────────────────────────────────────────────
  Widget _doctorCard(Doctor doctor, {required Color bg, required bool tall}) {
    final parts    = doctor.nom.trim().split(' ');
    final initials = parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : doctor.nom.isNotEmpty ? doctor.nom[0].toUpperCase() : '?';
    final rating   = doctor.note?.toStringAsFixed(1) ?? '4.5';
    final dist     = '${(0.5 + (doctor.nom.length % 5) * 0.6).toStringAsFixed(1)} km';
    final hour     = '${9 + (doctor.nom.length % 8)}h${doctor.nom.length % 2 == 0 ? "00" : "30"}';

    return GestureDetector(
      onTap: () => _onDoctorTapped(doctor),
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Color zone
          Stack(children: [
            Container(
              height: tall ? 110 : 90,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              ),
            ),
            // Green dot
            if (doctor.disponibleAujourdhui)
              Positioned(top: 10, left: 10,
                child: Container(width: 9, height: 9,
                    decoration: const BoxDecoration(color: _C.greenDot, shape: BoxShape.circle))),
            // Rating
            Positioned(top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded, size: 10, color: _C.orange),
                  const SizedBox(width: 2),
                  Text(rating, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _C.textDark)),
                ]),
              )),
            // Avatar
            Positioned.fill(child: Center(child: Container(
              width: tall ? 56 : 48, height: tall ? 56 : 48,
              decoration: BoxDecoration(
                color: _C.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(child: Text(initials,
                  style: TextStyle(fontSize: tall ? 17 : 14, fontWeight: FontWeight.w800, color: _C.teal))),
            ))),
          ]),
          // Info
          Padding(
            padding: EdgeInsets.fromLTRB(tall ? 12 : 8, 10, tall ? 12 : 8, tall ? 12 : 9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dr. ${doctor.nom}',
                  style: TextStyle(fontSize: tall ? 13 : 11, fontWeight: FontWeight.w700, color: _C.textDark),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(doctor.specialite,
                  style: TextStyle(fontSize: tall ? 11 : 10, color: _C.textGrey),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 7),
              Wrap(spacing: 5, runSpacing: 4, children: [
                _infoChip(Icons.location_on_outlined, dist),
                _infoChip(Icons.access_time_rounded, hour),
              ]),
              if (doctor.disponibleAujourdhui) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.bolt_rounded, size: 11, color: _C.greenText),
                  const SizedBox(width: 3),
                  Text('Disponible maintenant',
                      style: TextStyle(fontSize: 9.5, color: _C.greenText, fontWeight: FontWeight.w700)),
                ]),
              ],
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _onBook(doctor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.orange, foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: tall ? 10 : 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    textStyle: TextStyle(fontSize: tall ? 12 : 11, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('+ Réserver'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: _C.white.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 9, color: _C.teal),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9.5, color: _C.teal, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── HOW IT WORKS — horizontal strip ──────────────────────────────────────
  Widget _buildHowItWorksStrip() {
    final steps = [
      {'n': '01', 'title': 'Cherchez',   'desc': 'Médecin ou spécialité', 'icon': '🔍'},
      {'n': '02', 'title': 'Choisissez', 'desc': 'Créneau disponible',    'icon': '📅'},
      {'n': '03', 'title': 'Confirmez',  'desc': 'Votre rendez-vous',     'icon': '✅'},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Comment ça marche ?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.textDark)),
          Container(margin: const EdgeInsets.only(top: 3), height: 3, width: 50,
              decoration: BoxDecoration(color: _C.orange, borderRadius: BorderRadius.circular(2))),
        ]),
      ),
      const SizedBox(height: 12),
      // Horizontal connected strip
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Arrow connector
              return Expanded(child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_C.teal.withOpacity(0.3), _C.orange.withOpacity(0.3)]),
                  borderRadius: BorderRadius.circular(1),
                ),
              ));
            }
            final s = steps[i ~/ 2];
            return Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: _C.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.teal.withOpacity(0.2), width: 2),
                  boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Center(child: Text(s['icon']!, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(height: 6),
              Text(s['n']!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _C.orange)),
              Text(s['title']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _C.textDark)),
              Text(s['desc']!, style: TextStyle(fontSize: 9, color: _C.textGrey), textAlign: TextAlign.center),
            ]);
          }),
        ),
      ),
    ]);
  }

  // ─── ASTUCE SANTÉ ─────────────────────────────────────────────────────────
  Widget _buildAstuceSante() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.beigeBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: _C.orange.withOpacity(0.1), shape: BoxShape.circle),
          child: const Center(child: Text('🌙', style: TextStyle(fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Astuce santé',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _C.textDark)),
          const SizedBox(height: 3),
          Text('Dormez au moins 7h par nuit pour renforcer votre immunité',
              style: TextStyle(fontSize: 12, color: _C.textGrey, height: 1.4)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {},
            child: Row(children: [
              Text('En savoir plus', style: TextStyle(fontSize: 12, color: _C.teal, fontWeight: FontWeight.w700)),
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward_rounded, size: 13, color: _C.teal),
            ]),
          ),
        ])),
      ]),
    );
  }

  // ─── SIGNUP BANNER ────────────────────────────────────────────────────────
  Widget _buildSignupBanner() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.data != null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.tealDark, _C.teal],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Stack(children: [
            // Deco circle
            Positioned(right: -20, top: -20,
              child: Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Créez votre compte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Text("Accédez à la prise de rendez-vous,\nl'historique médical et plus encore.",
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), height: 1.5)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(color: _C.orange, borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: _C.orange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                  child: const Text("S'inscrire gratuitement →",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }

  // ─── MAP SECTION ──────────────────────────────────────────────────────────
  Widget _buildMapSection() {
    final markers = _filteredDoctors.map((doctor) => Marker(
      point: _pos(doctor), width: 44, height: 44,
      child: GestureDetector(
        onTap: () => _onDoctorTapped(doctor),
        child: Stack(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _C.teal, shape: BoxShape.circle,
              border: Border.all(color: _C.orange, width: 2),
              boxShadow: [BoxShadow(color: _C.teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Center(child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: _C.cream, shape: BoxShape.circle),
              child: const Icon(Icons.local_hospital, size: 13, color: _C.teal),
            )),
          ),
          if (doctor.disponibleAujourdhui) Positioned(right: 3, top: 3,
            child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: _C.greenDot, shape: BoxShape.circle))),
        ]),
      ),
    )).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Carte des médecins',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.textDark)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _C.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text('${_filteredDoctors.length} médecins',
                style: const TextStyle(fontSize: 11, color: _C.teal, fontWeight: FontWeight.w700)),
          ),
        ]),
        Container(margin: const EdgeInsets.only(top: 3, bottom: 14), height: 3, width: 50,
            decoration: BoxDecoration(color: _C.orange, borderRadius: BorderRadius.circular(2))),
        Container(
          height: 440,
          decoration: BoxDecoration(
            color: _C.white, borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(33.5731, -7.5898),
                initialZoom: 13.0, minZoom: 3.0, maxZoom: 18.0,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'e_rendezvous_medecin', maxZoom: 19),
                MarkerLayer(markers: markers),
                RichAttributionWidget(attributions: [
                  TextSourceAttribution('OpenStreetMap contributors',
                      textStyle: TextStyle(fontSize: 10, color: _C.textGrey)),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ─── SPECIALITIES GRID ────────────────────────────────────────────────────
  Widget _buildSpecialitiesGrid() {
    final full = [
      {'name': 'Cardio',    'emoji': '❤️',  'count': 12},
      {'name': 'Dentiste',  'emoji': '🦷',  'count': 20},
      {'name': 'Ophtalmo',  'emoji': '👁️',  'count': 8},
      {'name': 'Neuro',     'emoji': '🧠',  'count': 10},
      {'name': 'Général',   'emoji': '🩺',  'count': 45},
      {'name': 'Pédiatre',  'emoji': '👶',  'count': 22},
      {'name': 'Gynéco',    'emoji': '🌸',  'count': 15},
      {'name': 'Dermato',   'emoji': '🧬',  'count': 18},
      {'name': 'Kiné',      'emoji': '💪',  'count': 25},
      {'name': 'ORL',       'emoji': '👂',  'count': 6},
      {'name': 'Rhumato',   'emoji': '🦴',  'count': 9},
      {'name': 'Endocrino', 'emoji': '⚗️',  'count': 7},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Spécialités médicales',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _C.textDark)),
          const SizedBox(width: 6),
          const Text('✨'),
        ]),
        Container(margin: const EdgeInsets.only(top: 3, bottom: 16), height: 3, width: 50,
            decoration: BoxDecoration(color: _C.orange, borderRadius: BorderRadius.circular(2))),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.0,
          ),
          itemCount: full.length,
          itemBuilder: (_, i) {
            final sp = full[i];
            final sel = _selectedSpeciality == sp['name'];
            return GestureDetector(
              onTap: () => _pickSpeciality(sp['name'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: sel ? _C.teal : _C.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: sel ? _C.teal : _C.beigeBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(sp['emoji'] as String, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 5),
                  Text(sp['name'] as String,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : _C.textDark),
                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${sp['count']} médecins',
                      style: TextStyle(fontSize: 9, color: sel ? Colors.white.withOpacity(0.75) : _C.textGrey)),
                ]),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(flex: 55, child: Container(height: 200,
              decoration: BoxDecoration(color: _C.cardMint.withOpacity(0.5), borderRadius: BorderRadius.circular(18)))),
          const SizedBox(width: 10),
          Expanded(flex: 45, child: Container(height: 175,
              decoration: BoxDecoration(color: _C.cardBeige.withOpacity(0.5), borderRadius: BorderRadius.circular(18)))),
        ]),
      ))),
    );
  }

  LatLng _pos(Doctor d) {
    final a = d.adresseCabinet.toLowerCase();
    if (a.contains('casablanca')) return const LatLng(33.5731, -7.5898);
    if (a.contains('rabat'))      return const LatLng(34.0209, -6.8416);
    if (a.contains('marrakech'))  return const LatLng(31.6295, -7.9811);
    if (a.contains('fès'))        return const LatLng(34.0181, -5.0078);
    return const LatLng(33.9716, -6.8428);
  }

  // ─── FILTER SHEET ─────────────────────────────────────────────────────────
  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        currentFilters: _filters,
        onFiltersChanged: (f) { setState(() => _filters = f); _applyFilters(); },
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(children: [
            _navItem(Icons.home_rounded,       'Accueil',   true,  () {}),
            _navItem(Icons.search_rounded,     'Recherche', false, () {}),
            _navItem(Icons.calendar_today,     'Mes RDV',   false, () {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) showDialog(context: context, builder: (_) => common.LoginPromptDialog());
              else Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen()));
            }),
            _navItem(Icons.person_rounded,     'Profil',    false, () {
              showDialog(context: context, builder: (_) => common.LoginPromptDialog());
            }),
          ]),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: active ? _C.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: active ? Colors.white : _C.textGrey),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? _C.teal : _C.textGrey)),
        ]),
      ),
    );
  }
}

// ── STICKY SEARCH DELEGATE ─────────────────────────────────────────────────
class _StickySearchDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final Map<String, String> filters;
  final String selectedTab;
  final VoidCallback onFilterTap;
  final Function(String) onTabChanged;
  final Function(String) onFilterRemoved;

  const _StickySearchDelegate({
    required this.searchController,
    required this.filters,
    required this.selectedTab,
    required this.onFilterTap,
    required this.onTabChanged,
    required this.onFilterRemoved,
  });

  @override
  double get minExtent => 110;
  @override
  double get maxExtent => filters.isNotEmpty ? 148 : 116;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shrunk = shrinkOffset > 10;
    return Container(
      decoration: BoxDecoration(
        color: _C.cream,
        boxShadow: shrunk
            ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 3))]
            : [],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(children: [
        // Search row
        Row(children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _C.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 13, color: _C.textDark),
                decoration: InputDecoration(
                  hintText: 'Médecin, spécialité...',
                  hintStyle: TextStyle(color: _C.textGrey, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: _C.teal, size: 19),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onFilterTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: filters.isNotEmpty ? _C.orange : _C.teal,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: (filters.isNotEmpty ? _C.orange : _C.teal).withOpacity(0.35),
                    blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Stack(alignment: Alignment.center, children: [
                const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                if (filters.isNotEmpty)
                  Positioned(top: 8, right: 8,
                    child: Container(width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
              ]),
            ),
          ),
        ]),

        // Active filter chips
        if (filters.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: filters.entries.map((e) => Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _C.orange, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => onFilterRemoved(e.key),
                    child: const Icon(Icons.close_rounded, size: 11, color: Colors.white),
                  ),
                ]),
              )).toList(),
            ),
          ),
        ],
        const SizedBox(height: 8),

        // Tabs
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _C.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(children: [
            _tabBtn('medecins', Icons.people_rounded,  'Médecins',   selectedTab, onTabChanged),
            _tabBtn('carte',    Icons.map_rounded,     'Carte',      selectedTab, onTabChanged),
            _tabBtn('specialites', Icons.category_rounded, 'Spécialités', selectedTab, onTabChanged),
          ]),
        ),
      ]),
    );
  }

  Widget _tabBtn(String id, IconData icon, String label, String current, Function(String) onChange) {
    final active = current == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? _C.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: active ? Colors.white : _C.textGrey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: active ? Colors.white : _C.textGrey)),
          ]),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_StickySearchDelegate old) =>
      old.filters != filters || old.selectedTab != selectedTab;
}