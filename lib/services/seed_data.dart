import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Seeds Firestore (and Firebase Auth) with test data so the secretary
/// flow can be tested immediately.
///
/// Call [seedTestData] once — it checks for an existing flag document
/// (`_meta/seeded`) so it won't duplicate data on subsequent runs.
class SeedData {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Main entry point – safe to call repeatedly.
  static Future<void> seedTestData() async {
    // Check if already seeded
    final metaDoc = await _db.collection('_meta').doc('seeded').get();
    if (metaDoc.exists) {
      debugPrint('✅ Test data already seeded — skipping.');
      return;
    }

    debugPrint('🌱 Seeding test data…');

    // ── 1. Create Firebase Auth users ──────────────────────────────
    await _createAuthUser(
      email: 'secretaire@test.com',
      password: 'test1234',
    );
    await _createAuthUser(
      email: 'medecin@test.com',
      password: 'test1234',
    );
    await _createAuthUser(
      email: 'patient@test.com',
      password: 'test1234',
    );

    // ── 2. Utilisateurs ────────────────────────────────────────────
    final secUserId = 'user_secretaire_01';
    final medUserId = 'user_medecin_01';
    final patUserId = 'user_patient_01';

    await _db.collection('utilisateur').doc(secUserId).set({
      'nom': 'Benali',
      'prenom': 'Fatima',
      'email': 'secretaire@test.com',
      'telephone': '0612345678',
      'motDePasse': '',
      'dateInscription': FieldValue.serverTimestamp(),
    });

    await _db.collection('utilisateur').doc(medUserId).set({
      'nom': 'El Amrani',
      'prenom': 'Youssef',
      'email': 'medecin@test.com',
      'telephone': '0698765432',
      'motDePasse': '',
      'dateInscription': FieldValue.serverTimestamp(),
    });

    await _db.collection('utilisateur').doc(patUserId).set({
      'nom': 'Tazi',
      'prenom': 'Ahmed',
      'email': 'patient@test.com',
      'telephone': '0655443322',
      'motDePasse': '',
      'dateInscription': FieldValue.serverTimestamp(),
    });

    // Extra patient
    final patUserId2 = 'user_patient_02';
    await _db.collection('utilisateur').doc(patUserId2).set({
      'nom': 'Moussaoui',
      'prenom': 'Salma',
      'email': 'patient2@test.com',
      'telephone': '0677889900',
      'motDePasse': '',
      'dateInscription': FieldValue.serverTimestamp(),
    });

    // ── 3. Spécialité ──────────────────────────────────────────────
    final specId = 'spec_01';
    await _db.collection('specialite').doc(specId).set({
      'nom': 'Médecine Générale',
      'description': 'Consultation de médecine générale',
      'codeSpecialite': 'MG',
    });

    final specId2 = 'spec_02';
    await _db.collection('specialite').doc(specId2).set({
      'nom': 'Cardiologie',
      'description': 'Spécialiste des maladies cardiovasculaires',
      'codeSpecialite': 'CARDIO',
    });

    final specId3 = 'spec_03';
    await _db.collection('specialite').doc(specId3).set({
      'nom': 'Pédiatrie',
      'description': 'Spécialiste des enfants et adolescents',
      'codeSpecialite': 'PEDIA',
    });

    final specId4 = 'spec_04';
    await _db.collection('specialite').doc(specId4).set({
      'nom': 'Dermatologie',
      'description': 'Spécialiste des maladies de la peau',
      'codeSpecialite': 'DERMATO',
    });

    final specId5 = 'spec_05';
    await _db.collection('specialite').doc(specId5).set({
      'nom': 'Gynécologie',
      'description': 'Spécialiste de la santé feminine',
      'codeSpecialite': 'GYNECO',
    });

    // ── 4. Secrétaire & Médecin ────────────────────────────────────
    final medId = 'med_01';
    final medId2 = 'med_02';
    final medId3 = 'med_03';
    final medId4 = 'med_04';
    final medId5 = 'med_05';

    await _db.collection('secretaire').doc('sec_01').set({
      'cin': 'BK123456',
      'actif': true,
      'utilisateur_id': secUserId,
      'medecin_id': medId,
    });

    await _db.collection('medecin').doc(medId).set({
      'cin': 'AB654321',
      'numeroDordre': 'ORD-2024-001',
      'adresseCabinet': '12 Rue Mohammed V, Casablanca',
      'ville': 'Casablanca',
      'statutMedecin': 'valide',
      'cv': '',
      'diplome': 'Doctorat en Médecine',
      'certificatExercice': 'CE-2024-001',
      'dureeConsultationMin': 30,
      'tarifConsultation': 200.0,
      'noteMoyenne': 4.5,
      'biographie': 'Médecin généraliste avec 10 ans d\'expérience.',
      'anneesExperience': 10,
      'consultationEnLigne': true,
      'dateValidationCompte': Timestamp.now(),
      'utilisateur_id': medUserId,
      'specialite_id': specId,
    });

    // Médecin 2 - Cardiologue
    await _db.collection('medecin').doc(medId2).set({
      'cin': 'CD987654',
      'numeroDordre': 'ORD-2024-002',
      'adresseCabinet': '25 Boulevard Anfa, Casablanca',
      'ville': 'Casablanca',
      'statutMedecin': 'valide',
      'cv': '',
      'diplome': 'Doctorat en Cardiologie',
      'certificatExercice': 'CE-2024-002',
      'dureeConsultationMin': 45,
      'tarifConsultation': 350.0,
      'noteMoyenne': 4.8,
      'biographie': 'Cardiologue spécialisé en maladies cardiovasculaires.',
      'anneesExperience': 15,
      'consultationEnLigne': true,
      'dateValidationCompte': Timestamp.now(),
      'utilisateur_id': medUserId,
      'specialite_id': specId2,
    });

    // Médecin 3 - Pédiatre
    await _db.collection('medecin').doc(medId3).set({
      'cin': 'EF123456',
      'numeroDordre': 'ORD-2024-003',
      'adresseCabinet': '8 Rue des Jardins, Rabat',
      'ville': 'Rabat',
      'statutMedecin': 'valide',
      'cv': '',
      'diplome': 'Doctorat en Pédiatrie',
      'certificatExercice': 'CE-2024-003',
      'dureeConsultationMin': 25,
      'tarifConsultation': 180.0,
      'noteMoyenne': 4.6,
      'biographie': 'Pédiatre expérimenté pour les enfants de 0 à 18 ans.',
      'anneesExperience': 12,
      'consultationEnLigne': false,
      'dateValidationCompte': Timestamp.now(),
      'utilisateur_id': medUserId,
      'specialite_id': specId3,
    });

    // Médecin 4 - Dermatologue
    await _db.collection('medecin').doc(medId4).set({
      'cin': 'GH789012',
      'numeroDordre': 'ORD-2024-004',
      'adresseCabinet': '15 Avenue Hassan II, Marrakech',
      'ville': 'Marrakech',
      'statutMedecin': 'valide',
      'cv': '',
      'diplome': 'Doctorat en Dermatologie',
      'certificatExercice': 'CE-2024-004',
      'dureeConsultationMin': 30,
      'tarifConsultation': 250.0,
      'noteMoyenne': 4.4,
      'biographie': 'Dermatologue spécialisé en dermatologie esthétique.',
      'anneesExperience': 8,
      'consultationEnLigne': true,
      'dateValidationCompte': Timestamp.now(),
      'utilisateur_id': medUserId,
      'specialite_id': specId4,
    });

    // Médecin 5 - Gynécologue
    await _db.collection('medecin').doc(medId5).set({
      'cin': 'IJ345678',
      'numeroDordre': 'ORD-2024-005',
      'adresseCabinet': '5 Rue Moulay Youssef, Fès',
      'ville': 'Fès',
      'statutMedecin': 'valide',
      'cv': '',
      'diplome': 'Doctorat en Gynécologie',
      'certificatExercice': 'CE-2024-005',
      'dureeConsultationMin': 40,
      'tarifConsultation': 300.0,
      'noteMoyenne': 4.7,
      'biographie': 'Gynécologue-obstétricien avec expertise en suivi grossesse.',
      'anneesExperience': 20,
      'consultationEnLigne': true,
      'dateValidationCompte': Timestamp.now(),
      'utilisateur_id': medUserId,
      'specialite_id': specId5,
    });

    // ── 6. Patients ────────────────────────────────────────────────
    await _db.collection('patient').doc('pat_01').set({
      'cin': 'CD112233',
      'dateNaissance': Timestamp.fromDate(DateTime(1990, 5, 15)),
      'dateInscription': FieldValue.serverTimestamp(),
      'adresse': '45 Bd Zerktouni, Casablanca',
      'numeroSecuriteSociale': 'SS-990515-001',
      'actif': true,
      'utilisateur_id': patUserId,
    });

    await _db.collection('patient').doc('pat_02').set({
      'cin': 'EF445566',
      'dateNaissance': Timestamp.fromDate(DateTime(1985, 11, 22)),
      'dateInscription': FieldValue.serverTimestamp(),
      'adresse': '8 Av Hassan II, Rabat',
      'numeroSecuriteSociale': 'SS-851122-002',
      'actif': true,
      'utilisateur_id': patUserId2,
    });

    // ── 7. Créneaux horaires (today + tomorrow) ────────────────────
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    final slots = ['08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
                   '11:00', '14:00', '14:30', '15:00', '15:30', '16:00'];

    for (int i = 0; i < slots.length - 1; i += 1) {
      // Today slots
      await _db.collection('creneaux').add({
        'heureDebut': slots[i],
        'heureFin': _addMinutes(slots[i], 30),
        'disponible': true,
        'dateJour': Timestamp.fromDate(
            DateTime(today.year, today.month, today.day)),
        'medecin_id': medId,
      });
      // Tomorrow slots
      await _db.collection('creneaux').add({
        'heureDebut': slots[i],
        'heureFin': _addMinutes(slots[i], 30),
        'disponible': true,
        'dateJour': Timestamp.fromDate(
            DateTime(tomorrow.year, tomorrow.month, tomorrow.day)),
        'medecin_id': medId,
      });
    }

    // ── 8. Sample rendez-vous ──────────────────────────────────────
    await _db.collection('rendezVous').add({
      'dateHeure': Timestamp.fromDate(
          DateTime(today.year, today.month, today.day, 9, 0)),
      'typeVisite': 'cabinet',
      'statut': 'confirme',
      'notes': 'Contrôle de routine',
      'rappelEnvoye': false,
      'dateReservation': FieldValue.serverTimestamp(),
      'medecin_id': medId,
      'patient_id': 'pat_01',
    });

    await _db.collection('rendezVous').add({
      'dateHeure': Timestamp.fromDate(
          DateTime(today.year, today.month, today.day, 14, 30)),
      'typeVisite': 'teleconsultation',
      'statut': 'enAttente',
      'notes': 'Suivi post-opératoire',
      'rappelEnvoye': false,
      'dateReservation': FieldValue.serverTimestamp(),
      'medecin_id': medId,
      'patient_id': 'pat_02',
    });

    await _db.collection('rendezVous').add({
      'dateHeure': Timestamp.fromDate(
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0)),
      'typeVisite': 'domicile',
      'statut': 'enAttente',
      'notes': '',
      'rappelEnvoye': false,
      'dateReservation': FieldValue.serverTimestamp(),
      'medecin_id': medId,
      'patient_id': 'pat_01',
    });

    // ── Mark as seeded ─────────────────────────────────────────────
    await _db.collection('_meta').doc('seeded').set({
      'seededAt': FieldValue.serverTimestamp(),
      'description': 'Test data for secretary module',
    });

    // Sign out so the user lands on the login screen
    await _auth.signOut();

    debugPrint('✅ Test data seeded successfully!');
    debugPrint('   📧 Login: secretaire@test.com / test1234');
  }

  /// Helper: create a Firebase Auth user (skips if already exists).
  static Future<UserCredential?> _createAuthUser({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // User may already exist — that's fine
      debugPrint('   ℹ️ Auth user $email: $e');
      return null;
    }
  }

  /// Helper: add 30 minutes to a "HH:mm" string.
  static String _addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]) + minutes;
    final newHour = hour + minute ~/ 60;
    final newMinute = minute % 60;
    return '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}';
  }
}
