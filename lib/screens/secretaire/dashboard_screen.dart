import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/secretaire_service.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';
import 'weekly_planner_screen.dart';
import 'templates/templates_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _service = SecretaireService();
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

  late String _medecinId;
  String _doctorName = '';
  bool _initialized = false;
  bool _loadingInfo = true;

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
      _loadDoctorInfo();
      _initialized = true;
    }
  }

  Future<void> _loadDoctorInfo() async {
    final info = await _service.getMedecinFullInfo(_medecinId);
    if (info != null && info['utilisateur'] != null) {
      setState(() {
        _doctorName = info['utilisateur']['nom'] ?? '';
        _loadingInfo = false;
      });
    } else {
      setState(() => _loadingInfo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: switch(_currentIndex) {
        0 => _buildDashboard(),
        1 => WeeklyPlannerScreen(medecinId: _medecinId, embedded: true),
        2 => _buildReservationsList(),
        3 => TemplatesListScreen(medecinId: _medecinId, embedded: true),
        _ => _buildDashboard(),
      },
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.orangeAccent,
          unselectedItemColor: AppColors.inactiveGray,
          backgroundColor: AppColors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Planning',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Réservations',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style_rounded),
              label: 'Modèles',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orangeAccent,
        foregroundColor: AppColors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 30),
        onPressed: () => Navigator.pushNamed(
          context,
          '/add-reservation',
          arguments: _medecinId,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // --- Header Section ---
        Stack(
          children: [
            ClipPath(
              clipper: HeaderClipper(),
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.tealDark,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 40), // spacer
                            Text(
                              'Planning — Dr. $_doctorName',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                              onPressed: _logout,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // --- Date Selector ---
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: _buildDateSelector(),
            ),
          ],
        ),

        // --- Appointments List ---
        Expanded(
          child: StreamBuilder<List<RendezVous>>(
            stream: _service.getRendezVousStream(medecinId: _medecinId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.orangeAccent));
              }
              final rdvList = snapshot.data ?? [];
              final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
              
              final filteredRdv = rdvList.where((r) => 
                r.dateHeure != null && 
                DateFormat('yyyy-MM-dd').format(r.dateHeure!) == selectedDateStr
              ).toList();

              // Sort by hour
              filteredRdv.sort((a,b) => a.dateHeure!.compareTo(b.dateHeure!));

              if (filteredRdv.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                itemCount: filteredRdv.length,
                itemBuilder: (context, i) => _AppointmentCard(rdv: filteredRdv[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 14, // Show 2 weeks
        itemBuilder: (context, i) {
          final date = DateTime.now().add(Duration(days: i));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) == 
                           DateFormat('yyyy-MM-dd').format(_selectedDate);
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              width: 65,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.orangeAccent : AppColors.white,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'fr').format(date).substring(0, 3),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available_rounded, size: 80, color: AppColors.tealMedium.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'Aucun rendez-vous prévu',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              color: AppColors.tealDark.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cette journée est apparemment libre.',
            style: TextStyle(color: AppColors.textGray.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    return Column(
      children: [
        AppBar(
          title: Text('Toutes les réservations', style: GoogleFonts.playfairDisplay()),
          backgroundColor: AppColors.tealDark,
          foregroundColor: Colors.white,
        ),
        Expanded(
          child: StreamBuilder<List<RendezVous>>(
            stream: _service.getRendezVousStream(medecinId: _medecinId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final rdvList = snapshot.data ?? [];
              if (rdvList.isEmpty) return _buildEmptyState();

              rdvList.sort((a,b) => b.dateHeure?.compareTo(a.dateHeure ?? DateTime.now()) ?? 0);

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: rdvList.length,
                itemBuilder: (context, i) => _AppointmentCard(rdv: rdvList[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Déconnexion', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Déconnexion')),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _AppointmentCard extends StatelessWidget {
  final RendezVous rdv;
  const _AppointmentCard({required this.rdv});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left Accent Border
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: AppColors.tealDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppColors.orangeAccent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          rdv.dateHeure != null ? DateFormat('HH:mm').format(rdv.dateHeure!) : '--:--',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(width: 12),
                        _Tag(
                          label: rdv.typeVisite == TypeVisite.cabinet ? 'Cabinet' : 'Télé',
                          color: AppColors.beigeGray,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rdv.nomPatient.isEmpty ? 'Patient Inconnu' : rdv.nomPatient,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _IconButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.orangeAccent.withOpacity(0.1),
                    iconColor: AppColors.orangeAccent,
                    onTap: () => Navigator.pushNamed(context, '/edit-reservation', arguments: rdv),
                  ),
                  const SizedBox(width: 8),
                  // Cancellation icon removed as requested
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.tealMedium),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
