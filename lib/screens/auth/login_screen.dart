import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/secretaire_service.dart';
import '../../services/doctor_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _secretaireService = SecretaireService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Veuillez remplir tous les champs.');
      return;
    }
    setState(() => _isLoading = true);
    final error = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (error != null) {
      if (mounted) _showError(error);
      return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Utilisateur non trouvé');

      // ── FLUX SECRÉTAIRE ──
      final utilisateur = await _secretaireService.getUtilisateurByEmail(
        user.email!,
      );
      if (utilisateur != null) {
        final secretaire = await _secretaireService
            .getSecretaireByUtilisateurId(utilisateur.id);

        if (secretaire != null) {
          if (!secretaire.actif) {
            throw Exception('Ce compte secrétaire est désactivé');
          }
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/dashboard',
              arguments: secretaire.medecinId,
            );
          }
          return;
        }

        // ── FLUX MÉDECIN ──
        final medecin = await DoctorService.getMedecinByUtilisateurId(
          utilisateur.id,
        );
        if (medecin != null) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/medecin-dashboard',
              arguments: {
                'medecinId': medecin.id,
                'medecinNom': utilisateur.nom,
              },
            );
          }
          return;
        }
      }

      // ── FLUX PATIENT ──
      // Si ni secrétaire ni médecin → c'est un patient, on redirige vers HomeScreen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
      await _authService.logout();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header gradient avec logo ──
            Container(
              width: double.infinity,
              height: 260,
              decoration: const BoxDecoration(
                gradient: AppColors.gradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: const AssetImage('/images/logo.png'),
                      width: 90,
                      height: 90,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.local_hospital,
                        size: 70,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'E-Rendez-vous',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'Médecin',
                      style: TextStyle(
                        color: AppColors.lightBlue,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Formulaire ──
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Connectez-vous à votre compte',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 28),

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Mot de passe
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Mot de passe',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.navyDark,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showResetDialog,
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(color: AppColors.navyDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bouton connexion
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lien inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Pas encore de compte ? ",
                        style: TextStyle(color: Colors.grey),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            color: AppColors.navyDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: AppColors.navyDark),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyDark, width: 2),
        ),
      ),
    );
  }

  void _showResetDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Réinitialiser le mot de passe',
          style: TextStyle(color: AppColors.navyDark),
        ),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: 'Votre email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyDark,
            ),
            onPressed: () async {
              final error = await _authService.resetPassword(
                emailController.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error ?? '📧 Email envoyé ! Vérifiez votre boîte.',
                    ),
                    backgroundColor: error != null
                        ? Colors.red
                        : AppColors.navyDark,
                  ),
                );
              }
            },
            child: const Text(
              'Envoyer',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}