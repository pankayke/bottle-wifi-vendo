import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/bottle_provider.dart';
import '../../providers/credit_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import '../../widgets/action_card.dart';
import '../../widgets/credit_balance_card.dart';

/// Authenticated user dashboard — credits, scan history, profile.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final creditProvider = context.read<CreditProvider>();
    final bottleProvider = context.read<BottleProvider>();

    await Future.wait([
      creditProvider.fetchBalance(),
      bottleProvider.loadBottleHistory(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: BWColors.background,
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: Text('Please login to view your dashboard')),
      );
    }

    return Scaffold(
      backgroundColor: BWColors.background,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: BWSpacing.maxContentWidth,
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(BWSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context, user.name),
                  const SizedBox(height: BWSpacing.lg),
                  Consumer<CreditProvider>(
                    builder: (_, provider, _) => CreditBalanceCard(
                      balance: provider.creditBalance,
                      isLoading: provider.isLoading,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                  const SizedBox(height: BWSpacing.lg),
                  _buildQuickActions(context),
                  const SizedBox(height: BWSpacing.lg),
                  _buildBottleHistory(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String name) {
    return Text(
      'Hello, $name',
      style: Theme.of(context).textTheme.headlineLarge,
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        ActionCard(
          icon: Icons.recycling,
          title: 'Scan a Bottle',
          subtitle: 'Earn +20 credits by recycling',
          onTap: () => Navigator.pushNamed(context, '/user/insert'),
          variant: ActionCardVariant.primary,
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.05),
        const SizedBox(height: BWSpacing.sm),
        ActionCard(
          icon: Icons.swap_horiz,
          title: 'Convert Credits',
          subtitle: '1 credit = 1 minute WiFi access',
          onTap: () => Navigator.pushNamed(context, '/user/convert-credits'),
          variant: ActionCardVariant.secondary,
        ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideY(begin: 0.05),
        const SizedBox(height: BWSpacing.sm),
        ActionCard(
          icon: Icons.confirmation_num_rounded,
          title: 'Redeem Voucher',
          subtitle: 'Add WiFi credits with a voucher code',
          onTap: () => Navigator.pushNamed(context, '/user/redeem'),
          variant: ActionCardVariant.outlined,
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.05),
      ],
    );
  }

  Widget _buildBottleHistory(BuildContext context) {
    return Consumer<BottleProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Scans',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: BWSpacing.md),
            if (provider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(BWSpacing.xl),
                  child: CircularProgressIndicator(color: BWColors.primary),
                ),
              )
            else if (provider.bottleLogs.isEmpty)
              _buildEmptyHistory(context)
            else
              ...provider.bottleLogs.map((log) => _buildLogTile(context, log)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BWSpacing.xl),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.history_rounded,
                size: 48,
                color: BWColors.textHint,
              ),
              const SizedBox(height: BWSpacing.md),
              Text(
                'No scan history yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BWColors.textSecondary,
                ),
              ),
              const SizedBox(height: BWSpacing.xs),
              Text(
                'Start scanning bottles to earn credits!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildLogTile(BuildContext context, dynamic log) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: BWSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: BWColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.recycling, color: BWColors.primary, size: 22),
        ),
        title: Text(
          log.machineName ?? 'Machine #${log.machineId}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          Helpers.formatDateTime(log.createdAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '+${log.creditsAwarded} credits',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: BWColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'logout':
        _handleLogout();
        break;
      case 'profile':
        Navigator.pushNamed(context, '/user/profile');
        break;
    }
  }

  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logout();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }
}
