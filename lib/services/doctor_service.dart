import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/doctor.dart';

class DoctorService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<List<Doctor>> getDoctors({
    String? specialite,
    String? query,
    String? disponibilite,
    String? typeConsultation,
    String? secteur,
    String? tarifConsultation,
    double? noteMin,
  }) async {
    try {
      // D'abord essayer sans filtre pour voir si la collection existe
      QuerySnapshot allDocs = await _db.collection('medecin').get();
      print('Total documents dans collection medecin: ${allDocs.docs.length}');
      
      // Ensuite essayer SANS le filtre actif pour éviter l'erreur d'index
      QuerySnapshot querySnapshot = await _db.collection('medecin').get();

      print('Documents récupérés sans filtre: ${querySnapshot.docs.length}');
      
      List<Doctor> doctors = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Données brutes: $data');
        data['id'] = doc.id; // Ajouter l'ID du document
        return Doctor.fromJson(data);
      }).toList();

      print('Médecins convertis: ${doctors.length}');

      // Appliquer les filtres
      List<Doctor> filteredDoctors = _applyFilters(
        doctors,
        specialite: specialite,
        query: query,
        disponibilite: disponibilite,
        typeConsultation: typeConsultation,
        secteur: secteur,
        tarifConsultation: tarifConsultation,
        noteMin: noteMin,
      );

      return filteredDoctors;
    } catch (e) {
      print('Erreur lors de la récupération des médecins: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      // Ne PAS retourner les données mockées pour voir l'erreur réelle
      rethrow;
    }
  }

  static List<Doctor> _applyFilters(
    List<Doctor> doctors, {
    String? specialite,
    String? query,
    String? disponibilite,
    String? typeConsultation,
    String? secteur,
    String? tarifConsultation,
    double? noteMin,
  }) {
    List<Doctor> filteredDoctors = List.from(doctors);

    if (specialite != null && specialite.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((d) =>
        d.specialite.toLowerCase().contains(specialite.toLowerCase())
      ).toList();
    }

    if (query != null && query.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((d) =>
        d.fullName.toLowerCase().contains(query.toLowerCase()) ||
        d.specialite.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    if (disponibilite == 'Aujourd\'hui') {
      filteredDoctors = filteredDoctors.where((d) => d.actif).toList();
    }

    if (typeConsultation == 'Présentiel') {
      filteredDoctors = filteredDoctors.where((d) => true).toList(); // Tous les médecins font présentiel
    } else if (typeConsultation == 'Téléconsultation') {
      filteredDoctors = filteredDoctors.where((d) => d.consultationEnLigne).toList();
    }

    if (secteur != null && secteur.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((d) => d.secteur == secteur).toList();
    }

    if (tarifConsultation != null) {
      if (tarifConsultation == '< 100') {
        filteredDoctors = filteredDoctors.where((d) => d.tarif < 100).toList();
      } else if (tarifConsultation == '100-300') {
        filteredDoctors = filteredDoctors.where((d) => d.tarif >= 100 && d.tarif <= 300).toList();
      } else if (tarifConsultation == '300+') {
        filteredDoctors = filteredDoctors.where((d) => d.tarif > 300).toList();
      }
    }

    if (noteMin != null) {
      filteredDoctors = filteredDoctors.where((d) => d.noteMoyenne >= noteMin).toList();
    }

    return filteredDoctors;
  }

  static List<Doctor> _getMockDoctors() {
    return [
      Doctor(
        id: '1',
        nom: 'Martin',
        prenom: 'Sophie',
        specialite: 'Cardiologue',
        noteMoyenne: 4.8,
        adresseCabinet: '15 Rue de la Santé, Paris 15ème',
        telephone: '0145678901',
        actif: true,
        consultationEnLigne: true,
        anneesExperience: 12,
        biographies: 'Cardiologue expérimentée spécialisée en maladies cardiovasculaires',
        certificatExercice: 'certificats/martin_sophie.pdf',
        cin: 'AB123456',
        cv: 'cv/martin_sophie.pdf',
        dateValidationCompte: Timestamp.fromDate(DateTime(2020, 1, 15)),
        diplome: 'diplomes/martin_sophie.pdf',
        dureConsultationMin: 30,
        tarifConsultationFromDB: 150,
        latitude: 48.8466,
        longitude: 2.2860,
        disponibilites: ['Lundi 14h-18h', 'Mercredi 9h-12h', 'Vendredi 14h-18h'],
      ),
      Doctor(
        id: '2',
        nom: 'Dubois',
        prenom: 'Pierre',
        specialite: 'Généraliste',
        noteMoyenne: 4.5,
        adresseCabinet: '23 Avenue des Champs-Élysées, Paris 8ème',
        telephone: '0145678902',
        actif: true,
        consultationEnLigne: false,
        anneesExperience: 8,
        biographies: 'Médecin généraliste avec approche holistique',
        certificatExercice: 'certificats/dubois_pierre.pdf',
        cin: 'CD234567',
        cv: 'cv/dubois_pierre.pdf',
        dateValidationCompte: Timestamp.fromDate(DateTime(2019, 3, 20)),
        diplome: 'diplomes/dubois_pierre.pdf',
        dureConsultationMin: 20,
        tarifConsultationFromDB: 100,
        latitude: 48.8708,
        longitude: 2.3020,
        disponibilites: ['Lundi 8h-12h', 'Mardi 14h-18h', 'Jeudi 8h-12h'],
      ),
      Doctor(
        id: '3',
        nom: 'Bernard',
        prenom: 'Marie',
        specialite: 'Dermatologue',
        noteMoyenne: 4.9,
        adresseCabinet: '5 Rue du Faubourg Saint-Honoré, Paris 8ème',
        telephone: '0145678903',
        actif: false, // Inactive pour tester
        consultationEnLigne: true,
        anneesExperience: 15,
        biographies: 'Dermatologue spécialisée en médecine esthétique',
        certificatExercice: 'certificats/bernard_marie.pdf',
        cin: 'EF345678',
        cv: 'cv/bernard_marie.pdf',
        dateValidationCompte: Timestamp.fromDate(DateTime(2018, 6, 10)),
        diplome: 'diplomes/bernard_marie.pdf',
        dureConsultationMin: 25,
        tarifConsultationFromDB: 180,
        latitude: 48.8682,
        longitude: 2.3164,
        disponibilites: ['Mardi 9h-13h', 'Jeudi 14h-18h', 'Vendredi 9h-13h'],
      ),
    ];
  }

  static Future<void> addDoctor(Doctor doctor) async {
    try {
      await _db.collection('medecin').add(doctor.toJson());
    } catch (e) {
      print('Erreur lors de l\'ajout du médecin: $e');
      throw e;
    }
  }

  static Future<void> initializeMockData() async {
    try {
      print('Début initialisation des données mockées...');
      
      // Vérifier si la collection est vide
      QuerySnapshot snapshot = await _db.collection('medecin').limit(1).get();
      print('Documents existants: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('Collection vide, ajout des données mockées...');
        // Ajouter les données mockées
        List<Doctor> mockDoctors = _getMockDoctors();
        
        for (Doctor doctor in mockDoctors) {
          Map<String, dynamic> doctorData = doctor.toJson();
          doctorData.remove('id'); // Firestore génère l'ID
          print('Ajout du médecin: ${doctor.fullName}');
          await _db.collection('medecin').add(doctorData);
        }
        
        print('Données mockées initialisées avec succès');
      } else {
        print('Collection contient déjà des données');
        // Afficher les données existantes
        for (var doc in snapshot.docs) {
          print('Document existant: ${doc.id} -> ${doc.data()}');
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des données: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      rethrow;
    }
  }

  static List<String> getSpecialites() {
    return ['Généraliste', 'Cardiologue', 'Dermatologue', 'Pédiatre', 'Gynécologue', 'Ophtalmologue', 'Psychiatre'];
  }

  static List<String> getSecteurs() {
    return ['Secteur 1', 'Secteur 2', 'Secteur 3'];
  }

  // ── MÉTHODES DE SEED DATA MERGEES ──────────────────────────────────────

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

    // ── 4. Secrétaire & Médecin ────────────────────────────────────
    final medId = 'med_01';

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

    // ── 5. Patients ────────────────────────────────────────────────
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

    // ── 6. Créneaux horaires (today + tomorrow) ────────────────────
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

    // ── 7. Sample rendez-vous ──────────────────────────────────────
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
