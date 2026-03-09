import 'package:cloud_firestore/cloud_firestore.dart';

/// Patient model — maps to the `patient` Firestore collection.
class Patient {
  final String id;
  final String cin;
  final DateTime? dateNaissance;
  final DateTime? dateInscription;
  final String adresse;
  final String numeroSecuriteSociale;
  final bool actif;
  final String utilisateurId; // reference to /utilisateur/{id}

  Patient({
    required this.id,
    this.cin = '',
    this.dateNaissance,
    this.dateInscription,
    this.adresse = '',
    this.numeroSecuriteSociale = '',
    this.actif = true,
    this.utilisateurId = '',
  });

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Patient(
      id: doc.id,
      cin: data['cin'] ?? '',
      dateNaissance: (data['dateNaissance'] as Timestamp?)?.toDate(),
      dateInscription: (data['dateInscription'] as Timestamp?)?.toDate(),
      adresse: data['adresse'] ?? '',
      numeroSecuriteSociale: data['numeroSecuriteSociale'] ?? '',
      actif: data['actif'] ?? true,
      utilisateurId: data['utilisateur_id'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cin': cin,
      'dateNaissance':
          dateNaissance != null ? Timestamp.fromDate(dateNaissance!) : null,
      'dateInscription': dateInscription != null
          ? Timestamp.fromDate(dateInscription!)
          : FieldValue.serverTimestamp(),
      'adresse': adresse,
      'numeroSecuriteSociale': numeroSecuriteSociale,
      'actif': actif,
      'utilisateur_id': utilisateurId,
    };
  }
}
