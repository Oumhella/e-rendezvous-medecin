import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Doctor model — maps to the `medecin` Firestore collection.
class Medecin {
  final String id;
  final String cin;
  final String numeroDordre;
  final String adresseCabinet;
  final String ville;
  final StatutMedecin statutMedecin;
  final String cv;
  final String diplome;
  final String certificatExercice;
  final int dureeConsultationMin;
  final double tarifConsultation;
  final double noteMoyenne;
  final String biographie;
  final int anneesExperience;
  final bool consultationEnLigne;
  final DateTime? dateValidationCompte;
  final String utilisateurId; // reference to /utilisateur/{id}
  final String specialiteId; // reference to /specialite/{id}

  Medecin({
    required this.id,
    this.cin = '',
    this.numeroDordre = '',
    this.adresseCabinet = '',
    this.ville = '',
    this.statutMedecin = StatutMedecin.enAttenteValidation,
    this.cv = '',
    this.diplome = '',
    this.certificatExercice = '',
    this.dureeConsultationMin = 30,
    this.tarifConsultation = 0,
    this.noteMoyenne = 0,
    this.biographie = '',
    this.anneesExperience = 0,
    this.consultationEnLigne = false,
    this.dateValidationCompte,
    this.utilisateurId = '',
    this.specialiteId = '',
  });

  factory Medecin.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medecin(
      id: doc.id,
      cin: data['cin'] ?? '',
      numeroDordre: data['numeroDordre'] ?? '',
      adresseCabinet: data['adresseCabinet'] ?? '',
      ville: data['ville'] ?? '',
      statutMedecin: enumFromString(
        StatutMedecin.values,
        data['statutMedecin'] ?? 'enAttenteValidation',
      ),
      cv: data['cv'] ?? '',
      diplome: data['diplome'] ?? '',
      certificatExercice: data['certificatExercice'] ?? '',
      dureeConsultationMin: data['dureeConsultationMin'] ?? 30,
      tarifConsultation: (data['tarifConsultation'] ?? 0).toDouble(),
      noteMoyenne: (data['noteMoyenne'] ?? 0).toDouble(),
      biographie: data['biographie'] ?? '',
      anneesExperience: data['anneesExperience'] ?? 0,
      consultationEnLigne: data['consultationEnLigne'] ?? false,
      dateValidationCompte:
          (data['dateValidationCompte'] as Timestamp?)?.toDate(),
      utilisateurId: data['utilisateur_id'] ?? '',
      specialiteId: data['specialite_id'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cin': cin,
      'numeroDordre': numeroDordre,
      'adresseCabinet': adresseCabinet,
      'ville': ville,
      'statutMedecin': enumToString(statutMedecin),
      'cv': cv,
      'diplome': diplome,
      'certificatExercice': certificatExercice,
      'dureeConsultationMin': dureeConsultationMin,
      'tarifConsultation': tarifConsultation,
      'noteMoyenne': noteMoyenne,
      'biographie': biographie,
      'anneesExperience': anneesExperience,
      'consultationEnLigne': consultationEnLigne,
      'dateValidationCompte': dateValidationCompte != null
          ? Timestamp.fromDate(dateValidationCompte!)
          : null,
      'utilisateur_id': utilisateurId,
      'specialite_id': specialiteId,
    };
  }
}
