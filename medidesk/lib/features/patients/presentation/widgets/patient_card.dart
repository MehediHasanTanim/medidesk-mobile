import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
import '../../data/models/patient_model.dart';

class PatientCard extends StatelessWidget {
  const PatientCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _GenderAvatar(gender: patient.gender),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        SyncStatusBadge(syncStatus: patient.syncStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (patient.patientId != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              patient.patientId!,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        const Icon(
                          Icons.phone,
                          size: 13,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          patient.phone,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderAvatar extends StatelessWidget {
  const _GenderAvatar({required this.gender});

  final String gender;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (gender) {
      'M' => (Icons.male, Colors.blue[100]!),
      'F' => (Icons.female, Colors.pink[100]!),
      _ => (Icons.person, Colors.grey[200]!),
    };

    return CircleAvatar(
      radius: 22,
      backgroundColor: color,
      child: Icon(icon, size: 22, color: Colors.grey[700]),
    );
  }
}
