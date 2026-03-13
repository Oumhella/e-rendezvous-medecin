import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterPatientScreen extends StatefulWidget {
  const RegisterPatientScreen({super.key});

  @override
  State<RegisterPatientScreen> createState() => _RegisterPatientScreenState();
}

class _RegisterPatientScreenState extends State<RegisterPatientScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _cinController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _secuController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _cinController.dispose();
    _dateNaissanceController.dispose();
    _secuController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passwordController.text != _confirmController.text) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _telephoneController.text.isEmpty ||
        _adresseController.text.isEmpty ||
        _cinController.text.isEmpty ||
        _dateNaissanceController.text.isEmpty ||
        _secuController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('Veuillez remplir tous les champs.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Veuillez sélectionner une date de naissance.');
      return;
    }
    setState(() => _isLoading = true);
    
    final error = await _authService.register(
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      email: _emailController.text.trim(),
      telephone: _telephoneController.text.trim(),
      adresse: _adresseController.text.trim(),
      cin: _cinController.text.trim(),
      dateNaissance: _selectedDate!,
      password: _passwordController.text.trim(),
      numeroSecuriteSociale: _secuController.text.trim(),
    );

    setState(() => _isLoading = false);
    
    if (error == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      if (mounted) _showError(error);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 6570)), // 18 ans par défaut
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 ans minimum
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateNaissanceController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBEBDC), // warm cream
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBEBDC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4A4A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Inscription Patient",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B4A4A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Nom
            _buildInputField(
              controller: _nomController,
              hintText: "Nom",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // Prénom
            _buildInputField(
              controller: _prenomController,
              hintText: "Prénom",
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),

            // Email
            _buildInputField(
              controller: _emailController,
              hintText: "Email",
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Téléphone
            _buildInputField(
              controller: _telephoneController,
              hintText: "Téléphone",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Adresse
            _buildInputField(
              controller: _adresseController,
              hintText: "Adresse",
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 16),

            // CIN
            _buildInputField(
              controller: _cinController,
              hintText: "CIN",
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),

            // Numéro de sécurité sociale
            _buildInputField(
              controller: _secuController,
              hintText: "Numéro de sécurité sociale",
              icon: Icons.security_outlined,
            ),
            const SizedBox(height: 16),

            // Date de naissance
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE4), // warm beige input
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFF8A9BB0),
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _dateNaissanceController.text.isEmpty ? "Date de naissance" : _dateNaissanceController.text,
                        style: TextStyle(
                          color: _dateNaissanceController.text.isEmpty 
                              ? const Color(0xFF8A9BB0)
                              : const Color(0xFF1A1A1A),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mot de passe
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE4), // warm beige input
                borderRadius: BorderRadius.circular(50),
              ),
              child: TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Mot de passe",
                  hintStyle: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 15),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8A9BB0), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF8A9BB0),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirmer mot de passe
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE4), // warm beige input
                borderRadius: BorderRadius.circular(50),
              ),
              child: TextField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Confirmer mot de passe",
                  hintStyle: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 15),
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8A9BB0), size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF8A9BB0),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // S'inscrire button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9B90E), // amber
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        "S'inscrire",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                onPressed: _isLoading ? null : _register,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDE4), // warm beige input
        borderRadius: BorderRadius.circular(50),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF8A9BB0), fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF8A9BB0), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
