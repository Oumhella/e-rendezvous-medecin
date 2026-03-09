import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor.dart';

class DoctorService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<Doctor>> getDoctors({
    String? specialite,
    String? query,
    String? disponibilite,
    String? typeConsultation,
    String? secteur,
    String? tarifRange,
    double? noteMin,
  }) async {
    try {
      // Récupérer tous les médecins depuis Firestore
      QuerySnapshot querySnapshot = await _db
          .collection('medecins')
          .orderBy('nom')
          .get();

      List<Doctor> doctors = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Ajouter l'ID du document
        return Doctor.fromJson(data);
      }).toList();

      // Appliquer les filtres
      List<Doctor> filteredDoctors = _applyFilters(
        doctors,
        specialite: specialite,
        query: query,
        disponibilite: disponibilite,
        typeConsultation: typeConsultation,
        secteur: secteur,
        tarifRange: tarifRange,
        noteMin: noteMin,
      );

      return filteredDoctors;
    } catch (e) {
      print('Erreur lors de la récupération des médecins: $e');
      // En cas d'erreur, retourner les données mockées
      return _getMockDoctors();
    }
  }

  static List<Doctor> _applyFilters(
    List<Doctor> doctors, {
    String? specialite,
    String? query,
    String? disponibilite,
    String? typeConsultation,
    String? secteur,
    String? tarifRange,
    double? noteMin,
  }) {
    List<Doctor> filteredDoctors = List.from(doctors);

    if (specialite != null && specialite.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((d) =>
        d.specialite.toLowerCase().contains(specialite.toLowerCase())
      ).toList();
    }

    if (query != null && query.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((d) =>
        d.fullName.toLowerCase().contains(query.toLowerCase()) ||
        d.specialite.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }

    if (disponibilite == 'Aujourd\'hui') {
      filteredDoctors = filteredDoctors.where((d) => d.disponibleAujourdhui).toList();
    }

    if (typeConsultation == 'Présentiel') {
      filteredDoctors = filteredDoctors.where((d) => d.consultationPresentiel).toList();
    } else if (typeConsultation == 'Téléconsultation') {
      filteredDoctors = filteredDoctors.where((d) => d.consultationTele).toList();
    }

    if (secteur != null && secteur.isNotEmpty) {
      filteredDoctors = filteredDoctors.where((d) => d.secteur == secteur).toList();
    }

    if (tarifRange != null) {
      if (tarifRange == '< 30€') {
        filteredDoctors = filteredDoctors.where((d) => d.tarif < 30).toList();
      } else if (tarifRange == '30–60€') {
        filteredDoctors = filteredDoctors.where((d) => d.tarif >= 30 && d.tarif <= 60).toList();
      } else if (tarifRange == '60€+') {
        filteredDoctors = filteredDoctors.where((d) => d.tarif > 60).toList();
      }
    }

    if (noteMin != null) {
      filteredDoctors = filteredDoctors.where((d) => d.note >= noteMin).toList();
    }

    return filteredDoctors;
  }

  static List<Doctor> _getMockDoctors() {
    return [
      Doctor(
        id: '1',
        nom: 'Martin',
        prenom: 'Sophie',
        specialite: 'Cardiologue',
        note: 4.8,
        nombreAvis: 127,
        adresse: '15 Rue de la Santé',
        ville: 'Paris 15ème',
        distance: 1.2,
        disponibleAujourdhui: true,
        tarif: 50,
        secteur: 'Secteur 2',
        consultationPresentiel: true,
        consultationTele: true,
        latitude: 48.8466,
        longitude: 2.2860,
        disponibilites: ['Lundi 14h-18h', 'Mercredi 9h-12h', 'Vendredi 14h-18h'],
      ),
      Doctor(
        id: '2',
        nom: 'Dubois',
        prenom: 'Pierre',
        specialite: 'Généraliste',
        note: 4.5,
        nombreAvis: 89,
        adresse: '23 Avenue des Champs-Élysées',
        ville: 'Paris 8ème',
        distance: 2.8,
        disponibleAujourdhui: true,
        tarif: 30,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: false,
        latitude: 48.8708,
        longitude: 2.3020,
        disponibilites: ['Lundi 8h-12h', 'Mardi 14h-18h', 'Jeudi 8h-12h'],
      ),
      Doctor(
        id: '3',
        nom: 'Bernard',
        prenom: 'Marie',
        specialite: 'Dermatologue',
        note: 4.9,
        nombreAvis: 203,
        adresse: '5 Rue du Faubourg Saint-Honoré',
        ville: 'Paris 8ème',
        distance: 3.1,
        disponibleAujourdhui: false,
        tarif: 60,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: true,
        latitude: 48.8682,
        longitude: 2.3164,
        disponibilites: ['Mardi 9h-13h', 'Jeudi 14h-18h', 'Vendredi 9h-13h'],
      ),
      Doctor(
        id: '4',
        nom: 'Petit',
        prenom: 'Jean',
        specialite: 'Pédiatre',
        note: 4.7,
        nombreAvis: 156,
        adresse: '12 Boulevard Montmartre',
        ville: 'Paris 9ème',
        distance: 4.5,
        disponibleAujourdhui: true,
        tarif: 45,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: true,
        latitude: 48.8707,
        longitude: 2.3432,
        disponibilites: ['Lundi 10h-16h', 'Mercredi 10h-16h', 'Vendredi 10h-16h'],
      ),
      Doctor(
        id: '5',
        nom: 'Rousseau',
        prenom: 'Isabelle',
        specialite: 'Gynécologue',
        note: 4.6,
        nombreAvis: 98,
        adresse: '34 Rue de Vaugirard',
        ville: 'Paris 15ème',
        distance: 2.3,
        disponibleAujourdhui: false,
        tarif: 55,
        secteur: 'Secteur 2',
        consultationPresentiel: true,
        consultationTele: false,
        latitude: 48.8499,
        longitude: 2.3180,
        disponibilites: ['Mardi 14h-18h', 'Jeudi 9h-13h', 'Samedi 9h-12h'],
      ),
      Doctor(
        id: '6',
        nom: 'Lefebvre',
        prenom: 'Michel',
        specialite: 'Ophtalmologue',
        note: 4.4,
        nombreAvis: 67,
        adresse: '78 Avenue d\'Italie',
        ville: 'Paris 13ème',
        distance: 5.2,
        disponibleAujourdhui: true,
        tarif: 65,
        secteur: 'Secteur 2',
        consultationPresentiel: true,
        consultationTele: false,
        latitude: 48.8320,
        longitude: 2.3566,
        disponibilites: ['Lundi 9h-12h', 'Mercredi 14h-18h', 'Vendredi 9h-12h'],
      ),
      Doctor(
        id: '7',
        nom: 'Garcia',
        prenom: 'Carlos',
        specialite: 'Psychiatre',
        note: 4.8,
        nombreAvis: 142,
        adresse: '19 Rue de la Glacière',
        ville: 'Paris 13ème',
        distance: 3.8,
        disponibleAujourdhui: true,
        tarif: 70,
        secteur: 'Secteur 2',
        consultationPresentiel: true,
        consultationTele: true,
        latitude: 48.8336,
        longitude: 2.3490,
        disponibilites: ['Lundi 14h-18h', 'Mardi 10h-12h', 'Jeudi 14h-18h'],
      ),
      Doctor(
        id: '8',
        nom: 'Moreau',
        prenom: 'Claire',
        specialite: 'Généraliste',
        note: 4.3,
        nombreAvis: 54,
        adresse: '45 Rue Oberkampf',
        ville: 'Paris 11ème',
        distance: 6.1,
        disponibleAujourdhui: false,
        tarif: 35,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: true,
        latitude: 48.8606,
        longitude: 2.3775,
        disponibilites: ['Mercredi 8h-12h', 'Vendredi 14h-18h', 'Samedi 9h-12h'],
      ),
      Doctor(
        id: '9',
        nom: 'Fournier',
        prenom: 'Philippe',
        specialite: 'Cardiologue',
        note: 4.7,
        nombreAvis: 118,
        adresse: '8 Boulevard Saint-Germain',
        ville: 'Paris 6ème',
        distance: 4.2,
        disponibleAujourdhui: true,
        tarif: 75,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: false,
        latitude: 48.8530,
        longitude: 2.3385,
        disponibilites: ['Lundi 14h-18h', 'Mercredi 9h-13h', 'Vendredi 14h-18h'],
      ),
      Doctor(
        id: '10',
        nom: 'Laurent',
        prenom: 'Sophie',
        specialite: 'Dermatologue',
        note: 4.5,
        nombreAvis: 93,
        adresse: '67 Rue de Rivoli',
        ville: 'Paris 4ème',
        distance: 5.8,
        disponibleAujourdhui: false,
        tarif: 58,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: true,
        latitude: 48.8573,
        longitude: 2.3520,
        disponibilites: ['Mardi 10h-14h', 'Jeudi 14h-18h', 'Vendredi 10h-14h'],
      ),
      Doctor(
        id: '11',
        nom: 'Robert',
        prenom: 'François',
        specialite: 'Pédiatre',
        note: 4.9,
        nombreAvis: 187,
        adresse: '102 Avenue de la République',
        ville: 'Paris 11ème',
        distance: 7.3,
        disponibleAujourdhui: true,
        tarif: 42,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: true,
        latitude: 48.8667,
        longitude: 2.3890,
        disponibilites: ['Lundi 9h-12h', 'Mercredi 14h-18h', 'Vendredi 9h-12h'],
      ),
      Doctor(
        id: '12',
        nom: 'Martinez',
        prenom: 'Laura',
        specialite: 'Gynécologue',
        note: 4.6,
        nombreAvis: 104,
        adresse: '28 Rue des Martyrs',
        ville: 'Paris 9ème',
        distance: 3.9,
        disponibleAujourdhui: true,
        tarif: 52,
        secteur: 'Secteur 1',
        consultationPresentiel: true,
        consultationTele: false,
        latitude: 48.8837,
        longitude: 2.3425,
        disponibilites: ['Lundi 8h-12h', 'Mercredi 14h-18h', 'Jeudi 8h-12h'],
      ),
    ];
  }

  static Future<void> addDoctor(Doctor doctor) async {
    try {
      await _db.collection('medecins').add(doctor.toJson());
    } catch (e) {
      print('Erreur lors de l\'ajout du médecin: $e');
      throw e;
    }
  }

  static Future<void> initializeMockData() async {
    try {
      // Vérifier si la collection est vide
      QuerySnapshot snapshot = await _db.collection('medecins').limit(1).get();
      
      if (snapshot.docs.isEmpty) {
        // Ajouter les données mockées
        List<Doctor> mockDoctors = _getMockDoctors();
        
        for (Doctor doctor in mockDoctors) {
          await _db.collection('medecins').add(doctor.toJson());
        }
        
        print('Données mockées initialisées avec succès');
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation des données: $e');
    }
  }

  static List<String> getSpecialites() {
    return ['Généraliste', 'Cardiologue', 'Dermatologue', 'Pédiatre', 'Gynécologue', 'Ophtalmologue', 'Psychiatre'];
  }

  static List<String> getSecteurs() {
    return ['Secteur 1', 'Secteur 2', 'Secteur 3'];
  }
}
