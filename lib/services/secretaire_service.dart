import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rendez_vous.dart';
import '../models/creneau_horaire.dart';

/// Firestore CRUD operations for the secretary role.
class SecretaireService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── RendezVous ──────────────────────────────────────────────────

  /// Real-time stream of appointments, filtered by the secretary's doctor.
  Stream<List<RendezVous>> getRendezVousStream({
    String? medecinId,
    DateTime? dateDebut,
    DateTime? dateFin,
  }) {
    Query query = _db.collection('rendezVous');

    if (medecinId != null && medecinId.isNotEmpty) {
      query = query.where('medecin_id', isEqualTo: medecinId);
    }
    if (dateDebut != null) {
      query = query.where('dateHeure',
          isGreaterThanOrEqualTo: Timestamp.fromDate(dateDebut));
    }
    if (dateFin != null) {
      query = query.where('dateHeure',
          isLessThanOrEqualTo: Timestamp.fromDate(dateFin));
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => RendezVous.fromFirestore(doc)).toList());
  }

  /// Add a new appointment.
  Future<DocumentReference> addRendezVous(RendezVous rdv) {
    return _db.collection('rendezVous').add(rdv.toFirestore());
  }

  /// Update an existing appointment.
  Future<void> updateRendezVous(RendezVous rdv) {
    return _db
        .collection('rendezVous')
        .doc(rdv.id)
        .update(rdv.toFirestore());
  }

  /// Delete an appointment.
  Future<void> deleteRendezVous(String id) {
    return _db.collection('rendezVous').doc(id).delete();
  }

  // ── Créneaux ───────────────────────────────────────────────────

  /// Fetch available time-slots for a doctor on a given date.
  Future<List<CreneauHoraire>> getCreneauxDisponibles(
      String medecinId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('creneaux')
        .where('medecin_id', isEqualTo: medecinId)
        .where('dateJour',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateJour', isLessThan: Timestamp.fromDate(endOfDay))
        .where('disponible', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => CreneauHoraire.fromFirestore(doc))
        .toList();
  }

  // ── Patients ───────────────────────────────────────────────────

  /// Find an existing patient by CIN, or create a new patient + utilisateur.
  /// Returns the patient document ID.
  Future<String> findOrCreatePatient({
    required String nom,
    required String prenom,
    required String telephone,
    required String cin,
  }) async {
    // Try to find existing patient by CIN
    final existingQuery = await _db
        .collection('patient')
        .where('cin', isEqualTo: cin)
        .limit(1)
        .get();

    if (existingQuery.docs.isNotEmpty) {
      return existingQuery.docs.first.id;
    }

    // Create a new utilisateur first
    final userRef = await _db.collection('utilisateur').add({
      'nom': nom,
      'prenom': prenom,
      'email': '',
      'telephone': telephone,
      'motDePasse': '',
      'dateInscription': FieldValue.serverTimestamp(),
    });

    // Then create the patient referencing the utilisateur
    final patRef = await _db.collection('patient').add({
      'cin': cin,
      'dateNaissance': null,
      'dateInscription': FieldValue.serverTimestamp(),
      'adresse': '',
      'numeroSecuriteSociale': '',
      'actif': true,
      'utilisateur_id': userRef.id,
    });

    return patRef.id;
  }
}
