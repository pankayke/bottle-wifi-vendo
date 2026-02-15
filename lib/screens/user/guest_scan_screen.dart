import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/bottle_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/points_earned_card.dart';
import '../../widgets/scan_result_card.dart';

/// Unified bottle scanning screen.
/// Detects auth state and shows the appropriate reward flow:
///   - Guest  → voucher code
///   - User   → credits added to account
class GuestScanScreen extends StatefulWidget {
  const GuestScanScreen({super.key});

  @override
  State<GuestScanScreen> createState() => _GuestScanScreenState();
}

class _GuestScanScreenState extends State<GuestScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn =
        authProvider.isAuthenticated && !authProvider.isGuest;

    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(
        title: const Text('Scan a Bottle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(context, isLoggedIn),
        ),
      ),
      body: Consumer<BottleProvider>(
        builder: (context, provider, _) {
          final result = provider.lastScanResult;
          final isSuccess = result != null && result['success'] == true;
          final session = result?['session'] as Map<String, dynamic>?;
          final isPointsResult = session?['session_type'] == 'points';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: BWSpacing.maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BWSpacing.lg),
                child: Column(
                  children: [
                    _buildScanArea(provider, isLoggedIn, authProvider)
                        .animate()
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: BWSpacing.xl),
                    if (isSuccess && isPointsResult)
                      _buildPointsResult(session!),
                    if (isSuccess && !isPointsResult)
                      _buildVoucherResult(result),
                    if (provider.errorMessage != null)
                      _buildErrorBanner(provider.errorMessage!),
                    const SizedBox(height: BWSpacing.lg),
                    _buildInfoSection(context, isLoggedIn)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 200.ms),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Navigate back intelligently: logged-in → dashboard, guest → home.
  void _navigateBack(BuildContext context, bool isLoggedIn) {
    final targetRoute =
        isLoggedIn ? '/user/dashboard' : '/user/home';

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  Widget _buildScanArea(
    BottleProvider provider,
    bool isLoggedIn,
    AuthProvider authProvider,
  ) {
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
              'Insert a Bottle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: BWSpacing.sm),
            Text(
              isLoggedIn
                  ? 'Tap to scan and earn credits'
                  : 'Tap the bottle icon to simulate a scan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: BWSpacing.xl),
            ScaleTransition(
              scale: _scaleAnim,
              child: GestureDetector(
                onTap: _isScanning
                    ? null
                    : () => _handleScan(provider, isLoggedIn, authProvider),
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isScanning
                        ? BWColors.divider
                        : BWColors.primary.withAlpha(25),
                    border: Border.all(
                      color: _isScanning ? BWColors.textHint : BWColors.primary,
                      width: 3,
                    ),
                  ),
                  child: _isScanning
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: BWColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.recycling,
                          size: 60,
                          color: BWColors.primary,
                        ),
                ),
              ),
            ),
            const SizedBox(height: BWSpacing.md),
            Text(
              _isScanning ? 'Processing...' : 'Tap to Scan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isScanning ? BWColors.textHint : BWColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherResult(Map<String, dynamic> result) {
    final session = result['session'] as Map<String, dynamic>?;
    if (session == null) return const SizedBox.shrink();

    final code = session['voucher_code'] as String? ?? '';
    final minutes = session['minutes_granted'] as int? ?? 0;

    return ScanResultCard(
      voucherCode: code,
      minutesGranted: minutes,
      onRedeem: () => Navigator.pushNamed(context, '/user/redeem'),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildPointsResult(Map<String, dynamic> session) {
    final credits = session['credits_earned'] as int? ?? 0;
    final total = session['total_credits'] as int? ?? 0;

    return PointsEarnedCard(
      creditsEarned: credits,
      totalCredits: total,
      onViewDashboard: () =>
          Navigator.pushReplacementNamed(context, '/user/dashboard'),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildErrorBanner(String message) {
    return Card(
          color: BWColors.error.withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
            side: const BorderSide(color: BWColors.error),
          ),
          child: Padding(
            padding: const EdgeInsets.all(BWSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: BWColors.error),
                const SizedBox(width: BWSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: BWColors.error),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms)
        .shake(hz: 2, offset: const Offset(4, 0));
  }

  Widget _buildInfoSection(BuildContext context, bool isLoggedIn) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Scanning Works',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: BWSpacing.md),
            const _InfoRow(
              icon: Icons.looks_one,
              text: 'Insert a plastic bottle into the machine',
            ),
            _InfoRow(
              icon: Icons.looks_two,
              text: isLoggedIn
                  ? 'Credits are added to your account'
                  : 'A unique voucher code is generated',
            ),
            _InfoRow(
              icon: Icons.looks_3,
              text: isLoggedIn
                  ? 'Use credits for WiFi minutes'
                  : 'Redeem the code for WiFi minutes',
            ),
            const _InfoRow(
              icon: Icons.info_outline,
              text: 'Limit: 10 scans per day',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleScan(
    BottleProvider provider,
    bool isLoggedIn,
    AuthProvider authProvider,
  ) async {
    setState(() => _isScanning = true);
    _animController.repeat(reverse: true);

    provider.clearMessages();

    if (isLoggedIn) {
      final userId = authProvider.user!.id;
      await provider.userScanBottle(
        userId: userId,
        machineIdentifier: 'default_machine',
      );

      // Sync updated credits into AuthProvider
      if (mounted) {
        final result = provider.lastScanResult;
        final session = result?['session'] as Map<String, dynamic>?;
        final total = session?['total_credits'] as int?;
        if (total != null) {
          authProvider.updateUserCredits(total);
        }
      }
    } else {
      await provider.guestScanBottle(machineIdentifier: 'default_machine');
    }

    if (!mounted) return;

    _animController.stop();
    _animController.reset();
    setState(() => _isScanning = false);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BWColors.primary),
          const SizedBox(width: BWSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
