import 'package:flutter/material.dart';

import '../models/bottle_log.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Bottle log card widget
class BottleLogCard extends StatelessWidget {
  final BottleLog bottleLog;

  const BottleLogCard({super.key, required this.bottleLog});

  Color _getStatusColor() {
    if (bottleLog.isVerified) return AppColors.successColor;
    if (bottleLog.isPending) return AppColors.warningColor;
    if (bottleLog.isRejected) return AppColors.errorColor;
    return AppColors.textSecondary;
  }

  IconData _getStatusIcon() {
    if (bottleLog.isVerified) return Icons.check_circle;
    if (bottleLog.isPending) return Icons.hourglass_empty;
    if (bottleLog.isRejected) return Icons.cancel;
    return Icons.help;
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
          // Could navigate to detail screen
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              const SizedBox(width: 16),

              // Bottle info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bottleLog.machineName ??
                              'Machine ${bottleLog.machineId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bottleLog.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Helpers.formatDateTime(bottleLog.timestamp),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Credits earned
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${bottleLog.creditsAwarded}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Text(
                    'credits',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
