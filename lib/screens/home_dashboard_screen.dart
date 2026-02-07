import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'scanning_screen.dart';

/// Home Dashboard Screen matching the design mockup
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  // Demo data - replace with actual data from providers
  int remainingSeconds = 3802; // 01:03:22
  int ecoCredits = 5;
  int bottlesRecycled = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  void _navigateToScanning() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanningScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with school logo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // School logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/school_logo.jpg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: AppColors.primaryColor,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                  // Menu button
                  IconButton(
                    icon: const Icon(Icons.menu, size: 28),
                    onPressed: () {
                      // TODO: Open menu/drawer
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // WiFi Timer Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'REMAINING WIFI TIME',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatTime(remainingSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  // Eco Credits
                  Expanded(
                    child: _StatCard(
                      icon: Icons.eco,
                      iconColor: AppColors.successColor,
                      label: 'Eco Credits',
                      value: ecoCredits.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Bottles Recycled
                  Expanded(
                    child: _StatCard(
                      icon: Icons.delete_outline,
                      iconColor: AppColors.primaryColor,
                      label: 'Bottles Recycled',
                      value: bottlesRecycled.toString(),
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Ready to Insert Bottle Button
              ElevatedButton(
                onPressed: _navigateToScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.recycling, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Ready to Insert Bottle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: iconColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
