import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/credit_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

/// User profile screen — displays account details and credit balance.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: BWColors.background,
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please login to view your profile')),
      );
    }

    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: BWSpacing.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BWSpacing.lg),
            child: Column(
              children:
                  [
                        _buildAvatarSection(context, user),
                        const SizedBox(height: BWSpacing.lg),
                        _buildInfoCard(context, user),
                        const SizedBox(height: BWSpacing.lg),
                        _buildCreditCard(context),
                        const SizedBox(height: BWSpacing.xl),
                        _buildLogoutButton(context),
                      ]
                      .animate(interval: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, User user) {
    final initials = _extractInitials(user.name);

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: BWColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: BWColors.primary.withAlpha(60),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: BWSpacing.md),
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BWSpacing.xs),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, User user) {
    return Card(
      elevation: BWSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: BWSpacing.xl),
            _buildInfoRow(
              context,
              icon: Icons.person_outline,
              label: 'Name',
              value: user.name,
            ),
            const SizedBox(height: BWSpacing.md),
            _buildInfoRow(
              context,
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: BWSpacing.md),
              _buildInfoRow(
                context,
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phoneNumber!,
              ),
            ],
            const SizedBox(height: BWSpacing.md),
            _buildInfoRow(
              context,
              icon: Icons.badge_outlined,
              label: 'Role',
              value: user.role.toUpperCase(),
            ),
            const SizedBox(height: BWSpacing.md),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Member Since',
              value: Helpers.formatDateTime(user.createdAt),
            ),
            if (user.lastLoginAt != null) ...[
              const SizedBox(height: BWSpacing.md),
              _buildInfoRow(
                context,
                icon: Icons.login_outlined,
                label: 'Last Login',
                value: Helpers.formatDateTime(user.lastLoginAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: BWColors.primary),
        const SizedBox(width: BWSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCard(BuildContext context) {
    return Consumer<CreditProvider>(
      builder: (_, provider, _) {
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
                  size: 36,
                ),
                const SizedBox(height: BWSpacing.sm),
                Text(
                  '${provider.creditBalance} Credits',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: BWSpacing.xs),
                Text(
                  '1 credit = 1 minute WiFi',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout, color: BWColors.error),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: BWColors.error,
          side: const BorderSide(color: BWColors.error),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  String _extractInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
