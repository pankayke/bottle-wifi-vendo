import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

/// Displays a generated voucher with copy-to-clipboard support.
class ScanResultCard extends StatelessWidget {
  final String voucherCode;
  final int minutesGranted;
  final VoidCallback? onRedeem;

  const ScanResultCard({
    super.key,
    required this.voucherCode,
    required this.minutesGranted,
    this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
        side: const BorderSide(color: BWColors.success, width: 1.5),
      ),
      color: BWColors.success.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: BWColors.success.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: BWColors.success,
              ),
            ),
            const SizedBox(height: BWSpacing.md),
            Text(
              'Voucher Generated!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: BWColors.textPrimary,
              ),
            ),
            const SizedBox(height: BWSpacing.lg),
            _buildCodeDisplay(context),
            const SizedBox(height: BWSpacing.md),
            Text(
              '$minutesGranted minutes of free WiFi',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: BWColors.textSecondary,
              ),
            ),
            if (onRedeem != null) ...[
              const SizedBox(height: BWSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRedeem,
                  icon: const Icon(Icons.wifi, color: Colors.white),
                  label: const Text(
                    'Redeem Now',
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

  Widget _buildCodeDisplay(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyCode(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: BWColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BWColors.primary, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SelectableText(
                voucherCode,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: BWColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: BWSpacing.sm),
            IconButton(
              onPressed: () => _copyCode(context),
              icon: const Icon(Icons.copy_rounded, color: BWColors.primary),
              tooltip: 'Copy code',
            ),
          ],
        ),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: voucherCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Voucher code copied!'),
        backgroundColor: BWColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
