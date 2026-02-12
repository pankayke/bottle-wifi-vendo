import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bottle_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/machine_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Bottle scan screen for authenticated (account) users.
/// Awards 20 minutes of WiFi credit per bottle via the authenticated API.
class UserBottleScanScreen extends StatefulWidget {
  const UserBottleScanScreen({super.key});

  @override
  State<UserBottleScanScreen> createState() => _UserBottleScanScreenState();
}

class _UserBottleScanScreenState extends State<UserBottleScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _isProcessing = false;
  String _statusMessage = 'Ready to scan';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startBottleScan() async {
    final machineProvider = context.read<MachineProvider>();
    final machines = machineProvider.onlineMachines;

    if (machines.isEmpty) {
      Helpers.showSnackbar(
        context,
        'No online machines found. Please try again later.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _statusMessage = 'Insert your bottle now...';
    });

    // Simulate bottle detection delay (ESP32 would trigger this in production)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing bottle...';
    });

    try {
      final bottleProvider = context.read<BottleProvider>();
      final success = await bottleProvider.reportBottle(
        machineId: machines.first.id,
      );

      if (!mounted) return;

      if (success) {
        // Refresh credits after successful bottle report
        await context.read<CreditProvider>().fetchCredits();

        if (!mounted) return;

        setState(() {
          _isScanning = false;
          _isProcessing = false;
          _statusMessage = 'Ready to scan';
        });

        _showSuccessDialog();
      } else {
        final errorMsg =
            bottleProvider.errorMessage ?? 'Failed to process bottle';
        setState(() {
          _isScanning = false;
          _isProcessing = false;
          _statusMessage = 'Ready to scan';
        });
        Helpers.showSnackbar(context, errorMsg, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _isProcessing = false;
        _statusMessage = 'Ready to scan';
      });
      Helpers.showSnackbar(
        context,
        'An error occurred: ${e.toString()}',
        isError: true,
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Bottle Accepted!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: const [
                  Icon(Icons.wifi, size: 40, color: Colors.green),
                  SizedBox(height: 8),
                  Text(
                    '+20 minutes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'WiFi credit added to your account',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Insert another bottle to earn more credits!',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Scan Another'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Back to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insert Bottle'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated bottle icon
                      if (_isScanning || _isProcessing)
                        ScaleTransition(
                          scale: Tween(
                            begin: 0.9,
                            end: 1.1,
                          ).animate(_pulseController),
                          child: _buildBottleIcon(),
                        )
                      else
                        _buildBottleIcon(),

                      const SizedBox(height: 32),

                      // Status message
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      if (!_isScanning && !_isProcessing)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Tap the button below when you\'re ready to insert your bottle',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (_isProcessing) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom action area
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    if (!_isScanning && !_isProcessing)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startBottleScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'Start Scanning',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Info chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Earn 20 minutes of WiFi per bottle',
                            style: TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottleIcon() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.local_drink, size: 80, color: Colors.white),
    );
  }
}
