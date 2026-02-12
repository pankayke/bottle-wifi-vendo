import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../services/device_fingerprint_service.dart';
import '../utils/constants.dart';

class VoucherEntryScreen extends StatefulWidget {
  const VoucherEntryScreen({super.key});

  @override
  State<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _VoucherEntryScreenState extends State<VoucherEntryScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;
  bool _isRedeeming = false;
  Map<String, dynamic>? _validationResult;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _formatVoucherCode(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length && i < 12; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _validationResult = null;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'vouchers',
        where: 'code = ?',
        whereArgs: [code],
      );

      if (!mounted) return;

      if (rows.isNotEmpty) {
        final voucher = rows.first;
        final status = voucher['status'] as String? ?? 'active';

        if (status == 'active') {
          // Check expiry
          final expiresAt = voucher['expires_at'] as String?;
          if (expiresAt != null &&
              DateTime.now().isAfter(DateTime.parse(expiresAt))) {
            setState(() {
              _errorMessage = 'This voucher has expired';
              _validationResult = null;
            });
          } else {
            setState(() {
              _validationResult = {
                'found': true,
                'minutes': voucher['minutes'],
                'type': voucher['type'],
              };
              _errorMessage = null;
            });
          }
        } else if (status == 'redeemed') {
          setState(() {
            _errorMessage = 'This voucher has already been used';
            _validationResult = null;
          });
        } else if (status == 'revoked') {
          setState(() {
            _errorMessage = 'This voucher has been revoked';
            _validationResult = null;
          });
        } else {
          setState(() {
            _errorMessage = 'This voucher is no longer valid';
            _validationResult = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid voucher code';
          _validationResult = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error validating voucher: $e';
        _validationResult = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  /// Determine if the error is about a duplicate/used voucher
  bool get _isDuplicateError =>
      _errorMessage != null &&
      (_errorMessage!.toLowerCase().contains('already') ||
          _errorMessage!.toLowerCase().contains('used'));

  /// Determine if the error is about an expired voucher
  bool get _isExpiredError =>
      _errorMessage != null && _errorMessage!.toLowerCase().contains('expired');

  /// Determine if the error is about a revoked voucher
  bool get _isRevokedError =>
      _errorMessage != null && _errorMessage!.toLowerCase().contains('revoked');

  /// Get the appropriate icon for the current error
  IconData _getErrorIcon() {
    if (_isDuplicateError) return Icons.block;
    if (_isExpiredError) return Icons.timer_off;
    if (_isRevokedError) return Icons.cancel;
    return Icons.error_outline;
  }

  /// Get the appropriate color for the current error
  Color _getErrorColor() {
    return AppColors.errorColor;
  }

  /// Get a short title for the current error
  String _getErrorTitle() {
    if (_isDuplicateError) return 'Voucher Already Used';
    if (_isExpiredError) return 'Voucher Expired';
    if (_isRevokedError) return 'Voucher Revoked';
    return 'Invalid Voucher';
  }

  Future<void> _redeemVoucher() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();

    setState(() {
      _isRedeeming = true;
      _errorMessage = null;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'vouchers',
        where: 'code = ?',
        whereArgs: [code],
      );

      if (!mounted) return;

      if (rows.isEmpty) {
        setState(() => _errorMessage = 'Invalid voucher code');
        return;
      }

      final voucher = rows.first;
      final status = voucher['status'] as String? ?? 'active';
      final minutes = voucher['minutes'] as int? ?? 0;

      if (status != 'active') {
        setState(() => _errorMessage = 'This voucher has already been $status');
        return;
      }

      // Check expiry
      final expiresAt = voucher['expires_at'] as String?;
      if (expiresAt != null &&
          DateTime.now().isAfter(DateTime.parse(expiresAt))) {
        setState(() => _errorMessage = 'This voucher has expired');
        return;
      }

      // Mark voucher as redeemed
      final fingerprintService = DeviceFingerprintService();
      final deviceFingerprint = await fingerprintService.generateFingerprint();
      final now = DateTime.now().toIso8601String();

      await db.update(
        'vouchers',
        {
          'status': 'redeemed',
          'redeemed_at': now,
          'user_name': deviceFingerprint.substring(0, 8),
        },
        where: 'id = ?',
        whereArgs: [voucher['id']],
      );

      if (!mounted) return;

      _showSuccessDialog({
        'session': {
          'minutes_granted': minutes,
          'expires_at': DateTime.now()
              .add(Duration(minutes: minutes))
              .toIso8601String(),
        },
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error redeeming voucher: $e');
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    final session = data['session'];
    final minutes = session?['minutes_granted'] ?? 0;
    final expiresAt = session?['expires_at'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successColor.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 50,
                color: AppColors.successColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Voucher Redeemed!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have been granted $minutes minutes of WiFi access.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (expiresAt.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Expires: $expiresAt',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pop(); // go back
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logo
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/school_logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.school,
                              size: 80,
                              color: AppColors.primaryColor,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Redeem Voucher',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Enter your voucher code to get WiFi access',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Voucher Code Input
                  TextFormField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9\-]'),
                      ),
                      LengthLimitingTextInputFormatter(14), // XXXX-XXXX-XXXX
                    ],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: AppColors.textPrimary,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a voucher code';
                      }
                      final cleaned = value.replaceAll(
                        RegExp(r'[^A-Za-z0-9]'),
                        '',
                      );
                      if (cleaned.length < 8) {
                        return 'Voucher code is too short';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final formatted = _formatVoucherCode(value);
                      if (formatted != value) {
                        _codeController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                      // Clear previous validation when typing
                      if (_validationResult != null || _errorMessage != null) {
                        setState(() {
                          _validationResult = null;
                          _errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'XXXX-XXXX-XXXX',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: Colors.grey.shade300,
                      ),
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primaryColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getErrorColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getErrorColor().withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getErrorIcon(),
                            color: _getErrorColor(),
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getErrorTitle(),
                            style: TextStyle(
                              color: _getErrorColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _getErrorColor(),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Validation result
                  if (_validationResult != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: AppColors.successColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Valid Voucher',
                                style: TextStyle(
                                  color: AppColors.successColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_validationResult!['minutes'] != null)
                            Text(
                              '${_validationResult!['minutes']} minutes of WiFi',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          if (_validationResult!['type'] != null)
                            Text(
                              'Type: ${_validationResult!['type']}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Redeem Button
                  ElevatedButton(
                    onPressed: _isRedeeming ? null : _redeemVoucher,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                      elevation: 2,
                    ),
                    child: _isRedeeming
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Redeem Voucher',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Validate Button (secondary)
                  OutlinedButton(
                    onPressed: _isValidating ? null : _validateCode,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                    ),
                    child: _isValidating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Check Code First',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Help text
                  const Text(
                    'Voucher codes can be obtained from authorized staff.\nFormat: XXXX-XXXX-XXXX',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
