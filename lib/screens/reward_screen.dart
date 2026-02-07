import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Congratulations/Reward Screen
class RewardScreen extends StatelessWidget {
  final int minutesEarned;

  const RewardScreen({super.key, required this.minutesEarned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Celebration Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.successColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 70,
                  color: AppColors.successColor,
                ),
              ),
              const SizedBox(height: 32),

              // Congratulations text
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Most Clean Bottle Detected.\nYou\'ve earned $minutesEarned minutes of WiFi time!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Reward Display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.wifi,
                      size: 48,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '+$minutesEarned minutes',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // Got it button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to dashboard
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
