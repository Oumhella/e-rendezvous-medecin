import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Utilisateur connecté en ce moment
  User? get currentUser => _auth.currentUser;

  // Stream pour écouter les changements de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── INSCRIPTION ──────────────────────────────────────
  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sauvegarder les infos du patient dans Firestore
      await _db.collection('patients').doc(credential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // null = succès
    } on FirebaseAuthException catch (e) {
      return _handleError(e.code);
    }
  }

  // ── CONNEXION ────────────────────────────────────────
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // null = succès
    } on FirebaseAuthException catch (e) {
      return _handleError(e.code);
    }
  }

  // ── DÉCONNEXION ──────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── MOT DE PASSE OUBLIÉ ──────────────────────────────
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleError(e.code);
    }
  }

  // ── GESTION DES ERREURS ──────────────────────────────
  String _handleError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}