import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/credit_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/credit_balance_card.dart';

/// Dedicated voucher redemption screen.
class VoucherRedeemScreen extends StatefulWidget {
  const VoucherRedeemScreen({super.key});

  @override
  State<VoucherRedeemScreen> createState() => _VoucherRedeemScreenState();
}

class _VoucherRedeemScreenState extends State<VoucherRedeemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(title: const Text('Redeem Voucher')),
      body: Consumer<CreditProvider>(
        builder: (context, provider, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: BWSpacing.maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BWSpacing.lg),
                child: Column(
                  children: [
                    _buildRedeemForm(
                      provider,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: BWSpacing.lg),
                    if (provider.successMessage != null)
                      _buildSuccessBanner(provider)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(begin: const Offset(0.95, 0.95)),
                    if (provider.errorMessage != null)
                      _buildErrorBanner(provider.errorMessage!)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .shake(hz: 2, offset: const Offset(4, 0)),
                    const SizedBox(height: BWSpacing.lg),
                    CreditBalanceCard(
                      balance: provider.creditBalance,
                      isLoading: provider.isLoading,
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRedeemForm(CreditProvider provider) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_num_rounded,
                    color: BWColors.primary,
                  ),
                  const SizedBox(width: BWSpacing.sm),
                  Text(
                    'Enter Voucher Code',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: BWSpacing.sm),
              Text(
                'Enter the 12-character code from your bottle scan receipt.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: BWSpacing.lg),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                validator: Validators.validateVoucherCode,
                decoration: InputDecoration(
                  hintText: 'XXXX-XXXX-XXXX',
                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
                  ),
                ),
                style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: BWSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () => _handleRedeem(provider),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Redeem Voucher'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner(CreditProvider provider) {
    final voucher = provider.lastRedeemedVoucher;
    return Card(
      color: BWColors.success.withAlpha(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
        side: const BorderSide(color: BWColors.success, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: BWColors.success.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 40,
                color: BWColors.success,
              ),
            ),
            const SizedBox(height: BWSpacing.md),
            Text(
              provider.successMessage ?? 'Voucher redeemed successfully!',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: BWColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (voucher != null) ...[
              const SizedBox(height: BWSpacing.sm),
              Text(
                '${voucher.minutes} minutes added to your account',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
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
    );
  }

  Future<void> _handleRedeem(CreditProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    provider.clearMessages();
    final success = await provider.redeemVoucher(
      code: _codeController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _codeController.clear();
    }
  }
}
