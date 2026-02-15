import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../utils/app_theme.dart';

/// Entry point screen — lets the user choose their access mode.
///
/// **Platform-aware behaviour:**
/// - Web → shows only user-facing options (Admin is hidden).
/// - Mobile → shows all options including Admin Kiosk.
class AccessModeScreen extends StatelessWidget {
  const AccessModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: BWColors.heroGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: BWSpacing.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: BWSpacing.lg),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildHeader(context),
                    const Spacer(flex: 2),
                    // Admin option — mobile only
                    if (!kIsWeb)
                      _buildModeCard(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'Admin Kiosk',
                        subtitle: 'Manage machines, users & vouchers',
                        color: BWColors.warning,
                        onTap: () =>
                            Navigator.pushNamed(context, '/admin/login'),
                      ),
                    if (!kIsWeb) const SizedBox(height: BWSpacing.md),
                    _buildModeCard(
                      context,
                      icon: Icons.person,
                      title: 'User Login',
                      subtitle: 'Login or register to track credits',
                      color: BWColors.primary,
                      onTap: () => Navigator.pushNamed(context, '/user/home'),
                    ),
                    const SizedBox(height: BWSpacing.md),
                    _buildModeCard(
                      context,
                      icon: Icons.recycling,
                      title: 'Guest — Scan & Go',
                      subtitle: 'Scan a bottle and get a WiFi voucher',
                      color: BWColors.accent,
                      onTap: () =>
                          Navigator.pushNamed(context, '/user/guest-scan'),
                    ),
                    const Spacer(flex: 3),
                    _buildFooter(),
                    const SizedBox(height: BWSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.water_drop, size: 72, color: Colors.white),
        const SizedBox(height: BWSpacing.md),
        Text(
          'BottleWiFi',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: BWSpacing.sm),
        Text(
          'Recycle bottles. Earn free WiFi.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white.withAlpha(200)),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: BWSpacing.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: BWSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: BWColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildFooter() {
    return Text(
      'Bottle WiFi Vendo v1.0',
      style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(130)),
    );
  }
}
