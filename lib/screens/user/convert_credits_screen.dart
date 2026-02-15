import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../services/credit_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

/// Standalone screen for converting credits into WiFi vouchers.
/// Accessible from the dashboard. 1 credit = 1 minute WiFi.
class ConvertCreditsScreen extends StatefulWidget {
  const ConvertCreditsScreen({super.key});

  @override
  State<ConvertCreditsScreen> createState() => _ConvertCreditsScreenState();
}

class _ConvertCreditsScreenState extends State<ConvertCreditsScreen> {
  bool _isConverting = false;
  String? _voucherCode;
  int? _voucherMinutes;
  double _sliderValue = 1;

  @override
  void initState() {
    super.initState();
    _refreshBalance();
  }

  Future<void> _refreshBalance() async {
    await context.read<CreditProvider>().fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(
        backgroundColor: BWColors.primary,
        title: const Text('Convert Credits'),
      ),
      body: Consumer<CreditProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: BWColors.primary),
            );
          }
          return _buildBody(context, provider.creditBalance);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, int balance) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: BWSpacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BWSpacing.lg),
          child: Column(
            children:
                [
                      _buildBalanceHeader(context, balance),
                      const SizedBox(height: BWSpacing.lg),
                      _buildConversionCard(context, balance),
                      const SizedBox(height: BWSpacing.lg),
                      if (_voucherCode != null) _buildVoucherResult(context),
                    ]
                    .animate(interval: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(BuildContext context, int balance) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BWSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
          gradient: BWColors.primaryGradient,
        ),
        child: Column(
          children: [
            const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: BWSpacing.md),
            Text(
              '$balance Credits',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: BWSpacing.xs),
            Text(
              '1 credit = 1 minute WiFi access',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionCard(BuildContext context, int balance) {
    final hasCredits = balance >= AppConstants.minCreditsToConvert;
    final maxSlider = balance.toDouble().clamp(1.0, 999.0);

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
                    'Choose Amount',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (hasCredits && _voucherCode == null) ...[
              const SizedBox(height: BWSpacing.lg),
              _buildSliderSection(context, balance, maxSlider, selectedMinutes),
            ],
            if (!hasCredits) ...[
              const SizedBox(height: BWSpacing.lg),
              const Icon(Icons.info_outline, color: BWColors.warning, size: 40),
              const SizedBox(height: BWSpacing.sm),
              Text(
                'No credits available',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: BWColors.warning),
              ),
              const SizedBox(height: BWSpacing.xs),
              Text(
                'Scan bottles to earn credits!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    BuildContext context,
    int balance,
    double maxSlider,
    int selectedMinutes,
  ) {
    return Column(
      children: [
        // Preview
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
              Text('$balance', style: Theme.of(context).textTheme.bodySmall),
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
            const Icon(Icons.check_circle, color: BWColors.success, size: 48),
            const SizedBox(height: BWSpacing.sm),
            Text(
              'Voucher Created!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: BWColors.success,
              ),
            ),
            const SizedBox(height: BWSpacing.md),
            SelectableText(
              _voucherCode!,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: BWColors.textPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: BWSpacing.xs),
            Text(
              '$_voucherMinutes minutes WiFi access',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: BWSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _voucherCode = null;
                    _voucherMinutes = null;
                    _sliderValue = 1;
                  });
                  _refreshBalance();
                },
                icon: const Icon(Icons.add),
                label: const Text('Convert More'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
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
        await context.read<CreditProvider>().fetchBalance();

        if (!mounted) return;
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
}
