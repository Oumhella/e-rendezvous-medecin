import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../theme/app_theme.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onAppointment;

  const DoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    required this.onAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightBlue.withOpacity(0.04),
            blurRadius: 32, 
            spreadRadius: -2,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo et nom en haut
              Column(
                children: [
                  Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lightBlue.withOpacity(0.3), 
                            blurRadius: 20, 
                            offset: const Offset(0, 8)
                          ),
                          BoxShadow(
                            color: AppColors.lightBlue.withOpacity(0.12), 
                            blurRadius: 6, 
                            offset: const Offset(0, 3)
                          ),
                        ],
                      ),
                      child: doctor.photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.network(
                                doctor.photoUrl!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      doctor.prenom[0] + doctor.nom[0],
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.w900, 
                                        fontSize: 32
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                doctor.prenom[0] + doctor.nom[0],
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 32
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nom et spécialité centrés
                  Column(
                    children: [
                      Text(
                        doctor.fullName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.navyDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          doctor.specialite,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.navyDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Informations horizontales
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      doctor.noteText,
                                      style: const TextStyle(
                                        fontSize: 14, 
                                        fontWeight: FontWeight.w900, 
                                        color: Color(0xFFB45309)
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: AppColors.lightBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${doctor.ville} — ${doctor.distanceText}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: doctor.disponibleAujourdhui
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : AppColors.lightBlue.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: doctor.disponibleAujourdhui
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                doctor.disponibleAujourdhui
                                    ? 'Disponible'
                                    : 'Indisponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: doctor.disponibleAujourdhui
                                      ? const Color(0xFF10B981)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doctor.tarifText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Types de consultation
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (doctor.consultationPresentiel)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.local_hospital_rounded,
                            size: 16,
                            color: AppColors.navyDark,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cabinet',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (doctor.consultationTele)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.video_call_rounded,
                            size: 16,
                            color: AppColors.navyDark,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Téléconsultation',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Bouton CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: onAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlue,
                    foregroundColor: AppColors.navyDark,
                    elevation: 12,
                    shadowColor: AppColors.lightBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Prendre rendez-vous',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
