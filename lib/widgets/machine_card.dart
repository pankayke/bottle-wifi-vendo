import 'package:flutter/material.dart';

import '../models/machine.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Machine card widget
class MachineCard extends StatelessWidget {
  final Machine machine;

  const MachineCard({super.key, required this.machine});

  Color _getStatusColor() {
    if (machine.isOnline) return AppColors.successColor;
    if (machine.isInMaintenance) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  IconData _getStatusIcon() {
    if (machine.isOnline) return Icons.check_circle;
    if (machine.isInMaintenance) return Icons.build_circle;
    return Icons.error;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();

    return Card(
      elevation: AppConstants.cardElevation,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () {
          // Could show machine details
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Machine icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.router, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),

                  // Machine info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (machine.location != null)
                          Text(
                            machine.location!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Status indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        machine.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Machine details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.fingerprint,
                      label: 'MAC Address',
                      value: machine.macAddress,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.network_check,
                      label: 'IP Address',
                      value: machine.ipAddress,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      icon: Icons.recycling,
                      label: 'Bottles Processed',
                      value: machine.totalBottlesProcessed.toString(),
                    ),
                    if (machine.lastOnline != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.access_time,
                        label: 'Last Online',
                        value: Helpers.formatDateTime(machine.lastOnline!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
