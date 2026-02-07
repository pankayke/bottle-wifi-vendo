import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Screen shown while scanning/detecting a bottle
class BottleScanningScreen extends StatefulWidget {
  const BottleScanningScreen({super.key});

  @override
  State<BottleScanningScreen> createState() => _BottleScanningScreenState();
}

class _BottleScanningScreenState extends State<BottleScanningScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/school_logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.school,
                      size: 20,
                      color: AppColors.primaryColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Bottle-Wifi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Scanning Circle
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryColor.withOpacity(0.2),
                        border: Border.all(
                          color: AppColors.primaryColor,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryColor.withOpacity(0.3),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Title
            const Text(
              'Scanning Bottle',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Checking Cleanliness',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 40),

            // Loading Progress
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_controller.value * 0.7) + 0.3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor,
                            AppColors.primaryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
