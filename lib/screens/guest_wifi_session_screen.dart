import 'package:flutter/material.dart';
import 'dart:async';
import '../services/guest_service.dart';
import '../services/device_fingerprint_service.dart';
import 'optional_registration_screen.dart';

class GuestWifiSessionScreen extends StatefulWidget {
  final String sessionToken;
  final int minutes;
  final DateTime expiresAt;

  const GuestWifiSessionScreen({
    Key? key,
    required this.sessionToken,
    required this.minutes,
    required this.expiresAt,
  }) : super(key: key);

  @override
  State<GuestWifiSessionScreen> createState() => _GuestWifiSessionScreenState();
}

class _GuestWifiSessionScreenState extends State<GuestWifiSessionScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _shouldSuggestRegistration = false;
  Map<String, dynamic>? _guestStats;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkRegistrationSuggestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final remaining = widget.expiresAt.difference(now);

    if (remaining.isNegative) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      _timer?.cancel();
    } else {
      setState(() {
        _remainingTime = remaining;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _checkRegistrationSuggestion() async {
    try {
      final fingerprint = await DeviceFingerprintService()
          .generateFingerprint();
      final guestService = GuestService();

      final shouldSuggest = await guestService.shouldSuggestRegistration(
        fingerprint,
      );
      final stats = await guestService.getStats();

      if (mounted) {
        setState(() {
          _shouldSuggestRegistration = shouldSuggest;
          _guestStats = stats;
        });
      }
    } catch (e) {
      // Silently fail - suggestion is optional
    }
  }

  void _navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OptionalRegistrationScreen(guestStats: _guestStats ?? {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _remainingTime.inSeconds <= 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/school_logo.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Bottle-Wifi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpired ? Icons.wifi_off : Icons.wifi,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        isExpired ? 'Session Expired' : 'WiFi Active!',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Timer
                      if (!isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatDuration(_remainingTime),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          isExpired
                              ? 'Your WiFi session has ended. Insert another bottle to get more time!'
                              : 'Enjoy your free WiFi! The timer will countdown automatically.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Show "Scan Another Bottle" if session expired
                    if (isExpired)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.recycling),
                          label: const Text(
                            'Scan Another Bottle',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                    // Show registration suggestion if not expired and should suggest
                    if (_shouldSuggestRegistration && !isExpired) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.shade400,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.stars,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Save Your Credits!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You\'ve scanned multiple bottles! Create a free account to save your credits and earn rewards.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _navigateToRegistration,
                                icon: const Icon(Icons.account_circle),
                                label: const Text('Create Free Account'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Show "Back to Home" button if session not expired
                    if (!isExpired)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home),
                          label: const Text(
                            'Back to Home',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Session Token (for debugging)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Token:',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.sessionToken,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
