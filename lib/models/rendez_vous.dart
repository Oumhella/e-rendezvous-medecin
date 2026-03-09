import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Appointment model — maps to the `rendezVous` Firestore collection.
class RendezVous {
  final String id;
  final DateTime? dateHeure;
  final TypeVisite typeVisite;
  final StatutRDV statut;
  final String notes;
  final String motif;
  final bool rappelEnvoye;
  final DateTime? dateReservation;
  final String medecinId;  // reference to /medecin/{id}
  final String patientId;  // reference to /patient/{id}

  RendezVous({
    required this.id,
    this.dateHeure,
    this.typeVisite = TypeVisite.cabinet,
    this.statut = StatutRDV.enAttente,
    this.notes = '',
    this.motif = '',
    this.rappelEnvoye = false,
    this.dateReservation,
    this.medecinId = '',
    this.patientId = '',
  });

  factory RendezVous.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RendezVous(
      id: doc.id,
      dateHeure: data['dateHeure'] is Timestamp 
          ? (data['dateHeure'] as Timestamp).toDate() 
          : null,
      typeVisite: enumFromString(
        TypeVisite.values,
        data['typeVisite'] ?? 'cabinet',
      ),
      statut: enumFromString(
        StatutRDV.values,
        data['statut'] ?? 'enAttente',
      ),
      notes: data['note'] ?? data['notes'] ?? '',
      motif: data['motif'] ?? data['note'] ?? '',
      rappelEnvoye: data['rappelEnvoye'] ?? false,
      dateReservation: data['dateReservation'] is Timestamp
          ? (data['dateReservation'] as Timestamp).toDate()
          : null,
      medecinId: data['medecin_id'] is DocumentReference
          ? (data['medecin_id'] as DocumentReference).id
          : (data['medecin_id']?.toString().trim() ?? ''),
      patientId: data['patient_id'] is DocumentReference
          ? (data['patient_id'] as DocumentReference).id
          : (data['patient_id']?.toString().trim() ?? ''),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dateHeure':
          dateHeure != null ? Timestamp.fromDate(dateHeure!) : null,
      'typeVisite': enumToString(typeVisite),
      'statut': enumToString(statut),
      'notes': notes,
      'motif': motif,
      'rappelEnvoye': rappelEnvoye,
      'dateReservation': dateReservation != null
          ? Timestamp.fromDate(dateReservation!)
          : FieldValue.serverTimestamp(),
      'medecin_id': FirebaseFirestore.instance.doc('medecin/$medecinId'),
      'patient_id': FirebaseFirestore.instance.doc('patient/$patientId'),
    };
  }

  /// Creates a copy with some fields changed.
  RendezVous copyWith({
    String? id,
    DateTime? dateHeure,
    TypeVisite? typeVisite,
    StatutRDV? statut,
    String? notes,
    String? motif,
    bool? rappelEnvoye,
    DateTime? dateReservation,
    String? medecinId,
    String? patientId,
  }) {
    return RendezVous(
      id: id ?? this.id,
      dateHeure: dateHeure ?? this.dateHeure,
      typeVisite: typeVisite ?? this.typeVisite,
      statut: statut ?? this.statut,
      notes: notes ?? this.notes,
      motif: motif ?? this.motif,
      rappelEnvoye: rappelEnvoye ?? this.rappelEnvoye,
      dateReservation: dateReservation ?? this.dateReservation,
      medecinId: medecinId ?? this.medecinId,
      patientId: patientId ?? this.patientId,
    );
  }
}
