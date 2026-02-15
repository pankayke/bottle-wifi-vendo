import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Displays the result of a bottle scan for an authenticated user.
/// Shows credits earned and updated total balance.
class PointsEarnedCard extends StatelessWidget {
  final int creditsEarned;
  final int totalCredits;
  final VoidCallback? onViewDashboard;

  const PointsEarnedCard({
    super.key,
    required this.creditsEarned,
    required this.totalCredits,
    this.onViewDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
        side: const BorderSide(color: BWColors.primary, width: 1.5),
      ),
      color: BWColors.primary.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Column(
          children: [
            _buildSuccessIcon(),
            const SizedBox(height: BWSpacing.md),
            Text(
              'Credits Earned!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: BWColors.textPrimary,
              ),
            ),
            const SizedBox(height: BWSpacing.lg),
            _buildPointsDisplay(context),
            const SizedBox(height: BWSpacing.md),
            _buildTotalBalance(context),
            if (onViewDashboard != null) ...[
              const SizedBox(height: BWSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onViewDashboard,
                  icon: const Icon(Icons.dashboard, color: Colors.white),
                  label: const Text(
                    'View Dashboard',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BWColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: BWColors.primary.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.stars_rounded,
        size: 40,
        color: BWColors.primary,
      ),
    );
  }

  Widget _buildPointsDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: BWColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BWColors.primary, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.add_circle, color: BWColors.primary, size: 28),
          const SizedBox(width: BWSpacing.sm),
          Text(
            '+$creditsEarned',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: BWColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: BWSpacing.xs),
          Text(
            'credits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: BWColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalance(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.account_balance_wallet, size: 18,
            color: BWColors.textSecondary),
        const SizedBox(width: BWSpacing.xs),
        Text(
          'Total balance: $totalCredits credits',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: BWColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
