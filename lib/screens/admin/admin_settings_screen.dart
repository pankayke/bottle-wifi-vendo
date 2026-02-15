import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Admin settings screen
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  void _showChangeEmailDialog() {
    final emailController = TextEditingController(
      text: context.read<AuthProvider>().user?.email ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.email, color: AppColors.primaryColor),
                SizedBox(width: 8),
                Text('Change Email'),
              ],
            ),
            content: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newEmail = emailController.text.trim();
                        if (newEmail.isEmpty || !newEmail.contains('@')) {
                          Helpers.showSnackbar(
                            context,
                            'Please enter a valid email',
                            isError: true,
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final authProvider = context.read<AuthProvider>();
                        final success = await authProvider.updateProfile(
                          email: newEmail,
                        );

                        if (!mounted) return;
                        if (ctx.mounted) Navigator.pop(ctx);

                        Helpers.showSnackbar(
                          context,
                          success
                              ? 'Email updated successfully'
                              : authProvider.errorMessage ??
                                    'Failed to update email',
                          isError: !success,
                        );
                      },
                child: Text(isSaving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        bool obscureCurrent = true;
        bool obscureNew = true;
        bool obscureConfirm = true;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock, color: AppColors.primaryColor),
                SizedBox(width: 8),
                Text('Change Password'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPwController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPwController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_open),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPwController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_open),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final currentPw = currentPwController.text.trim();
                  final newPw = newPwController.text.trim();
                  final confirmPw = confirmPwController.text.trim();

                  if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                    Helpers.showSnackbar(
                      context,
                      'Please fill in all fields',
                      isError: true,
                    );
                    return;
                  }
                  if (newPw.length < 8) {
                    Helpers.showSnackbar(
                      context,
                      'New password must be at least 8 characters',
                      isError: true,
                    );
                    return;
                  }
                  if (newPw != confirmPw) {
                    Helpers.showSnackbar(
                      context,
                      'Passwords do not match',
                      isError: true,
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  final authProvider = context.read<AuthProvider>();
                  final success = await authProvider.changePassword(
                    currentPassword: currentPw,
                    newPassword: newPw,
                    newPasswordConfirmation: confirmPw,
                  );

                  if (mounted) {
                    Helpers.showSnackbar(
                      context,
                      success
                          ? 'Password changed successfully'
                          : authProvider.errorMessage ??
                                'Failed to change password',
                      isError: !success,
                    );
                  }
                },
                child: const Text('Change Password'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDebugInfo(BuildContext context) async {
    final user = context.read<AuthProvider>().user;
    final storageService = StorageService();
    final token = await storageService.getToken();
    final isAuth = await storageService.isAuthenticated();
    final tokenExpiry = await storageService.getTokenExpiry();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('Debug Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _debugSection('Environment', {
                'Build Mode': kReleaseMode ? 'Release' : 'Debug',
                'Platform': kIsWeb ? 'Web' : 'Native',
                'Storage': 'Local SQLite Database',
              }),
              const Divider(),
              _debugSection('Authentication', {
                'Is Authenticated': isAuth.toString(),
                'Token Present': (token != null).toString(),
                'Token Preview': token != null
                    ? '${token.substring(0, token.length.clamp(0, 20))}...'
                    : 'null',
                'Token Expiry': tokenExpiry?.toIso8601String() ?? 'Not set',
              }),
              const Divider(),
              _debugSection('User', {
                'ID': user?.id.toString() ?? 'N/A',
                'Name': user?.name ?? 'N/A',
                'Email': user?.email ?? 'N/A',
                'Role': user?.role ?? 'N/A',
                'Credits': user?.credits.toString() ?? 'N/A',
                'Is Admin': user?.isAdmin.toString() ?? 'N/A',
                'Is Suspended': user?.isSuspended.toString() ?? 'N/A',
              }),
              const Divider(),
              _debugSection('App', {'Version': '1.0.0'}),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _debugSection(String title, Map<String, String> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        ...entries.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    e.key,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(e.value, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Application section
          const _SectionHeader(title: 'Application'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.storage,
            title: 'Data Storage',
            subtitle: 'Local SQLite Database (Standalone)',
            onTap: () {},
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'System'),
          _SettingsTile(
            icon: Icons.cleaning_services,
            title: 'Clear Cache',
            subtitle: 'Clear temporary data',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
            },
          ),
          _SettingsTile(
            icon: Icons.bug_report,
            title: 'Debug Mode',
            subtitle: 'View debug information',
            onTap: () => _showDebugInfo(context),
          ),

          const SizedBox(height: 16),
          const _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.email,
            title: 'Change Email',
            subtitle: user?.email ?? 'Update admin email address',
            onTap: () => _showChangeEmailDialog(),
          ),
          _SettingsTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update admin password',
            onTap: () => _showChangePasswordDialog(),
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of admin account',
            iconColor: AppColors.errorColor,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.errorColor,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (_) => false);
                }
              }
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Bottle WiFi Vendo Admin v1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primaryColor;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
