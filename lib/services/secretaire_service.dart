import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rendez_vous.dart';
import '../models/creneau_horaire.dart';
import '../models/utilisateur.dart';
import '../models/secretaire.dart';

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
      query = query.where('medecin_id', isEqualTo: _db.doc('medecin/$medecinId'));
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

  /// Add a new appointment and optionally mark the time slot as booked.
  Future<DocumentReference> addRendezVous(
    RendezVous rdv, {
    String? creneauHeureDebut,
  }) async {
    final batch = _db.batch();
    final rdvRef = _db.collection('rendezVous').doc();
    batch.set(rdvRef, rdv.toFirestore());

    if (creneauHeureDebut != null && rdv.dateHeure != null) {
      final startOfDay = DateTime(
          rdv.dateHeure!.year, rdv.dateHeure!.month, rdv.dateHeure!.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final slotQuery = await _db
          .collection('creneaux')
          .where('medecin_id', isEqualTo: _db.doc('medecin/${rdv.medecinId}'))
          .get();

      for (var doc in slotQuery.docs) {
        final c = CreneauHoraire.fromFirestore(doc);
        if (c.heureDebut == creneauHeureDebut &&
            c.disponible &&
            c.dateJour != null &&
            c.dateJour!.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            c.dateJour!.isBefore(endOfDay)) {
          batch.update(doc.reference, {'disponible': false});
          break; // only book the first matching slot
        }
      }
    }

    await batch.commit();
    return rdvRef;
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

  /// Real-time stream of all time-slots for a given doctor.
  Stream<List<CreneauHoraire>> getCreneauxStream(String medecinId) {
    return _db
        .collection('creneaux')
        .where('medecin_id', isEqualTo: FirebaseFirestore.instance.doc('medecin/$medecinId'))
        // Note: Ordering by dateJour might require a composite index if filtered by medecin_id.
        // Doing simple where, and we will sort in Dart if needed, to avoid index demands right now.
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreneauHoraire.fromFirestore(doc))
            .toList());
  }

  /// Add a new time-slot.
  Future<DocumentReference> addCreneau(CreneauHoraire creneau) {
    return _db.collection('creneaux').add(creneau.toFirestore());
  }

  /// Update an existing time-slot.
  Future<void> updateCreneau(CreneauHoraire creneau) {
    return _db
        .collection('creneaux')
        .doc(creneau.id)
        .update(creneau.toFirestore());
  }

  /// Delete a time-slot.
  Future<void> deleteCreneau(String id) {
    return _db.collection('creneaux').doc(id).delete();
  }

  /// Batch create time-slots for a specific day and duration.
  Future<void> batchCreateCreneaux({
    required String medecinId,
    required DateTime dateJour,
    required TimeOfDay heureDebut,
    required TimeOfDay heureFin,
    required int dureeMinutes,
  }) async {
    final batch = _db.batch();
    
    // Convert to minutes since midnight for easy iteration
    int currentMinutes = heureDebut.hour * 60 + heureDebut.minute;
    final endMinutes = heureFin.hour * 60 + heureFin.minute;

    while (currentMinutes + dureeMinutes <= endMinutes) {
      final startH = (currentMinutes ~/ 60).toString().padLeft(2, '0');
      final startM = (currentMinutes % 60).toString().padLeft(2, '0');
      
      final nextMinutes = currentMinutes + dureeMinutes;
      final endH = (nextMinutes ~/ 60).toString().padLeft(2, '0');
      final endM = (nextMinutes % 60).toString().padLeft(2, '0');

      final creneauRef = _db.collection('creneaux').doc();
      final newSlot = CreneauHoraire(
        id: creneauRef.id,
        heureDebut: '$startH:$startM',
        heureFin: '$endH:$endM',
        disponible: true,
        dateJour: dateJour,
        medecinId: medecinId,
      );

      batch.set(creneauRef, newSlot.toFirestore());
      
      currentMinutes = nextMinutes;
    }

    await batch.commit();
  }

  /// Fetch available time-slots for a doctor on a given date.
  Future<List<CreneauHoraire>> getCreneauxDisponibles(
      String medecinId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // We query all slots for this doctor, then filter in Dart.
    // This avoids needing to create a complex Composite Index in Firebase Console.
    final snapshot = await _db
        .collection('creneaux')
        .where('medecin_id', isEqualTo: _db.doc('medecin/$medecinId'))
        .get();

    final filtered = snapshot.docs
        .map((doc) => CreneauHoraire.fromFirestore(doc))
        .where((c) =>
            c.disponible &&
            c.dateJour != null &&
            c.dateJour!.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            c.dateJour!.isBefore(endOfDay))
        .toList();

    // Remove duplicates (in case batch was run multiple times for the same times)
    final seen = <String>{};
    final uniqueSlots = <CreneauHoraire>[];
    for (var slot in filtered) {
      if (seen.add(slot.heureDebut)) {
        uniqueSlots.add(slot);
      }
    }

    // Sort chronologically
    uniqueSlots.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));

    return uniqueSlots;
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

  // ── Utilisateurs et Secrétaires ──────────────────────────────────

  /// Fetch the `utilisateur` document whose `email` matches the given email.
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
  Future<Secretaire?> getSecretaireByUtilisateurId(String utilisateurId) async {
    final query = await _db
        .collection('secretaire')
        .where('utilisateur_id', isEqualTo: utilisateurId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Secretaire.fromFirestore(query.docs.first);
  }
}
