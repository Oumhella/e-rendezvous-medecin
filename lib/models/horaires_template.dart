import 'package:cloud_firestore/cloud_firestore.dart';

class HorairesTemplate {
  final String id;
  final String nom;
  final String medecinId;
  final List<TemplateInterval> intervalles;

  HorairesTemplate({
    required this.id,
    required this.nom,
    required this.medecinId,
    required this.intervalles,
  });

  factory HorairesTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HorairesTemplate(
      id: doc.id,
      nom: data['nom'] ?? '',
      medecinId: data['medecin_id'] is DocumentReference
          ? (data['medecin_id'] as DocumentReference).id
          : (data['medecin_id']?.toString() ?? ''),
      intervalles: (data['intervalles'] as List<dynamic>?)
              ?.map((i) => TemplateInterval.fromMap(i))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'medecin_id': FirebaseFirestore.instance.doc('medecin/$medecinId'),
      'intervalles': intervalles.map((i) => i.toMap()).toList(),
    };
  }
}

class TemplateInterval {
  final String heureDebut;
  final String heureFin;

  TemplateInterval({
    required this.heureDebut,
    required this.heureFin,
  });

  factory TemplateInterval.fromMap(Map<String, dynamic> map) {
    return TemplateInterval(
      heureDebut: map['heureDebut'] ?? '',
      heureFin: map['heureFin'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'heureDebut': heureDebut,
      'heureFin': heureFin,
    };
  }
}
