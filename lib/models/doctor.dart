class Doctor {
  final String id;
  final String nom;
  final String prenom;
  final String specialite;
  final double note;
  final int nombreAvis;
  final String adresse;
  final String ville;
  final double distance;
  final bool disponibleAujourdhui;
  final int tarif;
  final String secteur;
  final bool consultationPresentiel;
  final bool consultationTele;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final List<String> disponibilites;

  Doctor({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.specialite,
    required this.note,
    required this.nombreAvis,
    required this.adresse,
    required this.ville,
    required this.distance,
    required this.disponibleAujourdhui,
    required this.tarif,
    required this.secteur,
    required this.consultationPresentiel,
    required this.consultationTele,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.disponibilites,
  });

  String get fullName => 'Dr. $prenom $nom';
  String get tarifText => '$tarif€';
  String get distanceText => '${distance.toStringAsFixed(1)} km';
  String get noteText => '$note ($nombreAvis avis)';

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      specialite: json['specialite'] ?? '',
      note: (json['note'] ?? 0.0).toDouble(),
      nombreAvis: json['nombreAvis'] ?? 0,
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      distance: (json['distance'] ?? 0.0).toDouble(),
      disponibleAujourdhui: json['disponibleAujourdhui'] ?? false,
      tarif: json['tarif'] ?? 0,
      secteur: json['secteur'] ?? '',
      consultationPresentiel: json['consultationPresentiel'] ?? false,
      consultationTele: json['consultationTele'] ?? false,
      photoUrl: json['photoUrl'],
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
      'note': note,
      'nombreAvis': nombreAvis,
      'adresse': adresse,
      'ville': ville,
      'distance': distance,
      'disponibleAujourdhui': disponibleAujourdhui,
      'tarif': tarif,
      'secteur': secteur,
      'consultationPresentiel': consultationPresentiel,
      'consultationTele': consultationTele,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'disponibilites': disponibilites,
    };
  }
}
