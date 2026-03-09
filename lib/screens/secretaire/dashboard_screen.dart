import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/secretaire_service.dart';
import '../../models/rendez_vous.dart';
import '../../models/enums.dart';
import '../../theme/app_theme.dart';

/// Secretary dashboard — summary cards + quick actions.
/// Receives `medecinId` as a route argument (the doctor this secretary works for).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  final _service = SecretaireService();
  int _currentIndex = 0;

  late String _medecinId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
        // Si les arguments sont perdus (ex: refresh de la page web),
        // on redirige vers le login.
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: _currentIndex == 0 ? _buildDashboard() : _buildReservationsList(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Réservations',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau RDV'),
        onPressed: () => Navigator.pushNamed(
          context,
          '/add-reservation',
          arguments: _medecinId,
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return StreamBuilder<List<RendezVous>>(
      stream: _service.getRendezVousStream(medecinId: _medecinId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur stream: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        final rdvList = snapshot.data ?? [];

        final today = DateTime.now();
        final todayStr = DateFormat('yyyy-MM-dd').format(today);

        final todayRdv = rdvList.where((r) =>
            r.dateHeure != null &&
            DateFormat('yyyy-MM-dd').format(r.dateHeure!) == todayStr);
        final enAttente =
            rdvList.where((r) => r.statut == StatutRDV.enAttente);
        final confirmes =
            rdvList.where((r) => r.statut == StatutRDV.confirme);

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            children: [
              // ── Greeting ────────────────────────────────
              Text(
                'Bonjour 👋',
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
                label: "Aujourd'hui",
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

              // ── Quick Actions ───────────────────────────
              Text(
                'Actions rapides',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.calendar_month_rounded,
                      label: 'Voir les\nréservations',
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Ajouter un\nrendez-vous',
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/add-reservation',
                        arguments: _medecinId,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReservationsList() {
    return StreamBuilder<List<RendezVous>>(
      stream: _service.getRendezVousStream(medecinId: _medecinId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rdvList = snapshot.data ?? [];
        if (rdvList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded,
                    size: 64,
                    color: AppColors.navyDark.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('Aucun rendez-vous',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.navyDark.withValues(alpha: 0.5))),
              ],
            ),
          );
        }

        // Sort by date descending
        rdvList.sort((a, b) {
          if (a.dateHeure == null) return 1;
          if (b.dateHeure == null) return -1;
          return b.dateHeure!.compareTo(a.dateHeure!);
        });

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 100),
          itemCount: rdvList.length,
          itemBuilder: (context, i) =>
              _RendezVousCard(rdv: rdvList[i]),
        );
      },
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Déconnexion')),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────

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
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: textColor ?? color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.white, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RendezVousCard extends StatelessWidget {
  final RendezVous rdv;
  const _RendezVousCard({required this.rdv});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.pushNamed(context, '/edit-reservation', arguments: rdv),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date badge
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
                          ? DateFormat('dd').format(rdv.dateHeure!)
                          : '--',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      rdv.dateHeure != null
                          ? DateFormat('MMM').format(rdv.dateHeure!)
                          : '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rdv.dateHeure != null
                          ? DateFormat('HH:mm').format(rdv.dateHeure!)
                          : 'Heure non définie',
                      style: Theme.of(context).textTheme.titleMedium,
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
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.navyDark),
            ],
          ),
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
