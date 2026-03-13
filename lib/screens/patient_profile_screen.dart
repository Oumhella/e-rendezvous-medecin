import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import 'patient_appointments_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  late TabController _tabController;
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingInfo = false;
  bool _isSavingPw = false;
  bool _isUploadingPhoto = false;

  String? _photoUrl;
  String _email = '';
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _email = user.email ?? '';
      _photoUrl = user.photoURL;
    });

    try {
      final docSnap = await _db.collection('utilisateur').doc(user.uid).get();
      if (docSnap.exists) {
        final data = docSnap.data()!;
        _userId = docSnap.id;
        setState(() {
          _nomController.text = data['nom'] ?? '';
          _prenomController.text = data['prenom'] ?? '';
          _telephoneController.text = data['telephone'] ?? '';
          _adresseController.text = data['adresse'] ?? '';
        });
      } else {
        final query = await _db
            .collection('utilisateur')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          final doc = query.docs.first;
          final data = doc.data();
          _userId = doc.id;
          setState(() {
            _nomController.text = data['nom'] ?? '';
            _prenomController.text = data['prenom'] ?? '';
            _telephoneController.text = data['telephone'] ?? '';
            _adresseController.text = data['adresse'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    final urlController = TextEditingController(text: _photoUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Photo de profil'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'Entrez l\'URL de votre photo',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, urlController.text.trim()),
            child: const Text('Appliquer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _isUploadingPhoto = true);
      try {
        final user = _auth.currentUser!;
        await user.updatePhotoURL(result);
        setState(() => _photoUrl = result);
        _showSuccess('Photo de profil mise à jour !');
      } catch (e) {
        _showError('Erreur : $e');
      } finally {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _saveInfo() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSavingInfo = true);
    try {
      final displayName = '${_prenomController.text.trim()} ${_nomController.text.trim()}';
      await user.updateDisplayName(displayName.trim());
      final docId = _userId ?? user.uid;
      await _db.collection('utilisateur').doc(docId).set({
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'email': _email,
      }, SetOptions(merge: true));
      if (_userId == null) _userId = docId;
      _showSuccess('Profil mis à jour !');
    } catch (e) {
      _showError('Erreur : $e');
    } finally {
      setState(() => _isSavingInfo = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPwController.text != _confirmPwController.text) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }
    setState(() => _isSavingPw = true);
    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(email: user.email!, password: _currentPwController.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPwController.text);
      _currentPwController.clear(); _newPwController.clear(); _confirmPwController.clear();
      _showSuccess('Mot de passe changé !');
    } catch (e) {
      _showError('Erreur : $e');
    } finally {
      setState(() => _isSavingPw = false);
    }
  }
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.tealDark, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      bottomNavigationBar: _buildBottomNavigation(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.tealDark))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildProfileHeader()),
                SliverFillRemaining(
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInfoTab(),
                            _buildPasswordTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _auth.currentUser?.displayName ?? '${_prenomController.text} ${_nomController.text}'.trim();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.tealDark,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const Text('Mon Profil', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Serif')),
                  IconButton(icon: const Icon(Icons.logout, color: Colors.white70), onPressed: _logout, tooltip: 'Déconnexion'),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), color: AppColors.cream),
                    child: _isUploadingPhoto
                        ? const Center(child: CircularProgressIndicator(color: AppColors.tealDark))
                        : ClipOval(child: _photoUrl != null ? Image.network(_photoUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => _avatarFallback(displayName)) : _avatarFallback(displayName)),
                  ),
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppColors.orangeAccent, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 16, color: Colors.black)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(displayName.isNotEmpty ? displayName : 'Mon Compte', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen())),
                icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.orangeAccent),
                label: const Text('Mes rendez-vous', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.orangeAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initials = name.isNotEmpty ? name.trim().split(' ').map((w) => w[0]).take(2).join() : '?';
    return Center(child: Text(initials.toUpperCase(), style: const TextStyle(color: AppColors.tealDark, fontSize: 36, fontWeight: FontWeight.bold)));
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.transparent,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.tealDark, unselectedLabelColor: AppColors.textGray,
        indicatorColor: AppColors.orangeAccent, indicatorWeight: 3, dividerColor: Colors.transparent,
        tabs: const [Tab(text: 'Informations'), Tab(text: 'Mot de passe')],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: 'Détails personnels', icon: Icons.person_outline,
            children: [
              _buildField(_prenomController, 'Prénom', Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildField(_nomController, 'Nom', Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildField(_telephoneController, 'Téléphone', Icons.phone_outlined, kbType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(_adresseController, 'Adresse', Icons.location_on_outlined),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionButton(_isSavingInfo ? null : _saveInfo, 'Enregistrer les modifications', _isSavingInfo),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: 'Sécurité', icon: Icons.lock_outline,
            children: [
              _buildPasswordField(_currentPwController, 'Mot de passe actuel', _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
              const SizedBox(height: 16),
              _buildPasswordField(_newPwController, 'Nouveau mot de passe', _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 16),
              _buildPasswordField(_confirmPwController, 'Confirmer le mot de passe', _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            ],
          ),
          const SizedBox(height: 32),
          _buildActionButton(_isSavingPw ? null : _changePassword, 'Changer le mot de passe', _isSavingPw),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.orangeAccent, size: 20), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tealDark))]),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType kbType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl, keyboardType: kbType,
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.tealDark.withOpacity(0.3)),
        filled: true, fillColor: AppColors.offWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.tealDark, width: 1.5)),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController ctrl, String label, bool obscure, VoidCallback onToggle) {
    return TextFormField(
      controller: ctrl, obscureText: obscure,
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.tealDark),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, size: 20, color: AppColors.textGray), onPressed: onToggle),
        filled: true, fillColor: AppColors.offWhite,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.tealDark, width: 1.5)),
      ),
    );
  }

  Widget _buildActionButton(VoidCallback? onPressed, String label, bool loading) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
        child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2)) : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Accueil', false, () => Navigator.of(context).popUntil((route) => route.isFirst)),
            _buildNavItem(Icons.search, 'Recherche', false, () => Navigator.of(context).popUntil((route) => route.isFirst)),
            _buildCentralNavItem(),
            _buildNavItem(Icons.calendar_today_outlined, 'Mes RDV', false, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientAppointmentsScreen()));
            }),
            _buildNavItem(Icons.person, 'Profil', true, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralNavItem() {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.orangeAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.tealDark : AppColors.inactiveGray,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.tealDark : AppColors.inactiveGray,
            ),
          ),
        ],
      ),
    );
  }
}
