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
  final int tarifConsultationFromDB;
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
    required this.tarifConsultationFromDB,
    required this.latitude,
    required this.longitude,
    required this.disponibilites,
  });

  String get fullName => 'Dr. $prenom $nom';
  String get noteText => '${noteMoyenne.toStringAsFixed(1)}';
  String get experienceText => '$anneesExperience ans d\'expérience';

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // Gérer le cas où specialite_id est une DocumentReference
    String specialite = 'Généraliste';
    if (json['specialite'] != null) {
      specialite = json['specialite'].toString();
    } else if (json['specialite_id'] != null) {
      final specialiteRef = json['specialite_id'];
      if (specialiteRef is String && specialiteRef.isNotEmpty) {
        specialite = specialiteRef;
      }
    }
    
    return Doctor(
      id: json['id'] ?? json['utilisateur_id'] ?? '',
      nom: json['nom'] ?? 'Médecin',
      prenom: json['prenom'] ?? '',
      specialite: specialite,
      noteMoyenne: (json['noteMoyenne'] ?? 4.0).toDouble(),
      adresseCabinet: json['adresseCabinet'] ?? json['adresse'] ?? 'Adresse non spécifiée',
      telephone: json['telephone'] ?? '',
      actif: json['actif'] ?? true,
      consultationEnLigne: json['consultationEnLigne'] ?? false,
      anneesExperience: json['anneesExperience'] ?? 0,
      biographies: json['biographies'] ?? json['biographie'] ?? '',
      certificatExercice: json['certificatExercice'] ?? '',
      cin: json['cin'] ?? '',
      cv: json['cv'] ?? '',
      dateValidationCompte: json['dateValidationCompte'] is Timestamp 
          ? json['dateValidationCompte'] as Timestamp
          : Timestamp.now(),
      diplome: json['diplome'] ?? '',
      dureConsultationMin: json['dureConsultationMin'] ?? json['dureeConsultationMin'] ?? 30,
      tarifConsultationFromDB: json['tarifConsultation'] ?? 0,
      latitude: (json['latitude'] ?? 33.5731).toDouble(), // Casablanca par défaut
      longitude: (json['longitude'] ?? -7.5898).toDouble(),
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
      'tarifConsultation': tarifConsultationFromDB,
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
  int get tarif => tarifConsultationFromDB > 0 ? tarifConsultationFromDB : dureConsultationMin * 2; // Utilise la vraie valeur ou estimation
  int get tarifConsultation => tarif; // Alias pour la compatibilité
  String get tarifText => '$tarif DH'; // Affiche le tarif réel en DH
  String get secteur => _determineSecteur();
  bool get consultationPresentiel => true;
  bool get consultationTele => consultationEnLigne;
  String? get photoUrl => null; // Pas de photo dans la structure actuelle

  String _extractVille(String adresse) {
    // Extraire la ville de l'adresse (logique simple)
    if (adresse.contains('Paris')) {
      final match = RegExp(r'Paris (\d+)[eè]me').firstMatch(adresse);
      return match != null ? 'Paris ${match.group(1)}ème' : 'Paris';
    } else if (adresse.contains('Casablanca')) {
      return 'Casablanca';
    } else if (adresse.contains('Rabat')) {
      return 'Rabat';
    } else if (adresse.isNotEmpty) {
      return adresse.split(',').last.trim();
    }
    return 'Maroc';
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
