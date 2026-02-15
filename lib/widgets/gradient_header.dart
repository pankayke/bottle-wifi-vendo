import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Full-width gradient hero section for landing pages.
class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> actions;
  final double verticalPadding;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.water_drop,
    this.actions = const [],
    this.verticalPadding = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: BWSpacing.lg,
        vertical: verticalPadding,
      ),
      decoration: const BoxDecoration(gradient: BWColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.white),
            const SizedBox(height: BWSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BWSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withAlpha(200),
              ),
              textAlign: TextAlign.center,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: BWSpacing.lg),
              Wrap(
                spacing: BWSpacing.md,
                runSpacing: BWSpacing.sm,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
