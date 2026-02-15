import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../providers/insert_provider.dart';
import '../../services/credit_service.dart';
import '../../services/reward_dispatcher.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

/// User success screen: shows +20 credits earned, total balance,
/// and option to convert credits to a WiFi voucher (1 credit = 1 minute).
class UserCreditsScreen extends StatefulWidget {
  const UserCreditsScreen({super.key});

  @override
  State<UserCreditsScreen> createState() => _UserCreditsScreenState();
}

class _UserCreditsScreenState extends State<UserCreditsScreen> {
  bool _isConverting = false;
  String? _voucherCode;
  int? _voucherMinutes;
  double _sliderValue = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(
        backgroundColor: BWColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateToDashboard(context),
        ),
        title: const Text('+20 Credits!'),
      ),
      body: Consumer<InsertProvider>(
        builder: (context, provider, _) {
          final result = provider.rewardResult;
          return _buildBody(context, result);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, RewardResult? result) {
    final creditsEarned =
        result?.creditsEarned ?? AppConstants.creditsPerBottle;
    final totalCredits = result?.totalCredits ?? 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BWSpacing.lg),
          child: Column(
            children:
                [
                      _buildSuccessBadge(),
                      const SizedBox(height: BWSpacing.xl),
                      _buildCreditsCard(context, creditsEarned, totalCredits),
                      const SizedBox(height: BWSpacing.lg),
                      _buildConversionCard(context, totalCredits),
                      const SizedBox(height: BWSpacing.lg),
                      if (_voucherCode != null) _buildVoucherResult(context),
                      if (_voucherCode != null)
                        const SizedBox(height: BWSpacing.lg),
                      _buildActions(context),
                    ]
                    .animate(interval: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBadge() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BWColors.accent.withAlpha(25),
        border: Border.all(color: BWColors.accent, width: 3),
      ),
      child: const Icon(
        Icons.monetization_on,
        size: 56,
        color: BWColors.accent,
      ),
    ).animate().scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.0, 1.0),
      duration: 600.ms,
      curve: Curves.elasticOut,
    );
  }

  Widget _buildCreditsCard(
    BuildContext context,
    int creditsEarned,
    int totalCredits,
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
              '+$creditsEarned Credits!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: BWColors.primary,
              ),
            ),
            const SizedBox(height: BWSpacing.md),
            _buildBalanceChip(context, totalCredits),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceChip(BuildContext context, int totalCredits) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BWSpacing.lg,
        vertical: BWSpacing.md,
      ),
      decoration: BoxDecoration(
        color: BWColors.surfaceVariant,
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: BWColors.primary,
            size: 28,
          ),
          const SizedBox(width: BWSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '$totalCredits Credits',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: BWColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionCard(BuildContext context, int totalCredits) {
    final hasCredits = totalCredits >= AppConstants.minCreditsToConvert;

    // Clamp slider to available credits
    final maxSlider = totalCredits.toDouble().clamp(1.0, 999.0);
    if (_sliderValue > maxSlider) {
      _sliderValue = maxSlider;
    }

    final selectedMinutes =
        _sliderValue.round() * AppConstants.creditsToMinutesRatio;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: BWColors.secondary),
                const SizedBox(width: BWSpacing.sm),
                Expanded(
                  child: Text(
                    'Convert Credits to WiFi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BWSpacing.sm),
            Text(
              '1 credit = 1 minute WiFi access',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: BWColors.textSecondary),
            ),
            if (hasCredits && _voucherCode == null) ...[
              const SizedBox(height: BWSpacing.lg),
              _buildSliderSection(
                context,
                totalCredits,
                maxSlider,
                selectedMinutes,
              ),
            ],
            if (!hasCredits) ...[
              const SizedBox(height: BWSpacing.sm),
              Text(
                'Scan more bottles to earn credits!',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: BWColors.warning),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    BuildContext context,
    int totalCredits,
    double maxSlider,
    int selectedMinutes,
  ) {
    return Column(
      children: [
        // Display selected amount
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BWSpacing.lg,
            vertical: BWSpacing.md,
          ),
          decoration: BoxDecoration(
            color: BWColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_sliderValue.round()} credits',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BWColors.primary,
                ),
              ),
              const Icon(Icons.arrow_forward, color: BWColors.primary),
              Text(
                '$selectedMinutes min WiFi',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BWColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: BWSpacing.md),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: BWColors.primary,
            inactiveTrackColor: BWColors.primary.withAlpha(40),
            thumbColor: BWColors.primary,
            overlayColor: BWColors.primary.withAlpha(30),
            valueIndicatorColor: BWColors.primary,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Slider(
            value: _sliderValue.clamp(1.0, maxSlider),
            min: 1,
            max: maxSlider,
            divisions: (maxSlider - 1).toInt().clamp(1, 998),
            label: '${_sliderValue.round()} credits',
            onChanged: (value) => setState(() => _sliderValue = value),
          ),
        ),

        // Min / Max labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BWSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1', style: Theme.of(context).textTheme.bodySmall),
              Text(
                '$totalCredits',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: BWSpacing.lg),

        // Convert button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isConverting ? null : () => _convertCredits(context),
            icon: _isConverting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.swap_horiz),
            label: Text(
              _isConverting
                  ? 'Converting...'
                  : 'Convert ${_sliderValue.round()} credits',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: BWColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherResult(BuildContext context) {
    return Card(
      elevation: BWSpacing.cardElevation,
      color: BWColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: BWColors.success, size: 40),
            const SizedBox(height: BWSpacing.sm),
            Text(
              'Voucher Created!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: BWColors.success,
              ),
            ),
            const SizedBox(height: BWSpacing.sm),
            SelectableText(
              _voucherCode!,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: BWColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: BWSpacing.xs),
            Text(
              '$_voucherMinutes minutes WiFi access',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              final provider = context.read<InsertProvider>();
              provider.reset();
              Navigator.pushReplacementNamed(context, '/user/insert');
            },
            icon: const Icon(Icons.recycling),
            label: const Text('Continue Scanning'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BWColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: BWSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToDashboard(context),
            icon: const Icon(Icons.dashboard),
            label: const Text('Go to Dashboard'),
          ),
        ),
      ],
    );
  }

  Future<void> _convertCredits(BuildContext context) async {
    setState(() => _isConverting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        if (!mounted) return;
        _showSnack('User not found. Please login again.', BWColors.error);
        return;
      }

      final creditsToSpend = _sliderValue.round();
      final code = await CreditService.instance.convertToVoucher(
        userId: userId,
        creditsToSpend: creditsToSpend,
      );

      if (!mounted) return;

      if (code != null) {
        final minutes = creditsToSpend * AppConstants.creditsToMinutesRatio;
        setState(() {
          _voucherCode = code;
          _voucherMinutes = minutes;
        });

        // Refresh credit balance in global provider
        context.read<CreditProvider>().fetchBalance();

        _showSnack('Voucher created: $minutes min WiFi!', BWColors.success);
      } else {
        _showSnack('Insufficient credits', BWColors.warning);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Conversion failed: $e', BWColors.error);
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToDashboard(BuildContext context) {
    final provider = context.read<InsertProvider>();
    provider.reset();

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/user/dashboard');
    }
  }
}
