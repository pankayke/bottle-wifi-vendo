import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/insert_provider.dart';
import '../../utils/app_theme.dart';

/// Guest success screen: 20-minute FREE WiFi countdown.
/// Shows WiFi network name, remaining time, and action buttons.
class GuestWifiScreen extends StatelessWidget {
  const GuestWifiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(
        backgroundColor: BWColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateHome(context),
        ),
        title: const Text('WiFi Unlocked! 🎉'),
      ),
      body: Consumer<InsertProvider>(
        builder: (context, provider, _) {
          return _GuestWifiBody(provider: provider);
        },
      ),
    );
  }

  void _navigateHome(BuildContext context) {
    final provider = context.read<InsertProvider>();
    provider.reset();
    Navigator.pushNamedAndRemoveUntil(context, '/user/home', (route) => false);
  }
}

class _GuestWifiBody extends StatelessWidget {
  final InsertProvider provider;
  const _GuestWifiBody({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BWSpacing.lg),
          child: Column(
            children:
                [
                      // Success badge
                      _buildSuccessBadge(context),
                      const SizedBox(height: BWSpacing.xl),
                      // WiFi timer card
                      _buildTimerCard(context),
                      const SizedBox(height: BWSpacing.lg),
                      // WiFi info card
                      _buildWifiInfoCard(context),
                      const SizedBox(height: BWSpacing.xl),
                      // Action buttons
                      _buildActions(context),
                    ]
                    .animate(interval: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBadge(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BWColors.success.withAlpha(25),
        border: Border.all(color: BWColors.success, width: 3),
      ),
      child: const Icon(Icons.check, size: 56, color: BWColors.success),
    ).animate().scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.0, 1.0),
      duration: 600.ms,
      curve: Curves.elasticOut,
    );
  }

  Widget _buildTimerCard(BuildContext context) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.xl),
        child: Column(
          children: [
            Text(
              '20 Minutes FREE WiFi',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BWColors.primary,
              ),
            ),
            const SizedBox(height: BWSpacing.lg),
            // Circular countdown
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _WifiTimerPainter(
                  progress: provider.wifiProgress,
                  strokeWidth: 10,
                  backgroundColor: BWColors.surfaceVariant,
                  progressColor: BWColors.success,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi, size: 28, color: BWColors.success),
                      const SizedBox(height: 4),
                      Text(
                        provider.formattedWifiTime,
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: BWColors.textPrimary,
                        ),
                      ),
                      Text(
                        'remaining',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiInfoCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: BWColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wifi, color: BWColors.primary),
            ),
            const SizedBox(width: BWSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WiFi Network',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'BottleWiFi-Free',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: BWColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BWColors.success.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Connected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BWColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate back to insert another bottle
              final provider = context.read<InsertProvider>();
              provider.reset();
              Navigator.pushReplacementNamed(context, '/user/insert');
            },
            icon: const Icon(Icons.recycling),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BWColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: BWSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              final provider = context.read<InsertProvider>();
              provider.reset();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/user/home',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
          ),
        ),
      ],
    );
  }
}

// ───────────────────── Circular WiFi Timer Painter ─────────────────────────

class _WifiTimerPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  const _WifiTimerPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_WifiTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
