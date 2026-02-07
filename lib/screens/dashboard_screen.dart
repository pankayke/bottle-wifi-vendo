import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/bottle_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/machine_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'bottle_history_screen.dart';
import 'bottle_scanning_screen.dart';
import 'bottle_success_screen.dart';
import 'machine_status_screen.dart';
import 'login_screen.dart';

/// Main dashboard screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final creditProvider = context.read<CreditProvider>();
    final bottleProvider = context.read<BottleProvider>();
    final machineProvider = context.read<MachineProvider>();

    await Future.wait([
      creditProvider.fetchCredits(),
      creditProvider.fetchActiveSession(),
      bottleProvider.fetchStatistics(),
      machineProvider.fetchMachineStatus(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _handleLogout() async {
    final confirm = await Helpers.showConfirmationDialog(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
    );

    if (confirm && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _navigateToBottleHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BottleHistoryScreen()),
    );
  }

  void _navigateToMachineStatus() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MachineStatusScreen()),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final secs = 0; // We don't track seconds, so always show 0
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _requestInternet(BuildContext context) async {
    final creditProvider = context.read<CreditProvider>();

    if (creditProvider.isLoading) return;

    // Use first available machine (or get from provider)
    final success = await creditProvider.requestInternet(
      machineId: 1,
      minutes: 30, // Default 30 minutes
    );

    if (!mounted) return;

    if (success) {
      Helpers.showSnackbar(
        context,
        'WiFi session started successfully!',
        isError: false,
      );
    } else {
      Helpers.showSnackbar(
        context,
        creditProvider.errorMessage ?? 'Failed to start WiFi session',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/school_logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.school,
                      size: 20,
                      color: AppColors.primaryColor,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Bottle-Wifi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _refreshData,
                child: Row(
                  children: const [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: _handleLogout,
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // WiFi Timer Card
              Consumer<CreditProvider>(
                builder: (context, creditProvider, child) {
                  final session = creditProvider.activeSession;
                  final hasActiveSession = session != null;

                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          hasActiveSession
                              ? 'REMAINING WIFI TIME'
                              : 'WIFI INACTIVE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasActiveSession
                              ? _formatDuration(session.remainingMinutes)
                              : '00:00:00',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (hasActiveSession)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.wifi, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'WiFi Active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!hasActiveSession)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Start session to connect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Stats Row
              Consumer2<CreditProvider, BottleProvider>(
                builder: (context, creditProvider, bottleProvider, child) {
                  final stats = bottleProvider.statistics;
                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value:
                              '${creditProvider.credits?.remainingMinutes ?? 0}',
                          label: 'WiFi Credits',
                          icon: Icons.wifi,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          value: '${stats?.totalBottles ?? 0}',
                          label: 'Bottles Recycled',
                          icon: Icons.recycling,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Ready to Insert Bottle Button
              InkWell(
                onTap: () {
                  // Navigate to guest bottle scan or show demo
                  Navigator.pushNamed(context, '/guest-scan');
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.1),
                        AppColors.primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_drink,
                          size: 48,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ready to Insert Bottle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Place a bottle in the machine',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.history,
                      label: 'History',
                      onTap: _navigateToBottleHistory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.router,
                      label: 'Machines',
                      onTap: _navigateToMachineStatus,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Consumer<CreditProvider>(
                      builder: (context, creditProvider, child) {
                        return _ActionButton(
                          icon: Icons.play_circle_filled,
                          label: 'Start WiFi',
                          color: Colors.green,
                          onTap: () => _requestInternet(context),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primaryColor;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(icon, color: buttonColor, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: buttonColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
