import 'package:flutter/material.dart';
import '../services/guest_service.dart';
import 'guest_wifi_session_screen.dart';

class GuestBottleScanScreen extends StatefulWidget {
  const GuestBottleScanScreen({Key? key}) : super(key: key);

  @override
  State<GuestBottleScanScreen> createState() => _GuestBottleScanScreenState();
}

class _GuestBottleScanScreenState extends State<GuestBottleScanScreen>
    with SingleTickerProviderStateMixin {
  final GuestService _guestService = GuestService();

  bool _isScanning = false;
  bool _isProcessing = false;
  String _statusMessage = 'Ready to scan';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startBottleScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Insert your bottle now...';
    });

    // Simulate bottle detection (in production, this would come from ESP32)
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing bottle...';
    });

    try {
      // Call guest service to process the scan
      final result = await _guestService.scanBottle(
        machineIdentifier: 'ESP32_001', // In production, this would be dynamic
      );

      if (result['success'] == true) {
        // Navigate to success screen with session details
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GuestWifiSessionScreen(
                sessionToken: result['session']['token'],
                minutes: result['session']['minutes'],
                expiresAt: DateTime.parse(result['session']['expires_at']),
              ),
            ),
          );
        }
      } else {
        // Show error
        if (mounted) {
          _showErrorDialog(result['error'] ?? 'Failed to process bottle');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isProcessing = false;
          _statusMessage = 'Ready to scan';
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guest WiFi'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
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
                      // Bottle Icon with Animation
                      if (_isScanning || _isProcessing)
                        RotationTransition(
                          turns: _animationController,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.recycling,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.recycling,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),

                      const SizedBox(height: 32),

                      // Status Message
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

                      if (!_isScanning && !_isProcessing) ...[
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
                      ],

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

              // Action Button
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
                            foregroundColor: const Color(0xFF4CAF50),
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

                    // Info Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
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
                            'Earn 30 minutes of free WiFi per bottle',
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
}
