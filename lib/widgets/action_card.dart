import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum ActionCardVariant { primary, secondary, outlined }

/// Reusable CTA card with icon, title, subtitle, and tap action.
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ActionCardVariant variant;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.variant = ActionCardVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == ActionCardVariant.primary;
    final isOutlined = variant == ActionCardVariant.outlined;

    return Card(
      elevation: isOutlined ? 0 : BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
        side: isOutlined
            ? const BorderSide(color: BWColors.divider)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(BWSpacing.lg),
          decoration: isPrimary
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
                  gradient: BWColors.primaryGradient,
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withAlpha(40)
                      : BWColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isPrimary ? Colors.white : BWColors.primary,
                ),
              ),
              const SizedBox(width: BWSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isPrimary ? Colors.white : BWColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isPrimary
                            ? Colors.white.withAlpha(190)
                            : BWColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isPrimary
                    ? Colors.white.withAlpha(180)
                    : BWColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
