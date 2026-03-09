import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomController        = TextEditingController();
  final _prenomController      = TextEditingController();
  final _emailController       = TextEditingController();
  final _telephoneController   = TextEditingController();
  final _adresseController     = TextEditingController();
  final _cinController         = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _secuController        = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmController     = TextEditingController();
  final _authService           = AuthService();
  bool _isLoading              = false;
  bool _obscurePassword        = true;
  DateTime? _selectedDate;

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
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      adresse: _adresseController.text.trim(),
      cin: _cinController.text.trim(),
      dateNaissance: _selectedDate!,
      numeroSecuriteSociale: _secuController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (error != null && mounted) _showError(error);
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
      body: Column(
        children: [
          // ── Header gradient ──
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navyDark, AppColors.lightBlue],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDark.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Image(
                        image: AssetImage('assets/images/logo.png'),
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Créer un compte',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Rejoignez notre réseau de médecins',
                    style: TextStyle(color: AppColors.white.withOpacity(0.9), fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Formulaire ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildField(_nomController, 'Nom', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildField(_prenomController, 'Prénom', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildField(_emailController, 'Email', Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _buildField(_telephoneController, 'Téléphone', Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _buildField(_adresseController, 'Adresse', Icons.home_outlined),
                  const SizedBox(height: 16),
                  _buildField(_cinController, 'CIN', Icons.credit_card_outlined),
                  const SizedBox(height: 16),
                  _buildDateField(),
                  const SizedBox(height: 16),
                  _buildField(_secuController, 'N° Sécurité Sociale', Icons.security_outlined),
                  const SizedBox(height: 16),
                  _buildField(_passwordController, 'Mot de passe', Icons.lock_outline,
                      obscure: true),
                  const SizedBox(height: 16),
                  _buildField(_confirmController, 'Confirmer mot de passe', Icons.lock_outline,
                      obscure: true),
                  const SizedBox(height: 32),

                  // Bouton
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius:
                            BorderRadius.all(Radius.circular(16)),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white)
                            : const Text(
                                "S'inscrire",
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _dateNaissanceController,
        readOnly: true,
        style: const TextStyle(fontSize: 16, color: AppColors.navyDark),
        decoration: InputDecoration(
          hintText: 'Date de naissance',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.lightBlue),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppColors.lightBlue),
            onPressed: _selectDate,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.lightBlue, width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 120)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.lightBlue, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: AppColors.navyDark, // body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.navyDark, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateNaissanceController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16, color: AppColors.navyDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: AppColors.lightBlue),
          suffixIcon: obscure
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.lightBlue, width: 2),
          ),
        ),
      ),
    );
  }
}