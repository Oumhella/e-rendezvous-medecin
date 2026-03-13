/// Status of a doctor's account validation
enum StatutMedecin {
  enAttenteValidation,
  valide,
  rejete,
  suspendu,
  bloque,
}

/// Status of an appointment (rendez-vous)
enum StatutRDV {
  confirme,
  annule,
  termine,
  absent,
}

/// Type of visit / consultation
enum TypeVisite {
  cabinet,
  teleconsultation,
  domicile,
}

/// Status of a complaint (réclamation)
enum StatutReclamation {
  enAttente,
  enCours,
  resolue,
  rejetee,
}

/// Type of notification
enum TypeNotification {
  confirmation,
  rappel,
  annulation,
  modification,
}

// ── Helpers ──────────────────────────────────────────────────────────

/// Convert an enum value to a Firestore-friendly string (e.g. StatutRDV.confirme → "confirme")
String enumToString(Object enumValue) => enumValue.toString().split('.').last;

/// Parse a Firestore string back to the matching enum value.
T enumFromString<T>(List<T> values, String value) {
  final cleanValue = value.trim().toLowerCase().replaceAll('é', 'e').replaceAll('è', 'e').replaceAll('à', 'a').replaceAll(' ', '');
  return values.firstWhere(
    (e) => e.toString().split('.').last.toLowerCase() == cleanValue,
    orElse: () => values.first,
  );
}
