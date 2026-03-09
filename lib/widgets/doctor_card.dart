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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.navyDark.withOpacity(0.1),
                    child: doctor.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.network(
                              doctor.photoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  doctor.prenom[0] + doctor.nom[0],
                                  style: TextStyle(
                                    color: AppColors.navyDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            doctor.prenom[0] + doctor.nom[0],
                            style: TextStyle(
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            doctor.specialite,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.lightBlue,
                              fontWeight: FontWeight.w500,
                            ),
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
                    Icons.star,
                    color: Colors.amber[400],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    doctor.noteText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${doctor.ville} — ${doctor.distanceText}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: doctor.disponibleAujourdhui
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: doctor.disponibleAujourdhui
                                ? Colors.green
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.disponibleAujourdhui
                              ? 'Disponible aujourd\'hui'
                              : 'Non disponible',
                          style: TextStyle(
                            fontSize: 11,
                            color: doctor.disponibleAujourdhui
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${doctor.secteur} — ${doctor.tarifText}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (doctor.consultationPresentiel)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.local_hospital,
                            size: 14,
                            color: AppColors.navyDark,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Présentiel',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (doctor.consultationTele)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.video_call,
                            size: 14,
                            color: AppColors.lightBlue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Téléconsultation',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.lightBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: onAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Prendre RDV',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
