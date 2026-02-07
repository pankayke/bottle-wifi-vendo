import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Screen shown when bottle is successfully detected and credits awarded
class BottleSuccessScreen extends StatelessWidget {
  final int minutesEarned;

  const BottleSuccessScreen({super.key, this.minutesEarned = 30});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon with Party/Celebration emoji style
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryColor.withOpacity(0.1),
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor.withOpacity(0.2),
                    ),
                    child: const Center(
                      child: Text('🎉', style: TextStyle(fontSize: 50)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Congratulations Text
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Your Clean Bottle Detected. You have\nearned 30 minutes of Wifi Time!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Minutes Earned Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!, width: 2),
                ),
                child: Text(
                  '+$minutesEarned minutes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Got it Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
