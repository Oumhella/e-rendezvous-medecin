import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/secretaire_service.dart';
import '../../services/doctor_service.dart';
import 'register_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PALETTE (inchangée)
// ─────────────────────────────────────────────────────────────────────────────
const _kCream = Color(0xFFFBEBDC);
const _kAmber = Color(0xFFF9B90E);
const _kTeal  = Color(0xFF1E4545);
const _kBeige = Color(0xFFF5EDE4);
const _kText  = Color(0xFF1A1A1A);
const _kHint  = Color(0xFF8A9BB0);
const _kError = Color(0xFFE53935);

// ─────────────────────────────────────────────────────────────────────────────
//  MESSAGES D'ERREUR PERSONNALISÉS
// ─────────────────────────────────────────────────────────────────────────────
String _friendlyError(String raw) {
  if (raw.contains('wrong-password') || raw.contains('invalid-credential'))
    return '🔒 Mot de passe incorrect.\nRéessayez ou réinitialisez votre mot de passe.';
  if (raw.contains('user-not-found'))
    return '❌ Aucun compte trouvé pour cet email.\nVérifiez votre adresse ou créez un compte.';
  if (raw.contains('invalid-email'))
    return '📧 Adresse email invalide.\nEx: prenom@domaine.com';
  if (raw.contains('user-disabled') || raw.contains('désactivé'))
    return '🚫 Ce compte a été désactivé.\nContactez l\'administrateur.';
  if (raw.contains('too-many-requests'))
    return '⏳ Trop de tentatives.\nPatientez quelques minutes avant de réessayer.';
  if (raw.contains('network'))
    return '📶 Pas de connexion internet.\nVérifiez votre réseau.';
  // Message custom (ex: "Ce compte secrétaire est désactivé")
  return raw;
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOGIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Services (inchangés) ──────────────────────────────────────────────────
  final _authService      = AuthService();
  final _secretaireService = SecretaireService();

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool    _obscurePassword = true;
  bool    _isLoading       = false;
  String? _errorMessage;

  late AnimationController _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _showError(String msg) {
    setState(() => _errorMessage = _friendlyError(msg));
    _shakeCtrl.forward(from: 0);
  }

  void _clearError() => setState(() => _errorMessage = null);

  // ── LOGIN — logique originale inchangée ───────────────────────────────────
  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Validation locale
    if (email.isEmpty) {
      _showError('📧 Veuillez saisir votre adresse email.'); return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showError('📧 Adresse email invalide.'); return;
    }
    if (password.isEmpty) {
      _showError('🔒 Veuillez saisir votre mot de passe.'); return;
    }
    if (password.length < 6) {
      _showError('🔒 Le mot de passe doit faire au moins 6 caractères.'); return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    // ── Auth Firebase (inchangé) ──────────────────────────────────────────
    final error = await _authService.login(email: email, password: password);
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error); return;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('Utilisateur non trouvé');

      // ── FLUX SECRÉTAIRE (inchangé) ────────────────────────────────────
      final utilisateur = await _secretaireService
          .getUtilisateurByEmail(user.email!);

      if (utilisateur != null) {
        final secretaire = await _secretaireService
            .getSecretaireByUtilisateurId(utilisateur.id);

        if (secretaire != null) {
          if (!secretaire.actif) {
            throw Exception('Ce compte secrétaire est désactivé');
          }
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, '/dashboard',
              arguments: secretaire.medecinId,
            );
          }
          return;
        }

        // ── FLUX MÉDECIN (inchangé) ───────────────────────────────────
        final medecin = await DoctorService
            .getMedecinByUtilisateurId(utilisateur.id);
        if (medecin != null) {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, '/medecin-dashboard',
              arguments: {
                'medecinId': medecin.id,
                'medecinNom': utilisateur.nom,
              },
            );
          }
          return;
        }
      }

      // ── FLUX PATIENT (inchangé) ───────────────────────────────────────
      if (mounted) Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
      await _authService.logout();
    }
  }

  // ── Mot de passe oublié ───────────────────────────────────────────────────
  void _forgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ForgotPasswordSheet(
            initialEmail: _emailCtrl.text.trim(),
            authService: _authService,
          ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCream,
      body: Stack(children: [
        // Dot grid background
        CustomPaint(size: Size.infinite, painter: _DotGridPainter()),

        SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 40),
          child: Column(children: [
            const SizedBox(height: 60),

            // ── Logo ──────────────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('+ ', style: TextStyle(
                  color: _kAmber, fontSize: 22,
                  fontWeight: FontWeight.w700)),
              Image.asset('assets/images/logo.png', height: 36,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.local_hospital, size: 36, color: _kTeal)),
            ]),
            const SizedBox(height: 28),

            // ── Card ──────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _shakeCtrl,
              builder: (_, child) {
                final t  = _shakeCtrl.value;
                final dx = _errorMessage != null
                    ? 8 * (t < 0.25 ? t / 0.25
                         : t < 0.5  ? 1 - (t - 0.25) / 0.25 * 2
                         : t < 0.75 ? -(t - 0.5) / 0.25
                         : -1 + (t - 0.75) / 0.25)
                    : 0.0;
                return Transform.translate(
                    offset: Offset(dx, 0), child: child);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text('Bon retour !',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 26, fontWeight: FontWeight.w800,
                            color: _kText)),
                    const SizedBox(height: 5),
                    Text('Connectez-vous à votre espace santé',
                        style: TextStyle(fontSize: 13, color: _kHint)),
                    const SizedBox(height: 22),

                    // ── Bannière d'erreur ─────────────────────────────────
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _kError.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _kError.withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(_errorMessage!,
                                  style: const TextStyle(
                                      color: _kError, fontSize: 13,
                                      height: 1.5)),
                            ),
                            GestureDetector(
                              onTap: _clearError,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.close_rounded,
                                    size: 16, color: _kError),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Email ─────────────────────────────────────────────
                    _field(
                      ctrl: _emailCtrl,
                      hint: 'Email',
                      icon: Icons.mail_outline_rounded,
                      type: TextInputType.emailAddress,
                      onChanged: (_) => _clearError(),
                    ),
                    const SizedBox(height: 14),

                    // ── Mot de passe ──────────────────────────────────────
                    _field(
                      ctrl: _passwordCtrl,
                      hint: 'Mot de passe',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      onChanged: (_) => _clearError(),
                      onSubmit: (_) => _login(),
                      suffix: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _kHint, size: 20),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Bouton connexion ──────────────────────────────────
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAmber,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5))
                            : Text('Se connecter',
                                style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Mot de passe oublié ───────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text('Mot de passe oublié ?',
                            style: GoogleFonts.inter(
                                color: _kAmber, fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // ── Créer un compte ───────────────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen())),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Pas encore de compte ? ',
                                style: TextStyle(
                                    color: _kHint, fontSize: 14)),
                            Text("S'inscrire",
                                style: GoogleFonts.inter(
                                    color: _kText, fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Champ texte réutilisable ───────────────────────────────────────────────
  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? type,
    void Function(String)? onChanged,
    void Function(String)? onSubmit,
  }) {
    return Container(
      decoration: BoxDecoration(
          color: _kBeige, borderRadius: BorderRadius.circular(50)),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: type,
        onChanged: onChanged,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kHint, fontSize: 15),
          prefixIcon: Icon(icon, color: _kHint, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FORGOT PASSWORD BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotPasswordSheet extends StatefulWidget {
  final String      initialEmail;
  final AuthService authService;
  const _ForgotPasswordSheet({
    required this.initialEmail,
    required this.authService,
  });
  @override
  State<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _emailCtrl;
  bool    _sending = false;
  bool    _sent    = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = '📧 Veuillez saisir votre email.'); return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _error = '📧 Email invalide.'); return;
    }

    setState(() { _sending = true; _error = null; });

    // Utilise AuthService.resetPassword (logique originale)
    final error = await widget.authService.resetPassword(email);
    setState(() => _sending = false);

    if (error != null) {
      setState(() => _error = _friendlyError(error));
    } else {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),

            if (_sent) ...[
              // ── Succès ────────────────────────────────────────────────
              const Center(
                  child: Text('✅', style: TextStyle(fontSize: 52))),
              const SizedBox(height: 14),
              Text('Email envoyé !',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: _kText)),
              const SizedBox(height: 10),
              Text(
                'Lien de réinitialisation envoyé à :\n'
                '${_emailCtrl.text.trim()}\n\n'
                '📬 Pensez à vérifier vos spams.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600], height: 1.6),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAmber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('Retour à la connexion',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ] else ...[
              // ── Formulaire ────────────────────────────────────────────
              Text('Mot de passe oublié ?',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: _kText)),
              const SizedBox(height: 8),
              Text(
                'Saisissez votre email pour recevoir '
                'un lien de réinitialisation.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 18),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kError.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kError.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(
                          color: _kError, fontSize: 13, height: 1.4)),
                ),
                const SizedBox(height: 14),
              ],

              Container(
                decoration: BoxDecoration(
                    color: _kBeige,
                    borderRadius: BorderRadius.circular(50)),
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Votre email',
                    hintStyle: TextStyle(color: _kHint, fontSize: 15),
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: _kHint, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAmber,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  onPressed: _sending ? null : _send,
                  child: _sending
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text('Envoyer le lien',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                    style: GoogleFonts.inter(
                        color: Colors.grey[500], fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DOT GRID PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEDD9C8)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius  = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}