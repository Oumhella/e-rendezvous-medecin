import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Utilisateur connecté en ce moment
  User? get currentUser => _auth.currentUser;

  // Stream pour écouter les changements de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── INSCRIPTION ──────────────────────────────────────
  Future<String?> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
    required String cin,
    required DateTime dateNaissance,
    required String numeroSecuriteSociale,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user!.uid;

      // Crypter le mot de passe avec SHA-256
      final bytes = utf8.encode(password);
      final digest = sha256.convert(bytes);
      final hashedPassword = digest.toString();

      // Sauvegarder dans collection utilisateur
      await _db.collection('utilisateur').doc(userId).set({
        'idU': userId,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'password': hashedPassword, // Mot de passe crypté
        'dateInscription': FieldValue.serverTimestamp(),
        'statut': 'actif',
        'photoProfil': '',
        'provider': 'email',
      });

      // Sauvegarder dans collection patient
      await _db.collection('patient').doc(userId).set({
        'actif': false,
        'adresse': adresse,
        'cin': cin,
        'dateNaissance': Timestamp.fromDate(dateNaissance),
        'numeroSecuriteSociale': numeroSecuriteSociale,
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

  // ── CONNEXION GOOGLE ───────────────────────────────
  Future<String?> signInWithGoogle() async {
    try {
      // 1. Déconnexion de Google au cas où l'utilisateur est connecté
      await _googleSignIn.signOut();

      // 2. Connexion avec Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'Connexion Google annulée';
      }

      // 3. Obtenir les authentifications
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Connexion avec Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // 5. Vérifier si l'utilisateur existe déjà dans Firestore
        final DocumentSnapshot userDoc = await _db.collection('utilisateur').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // 6. Créer le profil utilisateur s'il n'existe pas
          await _db.collection('utilisateur').doc(user.uid).set({
            'idU': user.uid,
            'nom': user.displayName?.split(' ').last ?? '',
            'prenom': user.displayName?.split(' ').first ?? '',
            'email': user.email,
            'telephone': '',
            'dateInscription': FieldValue.serverTimestamp(),
            'statut': 'actif',
            'photoProfil': user.photoURL ?? '',
            'provider': 'google', // Indiquer que c'est une connexion Google
          });

          // 7. Créer le profil patient
          await _db.collection('patient').doc(user.uid).set({
            'actif': false,
            'adresse': '',
            'cin': '',
            'dateNaissance': Timestamp.now(), // Date par défaut
          });
        }
      }

      return null; // Succès
    } catch (e) {
      return 'Erreur lors de la connexion Google: ${e.toString()}';
    }
  }

  // ── DÉCONNEXION ──────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
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
      case 'network-request-failed':
        return 'Erreur de connexion. Vérifiez votre internet.';
      default:
        return 'Une erreur est survenue. Réessayez.';
    }
  }
}
