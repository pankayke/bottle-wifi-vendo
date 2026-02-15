import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

/// Home screen with 2 primary actions:
///   🍾 INSERT BOTTLE — starts the 30s timer flow
///   👤 LOGIN — navigate to login/dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated && !authProvider.isGuest;

    return Scaffold(
      backgroundColor: BWColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _EcoHeader(),
              const SizedBox(height: BWSpacing.xl),
              _ActionButtons(isLoggedIn: isLoggedIn),
              const SizedBox(height: BWSpacing.xxl),
              const _HowItWorks(),
              const SizedBox(height: BWSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Eco Header ─────────────────────────

class _EcoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: BWSpacing.xxl,
        horizontal: BWSpacing.lg,
      ),
      decoration: const BoxDecoration(
        gradient: BWColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.recycling, size: 64, color: Colors.white)
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: BWSpacing.md),
          Text(
            'BottleWiFi ♻️',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
          const SizedBox(height: BWSpacing.xs),
          Text(
            'Recycle → Free WiFi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

// ───────────────────────── Action Buttons ─────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool isLoggedIn;
  const _ActionButtons({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BWSpacing.lg),
          child: Column(
            children: [
              // Primary: Insert Bottle
              _BigActionButton(
                icon: Icons.recycling,
                label: 'INSERT BOTTLE',
                sublabel: '30s timer starts',
                gradient: BWColors.primaryGradient,
                onTap: () => Navigator.pushNamed(context, '/user/insert'),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: BWSpacing.lg),
              // Secondary: Login / Dashboard
              _BigActionButton(
                    icon: isLoggedIn
                        ? Icons.dashboard_rounded
                        : Icons.person_rounded,
                    label: isLoggedIn ? 'MY DASHBOARD' : 'LOGIN',
                    sublabel: isLoggedIn
                        ? 'View credits & vouchers'
                        : 'Manage your credits',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      if (isLoggedIn) {
                        Navigator.pushNamed(context, '/user/dashboard');
                      } else {
                        Navigator.pushNamed(context, '/user/login');
                      }
                    },
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms)
                  .slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Big Action Button ─────────────────────────

class _BigActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _BigActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      elevation: BWSpacing.cardElevation,
      child: InkWell(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: BWSpacing.xl,
            horizontal: BWSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(width: BWSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sublabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── How It Works ─────────────────────────

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BWSpacing.lg),
          child: Column(
            children:
                [
                      Text(
                        'How It Works',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: BWSpacing.lg),
                      const _StepTile(
                        step: '1',
                        icon: Icons.recycling,
                        title: 'Insert a Bottle',
                        description:
                            'Press INSERT BOTTLE and drop your plastic bottle',
                      ),
                      const SizedBox(height: BWSpacing.sm),
                      const _StepTile(
                        step: '2',
                        icon: Icons.timer,
                        title: '30s Countdown',
                        description: 'Timer confirms your bottle is detected',
                      ),
                      const SizedBox(height: BWSpacing.sm),
                      const _StepTile(
                        step: '3',
                        icon: Icons.wifi,
                        title: 'Get WiFi or Credits',
                        description:
                            'Guest = 20min free WiFi, User = +20 credits',
                      ),
                    ]
                    .animate(interval: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.05),
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String description;

  const _StepTile({
    required this.step,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: BWColors.primary,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: BWSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step $step: $title',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
