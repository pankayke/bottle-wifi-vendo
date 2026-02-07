import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'reward_screen.dart';

/// Scanning Screen with circular progress indicator
class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String statusMessage = 'Initializing...';
  Timer? _progressTimer;
  int _step = 0;

  final List<String> _statusSteps = [
    'Initializing...',
    'Detecting bottle...',
    'Checking cleanliness...',
    'Analyzing material...',
    'Verification complete!',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startProgressSimulation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressSimulation() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 1200), (
      timer,
    ) {
      if (_step < _statusSteps.length - 1) {
        setState(() {
          _step++;
          statusMessage = _statusSteps[_step];
        });
      } else {
        timer.cancel();
        _controller.stop();
        // Navigate to reward screen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RewardScreen(minutesEarned: 30),
              ),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Title
              const Text(
                'Scanning Bottle',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 48),

              // Circular Progress Indicator
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated rotating circle
                    RotationTransition(
                      turns: _controller,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            width: 8,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _CircleProgressPainter(
                            progress: 0.7,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    // Bottle icon in center
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.recycling,
                        size: 70,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Status Message
              Text(
                statusMessage,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _statusSteps.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _step
                          ? AppColors.primaryColor
                          : AppColors.dividerColor,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for circular progress
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircleProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start from top (-90 degrees in radians)
      progress * 6.2832, // Progress in radians (2 * pi)
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
