import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterMedecinScreen extends StatefulWidget {
  const RegisterMedecinScreen({super.key});

  @override
  State<RegisterMedecinScreen> createState() => _RegisterMedecinScreenState();
}

class _RegisterMedecinScreenState extends State<RegisterMedecinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tarifController = TextEditingController();
  final _biographieController = TextEditingController();
  final _numeroOrdreController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _selectedSpecialite;

  final List<String> _specialites = [
    'Médecine Générale',
    'Cardiologie',
    'Dermatologie',
    'Pédiatrie',
    'Gynécologie',
    'Ophtalmologie',
    'Neurologie',
    'Orthopédie',
    'Psychiatrie',
    'ORL',
    'Dentisterie',
    'Endocrinologie',
  ];

  // Colors
  static const teal = Color(0xFF1B4A4A);
  static const amber = Color(0xFFF9B90E);
  static const scaffoldBg = Color(0xFFFBEBDC);
  static const inputBg = Color(0xFFF5EDE4);
  static const textDark = Color(0xFF1A1A1A);
  static const muted = Color(0xFF8A9BB0);

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tarifController.dispose();
    _biographieController.dispose();
    _numeroOrdreController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnack('Les mots de passe ne correspondent pas', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;

      // 2. Create utilisateur document
      await FirebaseFirestore.instance
          .collection('utilisateur')
          .doc(uid)
          .set({
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telephoneController.text.trim(),
        'motDePasse': '',
        'dateInscription': FieldValue.serverTimestamp(),
      });

      // 3. Get or create specialite
      String specId = '';
      if (_selectedSpecialite != null) {
        final specQuery = await FirebaseFirestore.instance
            .collection('specialite')
            .where('nom', isEqualTo: _selectedSpecialite)
            .limit(1)
            .get();

        if (specQuery.docs.isNotEmpty) {
          specId = specQuery.docs.first.id;
        } else {
          final specRef = await FirebaseFirestore.instance
              .collection('specialite')
              .add({
            'nom': _selectedSpecialite,
            'description': _selectedSpecialite,
            'codeSpecialite': _selectedSpecialite!
                .substring(0, 2)
                .toUpperCase(),
          });
          specId = specRef.id;
        }
      }

      // 4. Create medecin document
      await FirebaseFirestore.instance.collection('medecin').add({
        'utilisateur_id': uid,
        'specialite_id': specId,
        'cin': '',
        'numeroDordre': _numeroOrdreController.text.trim(),
        'adresseCabinet': _adresseController.text.trim(),
        'ville': '',
        'statutMedecin': 'en_attente',
        'dateCreation': FieldValue.serverTimestamp(),
        'cv': '',
        'diplome': '',
        'certificatExercice': '',
        'dureeConsultationMin': 30,
        'tarifConsultation': double.tryParse(
              _tarifController.text.trim()) ?? 0.0,
        'noteMoyenne': 0.0,
        'biographie': _biographieController.text.trim(),
        'anneesExperience': 0,
        'consultationEnLigne': false,
        'dateValidationCompte': null,
        'actif': false,
      });

      if (mounted) {
        _showSnack('Compte créé ! En attente de validation.');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Une erreur est survenue';
      if (e.code == 'email-already-in-use') {
        msg = 'Cet email est déjà utilisé';
      } else if (e.code == 'weak-password') {
        msg = 'Mot de passe trop faible (6 caractères min)';
      } else if (e.code == 'invalid-email') {
        msg = 'Email invalide';
      }
      _showSnack(msg, isError: true);
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          // ── WAVY TEAL HEADER ──────────────────────────────
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              color: teal,
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 48,
                left: 20,
                right: 20,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Inscription Médecin',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
          ),

          // ── FORM ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Prénom
                    _buildInput(
                      controller: _prenomController,
                      hint: 'Prénom',
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty
                          ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Nom
                    _buildInput(
                      controller: _nomController,
                      hint: 'Nom',
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty
                          ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Email
                    _buildInput(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => !v!.contains('@')
                          ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 14),

                    // Téléphone
                    _buildInput(
                      controller: _telephoneController,
                      hint: 'Téléphone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty
                          ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Mot de passe
                    _buildInput(
                      controller: _passwordController,
                      hint: 'Mot de passe',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: muted,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) => v!.length < 6
                          ? 'Min 6 caractères' : null,
                    ),
                    const SizedBox(height: 14),

                    // Confirmer MDP
                    _buildInput(
                      controller: _confirmPasswordController,
                      hint: 'Confirmer MDP',
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: muted,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (v) => v!.isEmpty
                          ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),

                    // Spécialité dropdown
                    _buildDropdown(),
                    const SizedBox(height: 14),

                    // Numéro d'ordre
                    _buildInput(
                      controller: _numeroOrdreController,
                      hint: "Numéro d'ordre professionnel",
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Adresse cabinet
                    _buildInput(
                      controller: _adresseController,
                      hint: 'Adresse du cabinet',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Tarif avec badge MAD
                    _buildTarifInput(),
                    const SizedBox(height: 14),

                    // Biographie (textarea)
                    _buildTextarea(),
                    const SizedBox(height: 14),

                    // Info banner
                    _buildInfoBanner(),
                    const SizedBox(height: 28),

                    // Submit button
                    _buildSubmitButton(),
                    const SizedBox(height: 16),

                    // Login link
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(
                              context, '/login'),
                      child: RichText(
                        text: TextSpan(
                          text: 'Déjà inscrit ? ',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Se connecter →',
                              style: TextStyle(
                                color: teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── INPUT WIDGET ─────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: textDark,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: muted,
            fontSize: 15,
          ),
          prefixIcon: Icon(icon, color: muted, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  // ── DROPDOWN SPÉCIALITÉ ──────────────────────────────────────────────
  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSpecialite,
          hint: Row(
            children: [
              Icon(Icons.medical_services_outlined,
                  color: muted, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Spécialité',
                style: TextStyle(color: muted, fontSize: 15),
              ),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: muted),
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          items: _specialites
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                        )),
                  ))
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedSpecialite = v),
        ),
      ),
    );
  }

  // ── TARIF INPUT ──────────────────────────────────────────────────────
  Widget _buildTarifInput() {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _tarifController,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: textDark,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Tarif',
          hintStyle:
              const TextStyle(color: muted, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: amber,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                'MAD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
        ),
      ),
    );
  }

  // ── BIOGRAPHIE TEXTAREA ──────────────────────────────────────────────
  Widget _buildTextarea() {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: muted.withOpacity(0.3),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: _biographieController,
        maxLines: 5,
        style: const TextStyle(
          color: textDark,
          fontSize: 15,
        ),
        decoration: const InputDecoration(
          hintText: 'Biographie',
          hintStyle: TextStyle(color: muted, fontSize: 15),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  // ── INFO BANNER ──────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: teal.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: teal.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: teal,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Votre compte sera activé après validation par l\'administrateur.',
              style: TextStyle(
                color: teal,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SUBMIT BUTTON ────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: amber.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        onPressed: _isLoading ? null : _submit,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Soumettre ma demande',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }
}

// ── WAVE CLIPPER ─────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 40,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}