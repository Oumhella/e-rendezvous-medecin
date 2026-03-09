import 'package:cloud_firestore/cloud_firestore.dart';

/// Time-slot model — maps to the `creneaux` Firestore collection.
class CreneauHoraire {
  final String id;
  final String heureDebut; // e.g. "09:00"
  final String heureFin;   // e.g. "09:30"
  final bool disponible;
  final DateTime? dateJour;
  final String medecinId; // reference to /medecin/{id}

  CreneauHoraire({
    required this.id,
    this.heureDebut = '',
    this.heureFin = '',
    this.disponible = true,
    this.dateJour,
    this.medecinId = '',
  });

  factory CreneauHoraire.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreneauHoraire(
      id: doc.id,
      heureDebut: data['heureDebut'] ?? '',
      heureFin: data['heureFin'] ?? '',
      disponible: data['disponible'] ?? true,
      dateJour: data['dateJour'] is Timestamp 
          ? (data['dateJour'] as Timestamp).toDate()
          : null,
      medecinId: data['medecin_id'] is DocumentReference
          ? (data['medecin_id'] as DocumentReference).id
          : (data['medecin_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'heureDebut': heureDebut,
      'heureFin': heureFin,
      'disponible': disponible,
      'dateJour':
          dateJour != null ? Timestamp.fromDate(dateJour!) : null,
      'medecin_id': medecinId,
    };
  }

  /// Checks if another time-slot can be placed without overlap.
  bool verifierChevauchement(CreneauHoraire autre) {
    return heureDebut.compareTo(autre.heureFin) < 0 &&
        heureFin.compareTo(autre.heureDebut) > 0;
  }
}
