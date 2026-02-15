import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/insert_provider.dart';
import '../../utils/app_theme.dart';

/// Insert Bottle screen: 30-second Piso-WiFi-style countdown.
/// On timer completion, dispatches reward based on auth state.
class InsertScreen extends StatefulWidget {
  const InsertScreen({super.key});

  @override
  State<InsertScreen> createState() => _InsertScreenState();
}

class _InsertScreenState extends State<InsertScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-start the 30s countdown on entering the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTimer();
    });
  }

  void _startTimer() {
    final authProvider = context.read<AuthProvider>();
    final insertProvider = context.read<InsertProvider>();

    final isLoggedIn = authProvider.isAuthenticated && !authProvider.isGuest;
    final user = isLoggedIn ? authProvider.user : null;

    insertProvider.startInsert(user);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated && !authProvider.isGuest;

    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(
        backgroundColor: BWColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context),
        ),
        title: const Text('Insert Bottle'),
      ),
      body: Consumer<InsertProvider>(
        builder: (context, provider, _) {
          return _buildBody(context, provider, isLoggedIn);
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    InsertProvider provider,
    bool isLoggedIn,
  ) {
    switch (provider.phase) {
      case InsertPhase.idle:
        return _buildIdleState(context);
      case InsertPhase.counting:
        return _buildCountingState(context, provider);
      case InsertPhase.scanSuccess:
        // User got credits → navigate to credits screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/user/credits-success');
        });
        return const Center(
          child: CircularProgressIndicator(color: BWColors.primary),
        );
      case InsertPhase.wifiActive:
        // Guest got free WiFi → navigate to WiFi screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/user/guest-wifi');
        });
        return const Center(
          child: CircularProgressIndicator(color: BWColors.primary),
        );
      case InsertPhase.error:
        return _buildErrorState(context, provider);
    }
  }

  // ───────────────────── Idle ─────────────────────────

  Widget _buildIdleState(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(BWSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.recycling, size: 80, color: BWColors.primary),
              const SizedBox(height: BWSpacing.lg),
              Text(
                'Ready to Scan',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: BWSpacing.md),
              Text(
                'Tap below to start the 30-second insert timer',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BWSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START INSERT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BWColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────── Counting ─────────────────────────

  Widget _buildCountingState(BuildContext context, InsertProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(BWSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular timer
              SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _CircularTimerPainter(
                        progress: provider.insertProgress,
                        strokeWidth: 10,
                        backgroundColor: BWColors.surfaceVariant,
                        progressColor: BWColors.primary,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.formattedInsertTime,
                              style: GoogleFonts.poppins(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: BWColors.primary,
                              ),
                            ),
                            Text(
                              'seconds',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(
                    duration: 2000.ms,
                    color: BWColors.accent.withAlpha(30),
                  ),
              const SizedBox(height: BWSpacing.xl),
              // Bottle drop animation placeholder
              const Icon(Icons.local_drink, size: 64, color: BWColors.secondary)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .slideY(begin: -0.15, end: 0.15, duration: 800.ms),
              const SizedBox(height: BWSpacing.lg),
              Text(
                'Insert bottle NOW',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: BWColors.textPrimary,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: BWSpacing.sm),
              Text(
                'Place your plastic bottle in the machine',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────── Error ─────────────────────────

  Widget _buildErrorState(BuildContext context, InsertProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.all(BWSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: BWColors.error),
              const SizedBox(height: BWSpacing.lg),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: BWSpacing.sm),
              Text(
                provider.errorMessage ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BWSpacing.xl),
              ElevatedButton.icon(
                onPressed: () {
                  provider.reset();
                  _startTimer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateBack(BuildContext context) {
    final provider = context.read<InsertProvider>();
    provider.reset();

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/user/home');
    }
  }
}

// ───────────────────── Circular Timer Painter ─────────────────────────

class _CircularTimerPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  const _CircularTimerPainter({
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
  bool shouldRepaint(_CircularTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
