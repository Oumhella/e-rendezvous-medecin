import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rendez_vous.dart';
import '../models/creneau_horaire.dart';
import '../models/utilisateur.dart';
import '../models/secretaire.dart';
import '../models/horaires_template.dart';

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

  /// Get slots for a specific date range (useful for weekly view).
  Stream<List<CreneauHoraire>> getCreneauxForRangeStream(String medecinId, DateTime start, DateTime end) {
    final medRef = _db.doc('medecin/$medecinId');
    return _db
        .collection('creneaux')
        .where('medecin_id', isEqualTo: medRef)
        // Note: We remove the date range filter from Firestore to avoid composite index requirements.
        // We filter in memory instead.
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => CreneauHoraire.fromFirestore(doc))
            .where((c) => 
               c.dateJour != null && 
               c.dateJour!.isAfter(start.subtract(const Duration(seconds: 1))) && 
               c.dateJour!.isBefore(end))
            .toList();
        });
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
  /// Supports multiple intervals and optional clearing of the day first.
  Future<void> batchCreateCreneaux({
    required String medecinId,
    required DateTime dateJour,
    required List<TemplateInterval> intervalles,
    required int dureeMinutes,
    bool clearFirst = false,
  }) async {
    final batch = _db.batch();
    final medRef = _db.doc('medecin/$medecinId');
    final dateOnly = DateTime(dateJour.year, dateJour.month, dateJour.day);

    if (clearFirst) {
      await _cleanupSlotsAndCancelRDVs(medecinId, [dateOnly], batch);
    }

    for (var interval in intervalles) {
      final startParts = interval.heureDebut.split(':');
      final endParts = interval.heureFin.split(':');
      
      if (startParts.length < 2 || endParts.length < 2) continue;

      int currentMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      while (currentMinutes + dureeMinutes <= endMinutes) {
        final startH = (currentMinutes ~/ 60).toString().padLeft(2, '0');
        final startM = (currentMinutes % 60).toString().padLeft(2, '0');
        
        final nextMinutes = currentMinutes + dureeMinutes;
        final endH = (nextMinutes ~/ 60).toString().padLeft(2, '0');
        final endM = (nextMinutes % 60).toString().padLeft(2, '0');

        // PAST DATE PROTECTION: Skip if date is today and slot has already started
        final now = DateTime.now();
        final slotStartTime = DateTime(dateOnly.year, dateOnly.month, dateOnly.day, int.parse(startH), int.parse(startM));
        
        if (slotStartTime.isAfter(now)) {
          final creneauRef = _db.collection('creneaux').doc();
          batch.set(creneauRef, {
            'heureDebut': '$startH:$startM',
            'heureFin': '$endH:$endM',
            'disponible': true,
            'dateJour': Timestamp.fromDate(dateOnly),
            'medecin_id': medRef,
          });
        }
        
        currentMinutes = nextMinutes;
      }
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

  // ── Horaires Templates ──────────────────────────────────────────

  /// Real-time stream of schedule templates for a given doctor.
  Stream<List<HorairesTemplate>> getTemplatesStream(String medecinId) {
    return _db
        .collection('templates')
        .where('medecin_id', isEqualTo: _db.doc('medecin/$medecinId'))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HorairesTemplate.fromFirestore(doc))
            .toList());
  }

  /// Add a new schedule template.
  Future<DocumentReference> addTemplate(HorairesTemplate template) {
    return _db.collection('templates').add(template.toFirestore());
  }

  /// Update an existing schedule template.
  Future<void> updateTemplate(HorairesTemplate template) {
    return _db
        .collection('templates')
        .doc(template.id)
        .update(template.toFirestore());
  }

  /// Delete a schedule template.
  Future<void> deleteTemplate(String id) {
    return _db.collection('templates').doc(id).delete();
  }

  /// Apply a template to several dates. 
  /// Fetches the doctor's duration automatically.
  Future<void> applyTemplateToDays({
    required String medecinId,
    required List<DateTime> dates,
    required String templateId,
  }) async {
    // 1. Fetch the doctor for duration
    final medDoc = await _db.collection('medecin').doc(medecinId).get();
    if (!medDoc.exists) throw 'Médecin introuvable';
    final int duree = (medDoc.data()?['dureeConsultationMin'] ?? 30).toInt();

    // 2. Fetch the template
    final tempDoc = await _db.collection('templates').doc(templateId).get();
    if (!tempDoc.exists) throw 'Modèle introuvable';
    final template = HorairesTemplate.fromFirestore(tempDoc);

    final batch = _db.batch();
    final medRef = _db.doc('medecin/$medecinId');

    // 0. Cleanup existing slots for these dates
    await _cleanupSlotsAndCancelRDVs(medecinId, dates, batch);

    for (var date in dates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      for (var interval in template.intervalles) {
        // Parse "HH:mm"
        final startParts = interval.heureDebut.split(':');
        final endParts = interval.heureFin.split(':');
        
        int currentMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        while (currentMinutes + duree <= endMinutes) {
          final startH = (currentMinutes ~/ 60).toString().padLeft(2, '0');
          final startM = (currentMinutes % 60).toString().padLeft(2, '0');
          
          final nextMin = currentMinutes + duree;
          final endH = (nextMin ~/ 60).toString().padLeft(2, '0');
          final endM = (nextMin % 60).toString().padLeft(2, '0');

          // PAST DATE PROTECTION: Skip if date is today and slot has already started
          final now = DateTime.now();
          final slotStartTime = DateTime(dateOnly.year, dateOnly.month, dateOnly.day, int.parse(startH), int.parse(startM));

          if (slotStartTime.isAfter(now)) {
            final ref = _db.collection('creneaux').doc();
            batch.set(ref, {
              'heureDebut': '$startH:$startM',
              'heureFin': '$endH:$endM',
              'disponible': true,
              'dateJour': Timestamp.fromDate(dateOnly),
              'medecin_id': medRef,
            });
          }

          currentMinutes = nextMin;
        }
      }
    }

    await batch.commit();
  }

  /// Duplicates all availability slots from one week to another.
  /// Clears the target week first to prevent duplicates.
  Future<void> duplicateWeekAvailability({
    required String medecinId,
    required DateTime sourceWeekStart, // Monday of source
    required DateTime targetWeekStart, // Monday of target
  }) async {
    final medRef = _db.doc('medecin/$medecinId');
    final sourceEnd = sourceWeekStart.add(const Duration(days: 7));

    // 0. Cleanup target week first
    final List<DateTime> targetDates = [];
    for (int i = 0; i < 7; i++) {
      targetDates.add(targetWeekStart.add(Duration(days: i)));
    }
    
    final batch = _db.batch();
    await _cleanupSlotsAndCancelRDVs(medecinId, targetDates, batch);

    // 1. Get all slots for that doctor in the source week
    final snapshot = await _db
        .collection('creneaux')
        .where('medecin_id', isEqualTo: medRef)
        .where('dateJour', isGreaterThanOrEqualTo: Timestamp.fromDate(sourceWeekStart))
        .where('dateJour', isLessThan: Timestamp.fromDate(sourceEnd))
        .get();

    if (snapshot.docs.isEmpty) {
      await batch.commit();
      return;
    }

    final difference = targetWeekStart.difference(sourceWeekStart).inDays;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final sourceDate = (data['dateJour'] as Timestamp).toDate();
      final targetDate = sourceDate.add(Duration(days: difference));

      final newRef = _db.collection('creneaux').doc();
      batch.set(newRef, {
        ...data,
        'dateJour': Timestamp.fromDate(targetDate),
        'disponible': true, // Always reset to available when duplicating
      });
    }

    await batch.commit();
  }

  /// Get doctor data
  Future<Map<String, dynamic>?> getMedecinData(String id) async {
    final doc = await _db.collection('medecin').doc(id).get();
    return doc.data();
  }

  /// Deletes all slots for the given dates.
  /// If a slot is reserved, the associated appointment is marked as 'annule'.
  Future<void> bulkDeleteCreneaux({
    required String medecinId,
    required List<DateTime> dates,
  }) async {
    final batch = _db.batch();
    await _cleanupSlotsAndCancelRDVs(medecinId, dates, batch);
    await batch.commit();
  }

  /// Internal helper to delete slots and cancel RDVs for multiple dates.
  Future<void> _cleanupSlotsAndCancelRDVs(String medecinId, List<DateTime> dates, WriteBatch batch) async {
    final medRef = _db.doc('medecin/$medecinId');
    
    // Fetch all slots for this doctor to filter in memory
    // This avoids the failed-precondition (missing index) error on composite queries.
    final snapshot = await _db.collection('creneaux')
        .where('medecin_id', isEqualTo: medRef)
        .get();

    final dateKeys = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateValue = (data['dateJour'] as Timestamp?)?.toDate();
      if (dateValue == null) continue;
      
      final dateOnly = DateTime(dateValue.year, dateValue.month, dateValue.day);
      if (!dateKeys.contains(dateOnly)) continue;

      if (data['disponible'] == false) {
        // Find and cancel associated RDV
        final rdvTime = _parseDateTime(dateOnly, data['heureDebut']);
        if (rdvTime != null) {
          final query = await _db.collection('rendezvous')
              .where('medecin_id', isEqualTo: medRef)
              .where('dateHeure', isEqualTo: Timestamp.fromDate(rdvTime))
              .get();
          for (var rdvDoc in query.docs) {
            batch.update(rdvDoc.reference, {
              'statut': 'annule',
              'notes': 'Annulé automatiquement suite à un changement de planning ou indisponibilité.',
            });
          }
        }
      }
      batch.delete(doc.reference);
    }
  }

  DateTime? _parseDateTime(DateTime date, String hStr) {
    try {
      final parts = hStr.split(':');
      return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }
}
