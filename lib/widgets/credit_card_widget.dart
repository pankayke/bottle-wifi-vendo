import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/credit_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Credit card widget displaying user credits
class CreditCardWidget extends StatelessWidget {
  const CreditCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CreditProvider>(
      builder: (context, authProvider, creditProvider, child) {
        final user = authProvider.user;
        final credits = creditProvider.credits;

        return Card(
          elevation: AppConstants.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryColor, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Credits',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${user?.credits ?? 0} minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (credits != null) ...[
                  Row(
                    children: [
                      _InfoChip(
                        label: 'Total',
                        value: Helpers.formatCredits(credits.totalMinutes),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: 'Used',
                        value: Helpers.formatCredits(credits.usedMinutes),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
