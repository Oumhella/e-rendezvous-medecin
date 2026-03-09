import 'package:cloud_firestore/cloud_firestore.dart';

/// Base user model — maps to the `utilisateur` Firestore collection.
class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final DateTime? dateInscription;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.dateInscription,
  });

  factory Utilisateur.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Utilisateur(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      telephone: data['telephone'] ?? '',
      dateInscription: (data['dateInscription'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'dateInscription': dateInscription != null
          ? Timestamp.fromDate(dateInscription!)
          : FieldValue.serverTimestamp(),
    };
  }

  String get nomComplet => '$prenom $nom';
}
