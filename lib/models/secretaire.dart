import 'package:cloud_firestore/cloud_firestore.dart';

/// Secretary model — maps to the `secretaire` Firestore collection.
/// References a `utilisateur` document via `utilisateur_id`
/// and the doctor they work for via `medecin_id`.
class Secretaire {
  final String id;
  final String cin;
  final bool actif;
  final String utilisateurId; // reference to /utilisateur/{id}
  final String medecinId;     // reference to /medecin/{id}

  Secretaire({
    required this.id,
    required this.cin,
    required this.actif,
    required this.utilisateurId,
    required this.medecinId,
  });

  factory Secretaire.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Secretaire(
      id: doc.id,
      cin: data['cin'] ?? '',
      actif: data['actif'] ?? false,
      utilisateurId: data['utilisateur_id'] ?? '',
      medecinId: data['medecin_id'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cin': cin,
      'actif': actif,
      'utilisateur_id': utilisateurId,
      'medecin_id': medecinId,
    };
  }
}

