import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/validators.dart';

/// Forgot Password screen.
/// User enters their email → if it exists in the DB the password
/// is reset to "password" and displayed on screen.
/// No email / OTP required.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isResetDone = false;
  String? _errorMessage;

  static const String _defaultPassword = 'password';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(
        backgroundColor: BWColors.primary,
        title: const Text('Forgot Password'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BWSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: BWSpacing.maxContentWidth,
            ),
            child: _isResetDone
                ? _buildSuccessCard(context)
                : _buildResetForm(context),
          ),
        ),
      ),
    );
  }

  // ───────────────────── Reset Form ─────────────────────────

  Widget _buildResetForm(BuildContext context) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset, size: 56, color: BWColors.primary),
              const SizedBox(height: BWSpacing.md),
              Text(
                'Reset Password',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: BWSpacing.sm),
              Text(
                'Enter your registered email address.\n'
                'Your password will be reset instantly.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: BWSpacing.lg),
              if (_errorMessage != null) _buildErrorBanner(_errorMessage!),
              TextFormField(
                controller: _emailController,
                validator: Validators.validateEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
                  ),
                ),
              ),
              const SizedBox(height: BWSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BWColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Reset My Password'),
                ),
              ),
              const SizedBox(height: BWSpacing.md),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  // ───────────────────── Success Card ─────────────────────────

  Widget _buildSuccessCard(BuildContext context) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BWColors.success.withAlpha(25),
                border: Border.all(color: BWColors.success, width: 3),
              ),
              child: const Icon(Icons.check, size: 44, color: BWColors.success),
            ),
            const SizedBox(height: BWSpacing.lg),
            Text(
              'Password Reset!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: BWColors.success,
              ),
            ),
            const SizedBox(height: BWSpacing.md),
            Text(
              'Your new password is:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: BWSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: BWSpacing.md,
                horizontal: BWSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: BWColors.surfaceVariant,
                borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
                border: Border.all(color: BWColors.primary.withAlpha(60)),
              ),
              child: Center(
                child: SelectableText(
                  _defaultPassword,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: BWColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: BWSpacing.md),
            Text(
              'Please change it after logging in.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BWColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: BWSpacing.xl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/user/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BWColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  // ───────────────────── Error Banner ─────────────────────────

  Widget _buildErrorBanner(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BWSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BWSpacing.sm + 4),
        decoration: BoxDecoration(
          color: BWColors.error.withAlpha(20),
          borderRadius: BorderRadius.circular(BWSpacing.inputRadius),
          border: Border.all(color: BWColors.error.withAlpha(100)),
        ),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: BWColors.error),
        ),
      ),
    );
  }

  // ───────────────────── Reset Logic ─────────────────────────

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.apiService.forgotPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isResetDone = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
