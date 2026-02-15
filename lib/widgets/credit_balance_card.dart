import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/helpers.dart';

/// Gradient-backed credit balance display card.
class CreditBalanceCard extends StatelessWidget {
  final int balance;
  final bool isLoading;

  const CreditBalanceCard({
    super.key,
    required this.balance,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BWSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
          gradient: BWColors.heroGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: BWSpacing.sm),
                Text(
                  'WiFi Credit Balance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BWSpacing.md),
            if (isLoading)
              const SizedBox(
                height: 36,
                width: 36,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            else
              Text(
                Helpers.formatCredits(balance),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              '1 credit = 1 minute WiFi',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
