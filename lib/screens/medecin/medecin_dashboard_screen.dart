import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';

import '../../theme/app_theme.dart';
import 'historique_rdv_screen.dart';

/// Médecin dashboard — summary cards + today's appointments.
class MedecinDashboardScreen extends StatefulWidget {
  const MedecinDashboardScreen({super.key});

  @override
  State<MedecinDashboardScreen> createState() => _MedecinDashboardScreenState();
}

class _MedecinDashboardScreenState extends State<MedecinDashboardScreen> {
  final _authService = AuthService();
  int _currentIndex = 0;

  late String _medecinId;
  String _medecinNom = '';
  bool _initialized = false;

  // Cache des noms de patients pour éviter des requêtes répétitives
  final Map<String, String> _patientNamesCache = {};

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
      if (args is Map<String, String>) {
        _medecinId = args['medecinId'] ?? '';
        _medecinNom = args['medecinNom'] ?? '';
      } else {
        _medecinId = args as String;
      }
      _initialized = true;
    }
  }

  /// Récupère le nom complet du patient via son ID (avec cache).
  Future<String> _getPatientName(String patientId) async {
    if (_patientNamesCache.containsKey(patientId)) {
      return _patientNamesCache[patientId]!;
    }
    try {
      final patient = await DoctorService.getPatientById(patientId);
      if (patient != null && patient.utilisateurId.isNotEmpty) {
        final utilisateur = await DoctorService.getUtilisateurById(
          patient.utilisateurId,
        );
        if (utilisateur != null) {
          final nom = utilisateur.nomComplet;
          _patientNamesCache[patientId] = nom;
          return nom;
        }
      }
    } catch (_) {}
    _patientNamesCache[patientId] = 'Patient inconnu';
    return 'Patient inconnu';
  }

  Widget _buildBody() {
    if (_currentIndex == 0) return _buildDashboard();
    if (_currentIndex == 1) return _buildTodayList();
    return HistoriqueRdvScreen(
      medecinId: _medecinId,
      getPatientName: _getPatientName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Tableau de bord'
              : _currentIndex == 1
              ? 'RDV du jour'
              : 'Historique',
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.navyDark,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today_rounded),
            label: 'Aujourd\'hui',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Historique',
          ),
        ],
      ),
    );
  }

  // ── Onglet Accueil ─────────────────────────────────────────────────

  Widget _buildDashboard() {
    return StreamBuilder<List<RendezVous>>(
      stream: DoctorService.getRendezVousStream(_medecinId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rdvList = snapshot.data ?? [];
        final today = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(today);

        final todayRdv = rdvList.where(
          (r) =>
              r.dateHeure != null &&
              DateFormat('yyyy-MM-dd').format(r.dateHeure!) == todayStr,
        );
        final enAttente = rdvList.where((r) => r.statut == StatutRDV.enAttente);
        final confirmes = rdvList.where((r) => r.statut == StatutRDV.confirme);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              // ── Greeting ────────────────────────────────
              Text(
                _medecinNom.isNotEmpty
                    ? 'Bonjour Dr. $_medecinNom 👋'
                    : 'Bonjour Docteur 👋',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat.yMMMMEEEEd('fr_FR').format(today),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.navyDark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 28),

              // ── Stats Cards ─────────────────────────────
              _StatCard(
                icon: Icons.today_rounded,
                label: "RDV aujourd'hui",
                value: todayRdv.length.toString(),
                color: AppColors.navyDark,
              ),
              _StatCard(
                icon: Icons.hourglass_top_rounded,
                label: 'En attente',
                value: enAttente.length.toString(),
                color: Colors.orange.shade700,
              ),
              _StatCard(
                icon: Icons.check_circle_outline_rounded,
                label: 'Confirmés',
                value: confirmes.length.toString(),
                color: Colors.green.shade700,
              ),
              _StatCard(
                icon: Icons.event_note_rounded,
                label: 'Total rendez-vous',
                value: rdvList.length.toString(),
                color: AppColors.lightBlue,
                textColor: AppColors.navyDark,
              ),

              const SizedBox(height: 32),

              // ── Prochains RDV aujourd'hui ─────────────────
              Text(
                "Prochains rendez-vous",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),

              if (todayRdv.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 48,
                        color: AppColors.navyDark.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Aucun rendez-vous aujourd'hui",
                        style: TextStyle(
                          color: AppColors.navyDark.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...(todayRdv.toList()..sort((a, b) {
                      if (a.dateHeure == null) return 1;
                      if (b.dateHeure == null) return -1;
                      return a.dateHeure!.compareTo(b.dateHeure!);
                    }))
                    .map(
                      (rdv) => _RdvCardWithPatient(
                        rdv: rdv,
                        getPatientName: _getPatientName,
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // ── Onglet RDV du jour ─────────────────────────────────────────────

  Widget _buildTodayList() {
    return StreamBuilder<List<RendezVous>>(
      stream: DoctorService.getRendezVousStream(_medecinId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rdvList = snapshot.data ?? [];
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final todayRdv =
            rdvList
                .where(
                  (r) =>
                      r.dateHeure != null &&
                      DateFormat('yyyy-MM-dd').format(r.dateHeure!) == todayStr,
                )
                .toList()
              ..sort((a, b) {
                if (a.dateHeure == null) return 1;
                if (b.dateHeure == null) return -1;
                return a.dateHeure!.compareTo(b.dateHeure!);
              });

        if (todayRdv.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 64,
                  color: AppColors.navyDark.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "Aucun rendez-vous aujourd'hui",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.navyDark.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
          itemCount: todayRdv.length,
          itemBuilder: (context, i) => _RdvCardWithPatient(
            rdv: todayRdv[i],
            getPatientName: _getPatientName,
          ),
        );
      },
    );
  }

  // ── Déconnexion ────────────────────────────────────────────────────

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? textColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: textColor ?? color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte RDV avec résolution asynchrone du nom patient.
class _RdvCardWithPatient extends StatelessWidget {
  final RendezVous rdv;
  final Future<String> Function(String) getPatientName;

  const _RdvCardWithPatient({required this.rdv, required this.getPatientName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time badge
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.navyDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    rdv.dateHeure != null
                        ? DateFormat('HH:mm').format(rdv.dateHeure!)
                        : '--:--',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Patient + type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<String>(
                    future: getPatientName(rdv.patientId),
                    builder: (context, snap) {
                      return Text(
                        snap.data ?? '...',
                        style: Theme.of(context).textTheme.titleMedium,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _typeLabel(rdv.typeVisite),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.navyDark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Status chip
            _StatusChip(statut: rdv.statut),
          ],
        ),
      ),
    );
  }

  String _typeLabel(TypeVisite type) {
    switch (type) {
      case TypeVisite.cabinet:
        return '🏥 Cabinet';
      case TypeVisite.teleconsultation:
        return '💻 Téléconsultation';
      case TypeVisite.domicile:
        return '🏠 Domicile';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final StatutRDV statut;
  const _StatusChip({required this.statut});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (statut) {
      StatutRDV.enAttente => ('En attente', Colors.orange),
      StatutRDV.confirme => ('Confirmé', Colors.green),
      StatutRDV.annule => ('Annulé', Colors.red),
      StatutRDV.termine => ('Terminé', Colors.grey),
      StatutRDV.absent => ('Absent', Colors.deepOrange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
