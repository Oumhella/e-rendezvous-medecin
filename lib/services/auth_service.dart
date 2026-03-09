import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/secretaire.dart';
import '../models/utilisateur.dart';

/// Handles Firebase Authentication & secretary profile fetching.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Current Firebase user (null if not logged in).
  User? get currentUser => _auth.currentUser;

  /// Stream that emits whenever auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email & password.
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch the `utilisateur` document whose `email` matches the current user.
  Future<Utilisateur?> getUtilisateurByEmail(String email) async {
    final query = await _db
        .collection('utilisateur')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Utilisateur.fromFirestore(query.docs.first);
  }

  /// Fetch the `secretaire` document linked to the given utilisateur ID.
  Future<Secretaire?> getSecretaireByUtilisateurId(
      String utilisateurId) async {
    final query = await _db
        .collection('secretaire')
        .where('utilisateur_id', isEqualTo: utilisateurId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Secretaire.fromFirestore(query.docs.first);
  }
}
