import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String nom;
  final String prenom;
  final String specialite;
  final double noteMoyenne;
  final String adresseCabinet;
  final String telephone;
  final bool actif;
  final bool consultationEnLigne;
  final int anneesExperience;
  final String biographies;
  final String certificatExercice;
  final String cin;
  final String cv;
  final Timestamp dateValidationCompte;
  final String diplome;
  final int dureConsultationMin;
  final double latitude;
  final double longitude;
  final List<String> disponibilites;

  Doctor({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.specialite,
    required this.noteMoyenne,
    required this.adresseCabinet,
    required this.telephone,
    required this.actif,
    required this.consultationEnLigne,
    required this.anneesExperience,
    required this.biographies,
    required this.certificatExercice,
    required this.cin,
    required this.cv,
    required this.dateValidationCompte,
    required this.diplome,
    required this.dureConsultationMin,
    required this.latitude,
    required this.longitude,
    required this.disponibilites,
  });

  String get fullName => 'Dr. $prenom $nom';
  String get noteText => '${noteMoyenne.toStringAsFixed(1)}';
  String get tarifText => '${dureConsultationMin * 2}€'; // Estimation basée sur la durée
  String get experienceText => '$anneesExperience ans d\'expérience';

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      specialite: json['specialite'] ?? '',
      noteMoyenne: (json['noteMoyenne'] ?? 0.0).toDouble(),
      adresseCabinet: json['adresseCabinet'] ?? '',
      telephone: json['telephone'] ?? '',
      actif: json['actif'] ?? false,
      consultationEnLigne: json['consultationEnLigne'] ?? false,
      anneesExperience: json['anneesExperience'] ?? 0,
      biographies: json['biographies'] ?? '',
      certificatExercice: json['certificatExercice'] ?? '',
      cin: json['cin'] ?? '',
      cv: json['cv'] ?? '',
      dateValidationCompte: json['dateValidationCompte'] is Timestamp 
          ? json['dateValidationCompte'] as Timestamp
          : Timestamp.now(),
      diplome: json['diplome'] ?? '',
      dureConsultationMin: json['dureConsultationMin'] ?? 30,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      disponibilites: List<String>.from(json['disponibilites'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'specialite': specialite,
      'noteMoyenne': noteMoyenne,
      'adresseCabinet': adresseCabinet,
      'telephone': telephone,
      'actif': actif,
      'consultationEnLigne': consultationEnLigne,
      'anneesExperience': anneesExperience,
      'biographies': biographies,
      'certificatExercice': certificatExercice,
      'cin': cin,
      'cv': cv,
      'dateValidationCompte': dateValidationCompte,
      'diplome': diplome,
      'dureConsultationMin': dureConsultationMin,
      'latitude': latitude,
      'longitude': longitude,
      'disponibilites': disponibilites,
    };
  }

  // Pour la compatibilité avec l'interface existante
  double get note => noteMoyenne;
  int get nombreAvis => 0; // À calculer depuis une collection avis séparée
  String get adresse => adresseCabinet;
  String get ville => _extractVille(adresseCabinet);
  double get distance => _calculateDistance();
  String get distanceText => '${distance.toStringAsFixed(1)} km';
  bool get disponibleAujourdhui => actif;
  int get tarif => dureConsultationMin * 2; // Estimation
  String get secteur => _determineSecteur();
  bool get consultationPresentiel => true;
  bool get consultationTele => consultationEnLigne;
  String? get photoUrl => null; // Pas de photo dans la structure actuelle

  String _extractVille(String adresse) {
    // Extraire la ville de l'adresse (logique simple)
    if (adresse.contains('Paris')) {
      final match = RegExp(r'Paris (\d+)[eè]me').firstMatch(adresse);
      return match != null ? 'Paris ${match.group(1)}ème' : 'Paris';
    }
    return 'France';
  }

  double _calculateDistance() {
    // Simulation de distance (à remplacer avec un vrai calcul GPS)
    return (latitude + longitude).abs() % 10 + 1;
  }

  String _determineSecteur() {
    // Logique pour déterminer le secteur selon la localisation
    if (adresseCabinet.contains('Paris 7') || adresseCabinet.contains('Paris 8')) {
      return 'Secteur 1';
    } else if (adresseCabinet.contains('Paris 13') || adresseCabinet.contains('Paris 14')) {
      return 'Secteur 2';
    }
    return 'Secteur 3';
  }
}
