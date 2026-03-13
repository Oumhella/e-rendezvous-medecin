import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/doctor_service.dart';
import '../../models/medecin.dart';
import '../../models/utilisateur.dart';
import '../../models/secretaire.dart';
import '../../theme/app_theme.dart';

class ProfilMedecinScreen extends StatefulWidget {
  final String medecinId;
  /// Callback appelé après une sauvegarde réussie, pour rafraîchir le dashboard.
  final Future<void> Function()? onProfilUpdated;

  const ProfilMedecinScreen({
    super.key,
    required this.medecinId,
    this.onProfilUpdated,
  });

  @override
  State<ProfilMedecinScreen> createState() => _ProfilMedecinScreenState();
}

class _ProfilMedecinScreenState extends State<ProfilMedecinScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSaving = false;
  Medecin? _medecin;
  Utilisateur? _utilisateur;
  Secretaire? _secretaire;
  Utilisateur? _secretaireUtilisateur;

  late TabController _tabController;

  // ── Onglet Infos Perso ──────────────────────────────────
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();

  // ── Onglet Cabinet ─────────────────────────────────────
  final _adresseCabinetController = TextEditingController();
  final _villeController = TextEditingController();
  final _tarifController = TextEditingController();
  final _dureeConsultationController = TextEditingController();
  final _biographieController = TextEditingController();

  // ── Onglet Sécurité ────────────────────────────────────
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrentPwd = false;
  bool _showNewPwd = false;
  bool _showConfirmPwd = false;

  final _formKeyInfos = GlobalKey<FormState>();
  final _formKeyCabinet = GlobalKey<FormState>();
  final _formKeySec = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfil();
  }

  Future<void> _loadProfil({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final medecin = await DoctorService.getMedecinById(widget.medecinId);
      if (medecin != null) {
        final utilisateur =
            await DoctorService.getUtilisateurById(medecin.utilisateurId);
        // Charger la secrétaire associée
        final secretaire =
            await DoctorService.getSecretaireByMedecinId(medecin.id);
        Utilisateur? secretaireUtil;
        if (secretaire != null && secretaire.utilisateurId.isNotEmpty) {
          secretaireUtil = await DoctorService.getUtilisateurById(
            secretaire.utilisateurId,
          );
        }
        setState(() {
          _medecin = medecin;
          _utilisateur = utilisateur;
          _secretaire = secretaire;
          _secretaireUtilisateur = secretaireUtil;
        });
        if (utilisateur != null) {
          _nomController.text = utilisateur.nom;
          _prenomController.text = utilisateur.prenom;
          _telephoneController.text = utilisateur.telephone;
          _emailController.text = utilisateur.email;
        }
        _adresseCabinetController.text = medecin.adresseCabinet;
        _villeController.text = medecin.ville;
        _tarifController.text = medecin.tarifConsultation.toString();
        _dureeConsultationController.text =
            medecin.dureeConsultationMin.toString();
        _biographieController.text = medecin.biographie;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur au chargement du profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Sauvegarde Infos Perso ──────────────────────────────
  Future<void> _saveInfosPerso() async {
    if (!_formKeyInfos.currentState!.validate()) return;
    if (_medecin == null) return;
    setState(() => _isSaving = true);
    try {
      // Mise à jour Firestore
      await DoctorService.updateUtilisateur(_medecin!.utilisateurId, {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'telephone': _telephoneController.text.trim(),
      });

      // Mise à jour email Firebase Auth si modifié
      final authUser = FirebaseAuth.instance.currentUser;
      final newEmail = _emailController.text.trim();
      if (authUser != null && authUser.email != newEmail) {
        await authUser.verifyBeforeUpdateEmail(newEmail);
        // Mettre à jour aussi dans Firestore
        await DoctorService.updateUtilisateur(_medecin!.utilisateurId, {
          'email': newEmail,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Un email de confirmation a été envoyé à la nouvelle adresse.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Rafraîchir le greeting du dashboard
      await widget.onProfilUpdated?.call();

      // Recharger le profil pour mettre à jour l'entête (nom, initiales…)
      await _loadProfil(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Informations mises à jour avec succès',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.navyDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Sauvegarde Cabinet ──────────────────────────────────
  Future<void> _saveCabinet() async {
    if (!_formKeyCabinet.currentState!.validate()) return;
    if (_medecin == null) return;
    setState(() => _isSaving = true);
    try {
      await DoctorService.updateMedecin(_medecin!.id, {
        'adresseCabinet': _adresseCabinetController.text.trim(),
        'ville': _villeController.text.trim(),
        'tarifConsultation':
            double.tryParse(_tarifController.text) ?? 0.0,
        'dureeConsultationMin':
            int.tryParse(_dureeConsultationController.text) ?? 30,
        'biographie': _biographieController.text.trim(),
      });

      // Recharger le profil pour synchroniser _medecin avec Firestore
      await _loadProfil(silent: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cabinet mis à jour avec succès',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.navyDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Changement de mot de passe ──────────────────────────
  Future<void> _changePassword() async {
    if (!_formKeySec.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null || authUser.email == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Ré-authentifier d'abord
      final credential = EmailAuthProvider.credential(
        email: authUser.email!,
        password: _currentPasswordController.text,
      );
      await authUser.reauthenticateWithCredential(credential);

      // Changer le mot de passe
      await authUser.updatePassword(_newPasswordController.text);

      // Effacer les champs
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mot de passe modifié avec succès',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.navyDark,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Mot de passe actuel incorrect.';
          break;
        case 'weak-password':
          message = 'Le nouveau mot de passe est trop faible (min. 6 caractères).';
          break;
        default:
          message = 'Erreur : ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseCabinetController.dispose();
    _villeController.dispose();
    _tarifController.dispose();
    _dureeConsultationController.dispose();
    _biographieController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_medecin == null || _utilisateur == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Impossible de charger le profil.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfil,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // En-tête avec initiales
        Container(
          color: AppColors.navyDark,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.lightBlue,
                child: Text(
                  '${_utilisateur!.prenom.isNotEmpty ? _utilisateur!.prenom[0] : ''}${_utilisateur!.nom.isNotEmpty ? _utilisateur!.nom[0] : ''}'
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dr. ${_utilisateur!.prenom} ${_utilisateur!.nom}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _utilisateur!.email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              // ── Note / Rating ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(5, (i) {
                    final note = _medecin!.noteMoyenne;
                    if (i < note.floor()) {
                      return const Icon(Icons.star_rounded,
                          color: Color(0xFFFFD700), size: 18);
                    } else if (i < note && note - i >= 0.5) {
                      return const Icon(Icons.star_half_rounded,
                          color: Color(0xFFFFD700), size: 18);
                    } else {
                      return Icon(Icons.star_outline_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 18);
                    }
                  }),
                  const SizedBox(width: 6),
                  Text(
                    _medecin!.noteMoyenne.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' / 5',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.lightBlue,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: const [
                  Tab(text: 'Infos perso.'),
                  Tab(text: 'Cabinet'),
                  Tab(text: 'Sécurité'),
                  Tab(text: 'Secrétaire'),
                ],
              ),
            ],
          ),
        ),

        // Corps des onglets
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInfosPersoTab(),
              _buildCabinetTab(),
              _buildSecuriteTab(),
              _buildSecretaireTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Onglet 1 : Infos personnelles ──────────────────────
  Widget _buildInfosPersoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyInfos,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nomController,
              label: 'Nom',
              icon: Icons.person,
              validator: (v) => v!.isEmpty ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _prenomController,
              label: 'Prénom',
              icon: Icons.person_outline,
              validator: (v) => v!.isEmpty ? 'Ce champ est requis' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _telephoneController,
              label: 'Téléphone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Ce champ est requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Si vous modifiez l\'email, un lien de confirmation sera envoyé à la nouvelle adresse.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSaveButton(onPressed: _saveInfosPerso),
          ],
        ),
      ),
    );
  }

  // ── Onglet 2 : Cabinet ──────────────────────────────────
  Widget _buildCabinetTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeyCabinet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              controller: _adresseCabinetController,
              label: 'Adresse du cabinet',
              icon: Icons.business,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _villeController,
              label: 'Ville',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _tarifController,
                    label: 'Tarif (DH)',
                    icon: Icons.attach_money,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (double.tryParse(v) == null) return 'Invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _dureeConsultationController,
                    label: 'Durée (min)',
                    icon: Icons.timer,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      if (int.tryParse(v) == null) return 'Invalide';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _biographieController,
              label: 'Biographie',
              icon: Icons.article,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            _buildSaveButton(onPressed: _saveCabinet),
          ],
        ),
      ),
    );
  }

  // ── Onglet 3 : Sécurité ────────────────────────────────
  Widget _buildSecuriteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKeySec,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildPasswordField(
              controller: _currentPasswordController,
              label: 'Mot de passe actuel',
              obscure: !_showCurrentPwd,
              onToggle: () =>
                  setState(() => _showCurrentPwd = !_showCurrentPwd),
              validator: (v) =>
                  v!.isEmpty ? 'Entrez votre mot de passe actuel' : null,
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Nouveau mot de passe',
              obscure: !_showNewPwd,
              onToggle: () => setState(() => _showNewPwd = !_showNewPwd),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                if (v.length < 6) return 'Minimum 6 caractères';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmer le nouveau mot de passe',
              obscure: !_showConfirmPwd,
              onToggle: () =>
                  setState(() => _showConfirmPwd = !_showConfirmPwd),
              validator: (v) {
                if (v != _newPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSaveButton(
              onPressed: _changePassword,
              label: 'Changer le mot de passe',
              icon: Icons.lock_reset,
            ),
          ],
        ),
      ),
    );
  }

  // ── Onglet 4 : Secrétaire ──────────────────────────────
  Widget _buildSecretaireTab() {
    if (_secretaire == null || _secretaireUtilisateur == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune secrétaire assignée',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contactez l\'administration pour associer\nune secrétaire à votre compte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final sec = _secretaire!;
    final util = _secretaireUtilisateur!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Carte de profil de la secrétaire
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar + nom
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.lightBlue,
                        child: Text(
                          '${util.prenom.isNotEmpty ? util.prenom[0] : ''}${util.nom.isNotEmpty ? util.nom[0] : ''}'
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              util.nomComplet,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: sec.actif
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                sec.actif ? '✅ Active' : '❌ Inactive',
                                style: TextStyle(
                                  color: sec.actif
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Informations détaillées
                  _buildInfoRow(Icons.email_outlined, 'Email', util.email),
                  const SizedBox(height: 14),
                  _buildInfoRow(Icons.phone_outlined, 'Téléphone', util.telephone),
                  const SizedBox(height: 14),
                  _buildInfoRow(Icons.credit_card_outlined, 'CIN', sec.cin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── Widgets réutilisables ───────────────────────────────

  Widget _buildSaveButton({
    required Future<void> Function() onPressed,
    String label = 'Enregistrer les modifications',
    IconData icon = Icons.save,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Icon(icon, color: Colors.white),
        label: Text(
          _isSaving ? 'Enregistrement...' : label,
          style: const TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.navyDark.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyDark, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline,
            color: AppColors.navyDark.withOpacity(0.6)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyDark, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
