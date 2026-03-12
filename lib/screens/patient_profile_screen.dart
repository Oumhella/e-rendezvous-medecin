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
  String? _userId; // utilisateur doc id in Firestore

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

    // Try to fetch extra info from Firestore 'utilisateur' collection
    try {
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
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    // Demande une URL de photo
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, urlController.text.trim()),
            child: const Text('Appliquer',
                style: TextStyle(color: Colors.white)),
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
        _showError('Impossible de mettre à jour la photo : $e');
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
      // Update display name in Firebase Auth
      final displayName =
          '${_prenomController.text.trim()} ${_nomController.text.trim()}';
      await user.updateDisplayName(displayName);

      // Update in Firestore if we have the document id
      if (_userId != null) {
        await _db.collection('utilisateur').doc(_userId).update({
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'adresse': _adresseController.text.trim(),
        });
      } else {
        // Try to create/upsert
        await _db.collection('utilisateur').add({
          'email': _email,
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'telephone': _telephoneController.text.trim(),
          'adresse': _adresseController.text.trim(),
          'role': 'patient',
        });
      }
      _showSuccess('Informations mises à jour !');
    } catch (e) {
      _showError('Erreur lors de la mise à jour : $e');
    } finally {
      setState(() => _isSavingInfo = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPwController.text != _confirmPwController.text) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }
    if (_newPwController.text.length < 6) {
      _showError('Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }

    setState(() => _isSavingPw = true);
    try {
      final user = _auth.currentUser!;
      // Re-authenticate first
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPwController.text,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPwController.text);
      _currentPwController.clear();
      _newPwController.clear();
      _confirmPwController.clear();
      _showSuccess('Mot de passe modifié avec succès !');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showError('Mot de passe actuel incorrect.');
      } else {
        _showError('Erreur : ${e.message}');
      }
    } catch (e) {
      _showError('Erreur inattendue : $e');
    } finally {
      setState(() => _isSavingPw = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: _buildProfileHeader()),
              ],
              body: Column(
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
    );
  }

  Widget _buildProfileHeader() {
    final user = _auth.currentUser;
    final displayName = user?.displayName ??
        '${_prenomController.text} ${_nomController.text}'.trim();

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              // App bar row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Mon Profil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white70),
                    onPressed: _logout,
                    tooltip: 'Déconnexion',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: _isUploadingPhoto
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white))
                        : ClipOval(
                            child: _photoUrl != null
                                ? Image.network(
                                    _photoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _avatarFallback(displayName),
                                  )
                                : _avatarFallback(displayName),
                          ),
                  ),
                  GestureDetector(
                    onTap: _pickAndUploadPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: AppColors.navyDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                displayName.isNotEmpty ? displayName : 'Mon compte',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Quick action: Mes RDV
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientAppointmentsScreen(),
                  ),
                ),
                icon: const Icon(Icons.calendar_today,
                    size: 16, color: Colors.white),
                label: const Text('Mes rendez-vous',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';
    return Container(
      color: AppColors.navyDark.withOpacity(0.4),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.navyDark,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.navyDark,
        indicatorWeight: 3,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: 'Informations'),
          Tab(text: 'Mot de passe'),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCard(
            title: 'Informations personnelles',
            icon: Icons.person_outline,
            children: [
              _buildField(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.badge_outlined),
              const SizedBox(height: 16),
              _buildField(
                controller: TextEditingController(text: _email),
                label: 'Email',
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 16),
              _buildField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField(
                  controller: _adresseController,
                  label: 'Adresse',
                  icon: Icons.location_on_outlined),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSavingInfo ? null : _saveInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSavingInfo
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Enregistrer les modifications',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
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
            title: 'Changer le mot de passe',
            icon: Icons.lock_outline,
            children: [
              _buildPasswordField(
                controller: _currentPwController,
                label: 'Mot de passe actuel',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPwController,
                label: 'Nouveau mot de passe',
                obscure: _obscureNew,
                onToggle: () =>
                    setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPwController,
                label: 'Confirmer le nouveau mot de passe',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.navyDark, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Le mot de passe doit comporter au moins 6 caractères.',
                    style: TextStyle(fontSize: 13, color: AppColors.navyDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSavingPw ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isSavingPw
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      'Modifier le mot de passe',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: AppColors.navyDark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.navyDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.navyDark, size: 20),
        filled: true,
        fillColor: readOnly ? Colors.grey[50] : AppColors.offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyDark, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline,
            color: AppColors.navyDark, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyDark, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
    );
  }
}
