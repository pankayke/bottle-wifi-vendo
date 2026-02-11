import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/voucher.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Voucher management screen for admin
class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadVouchers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showGenerateDialog() {
    int selectedMinutes = 30;
    final options = [10, 30, 60, 120, 360];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle, color: AppColors.primaryColor),
                SizedBox(width: 8),
                Text('Generate Voucher'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select WiFi Minutes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((mins) {
                    final isSelected = selectedMinutes == mins;
                    return ChoiceChip(
                      label: Text(mins >= 60 ? '${mins ~/ 60}h' : '${mins}m'),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() => selectedMinutes = mins);
                      },
                      selectedColor: AppColors.primaryColor.withOpacity(0.2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will generate a unique voucher code worth $selectedMinutes minutes of WiFi access.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              Consumer<AdminProvider>(
                builder: (context, admin, _) => FilledButton.icon(
                  onPressed: admin.isLoading
                      ? null
                      : () async {
                          final voucher = await admin.generateVoucher(
                            minutes: selectedMinutes,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted && voucher != null) {
                            _showVoucherCreatedDialog(voucher);
                          } else if (mounted) {
                            Helpers.showSnackbar(
                              context,
                              admin.errorMessage ??
                                  'Failed to generate voucher',
                              isError: true,
                            );
                          }
                        },
                  icon: admin.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.confirmation_number),
                  label: const Text('Generate'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVoucherCreatedDialog(Voucher voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.successColor),
            SizedBox(width: 8),
            Text('Voucher Created!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Voucher Code',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    voucher.code,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${voucher.minutes} minutes of WiFi',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: voucher.code));
              Helpers.showSnackbar(context, 'Voucher code copied!');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Code'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Scaffold(
          body: Column(
            children: [
              // Tab bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Active (${admin.activeVouchers.length})'),
                    Tab(text: 'Redeemed (${admin.redeemedVouchers.length})'),
                    Tab(text: 'All (${admin.vouchers.length})'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: admin.isLoading && admin.vouchers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildVoucherList(admin.activeVouchers, admin),
                          _buildVoucherList(admin.redeemedVouchers, admin),
                          _buildVoucherList(admin.vouchers, admin),
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'generateVoucherFab',
            onPressed: _showGenerateDialog,
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Generate Voucher'),
          ),
        );
      },
    );
  }

  Widget _buildVoucherList(List<Voucher> vouchers, AdminProvider admin) {
    if (vouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'No Vouchers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => admin.loadVouchers(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          return _VoucherCard(
            voucher: vouchers[index],
            onRevoke: () async {
              final reasonController = TextEditingController();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Revoke Voucher?'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revoke voucher ${vouchers[index].code}? This cannot be undone.',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          hintText: 'Enter revocation reason',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
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
                      child: const Text('Revoke'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  Helpers.showSnackbar(
                    context,
                    'Please provide a reason',
                    isError: true,
                  );
                  return;
                }
                final success = await admin.revokeVoucher(
                  vouchers[index].id,
                  reason: reason,
                );
                if (mounted) {
                  Helpers.showSnackbar(
                    context,
                    success ? 'Voucher revoked' : 'Failed to revoke',
                    isError: !success,
                  );
                }
              }
              reasonController.dispose();
            },
            onCopy: () {
              Clipboard.setData(ClipboardData(text: vouchers[index].code));
              Helpers.showSnackbar(context, 'Code copied!');
            },
          );
        },
      ),
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onRevoke;
  final VoidCallback onCopy;

  const _VoucherCard({
    required this.voucher,
    required this.onRevoke,
    required this.onCopy,
  });

  Color get _statusColor {
    if (voucher.isRevoked) return AppColors.errorColor;
    if (voucher.isRedeemed) return AppColors.primaryColor;
    if (voucher.isExpired) return Colors.grey;
    return AppColors.successColor;
  }

  String get _statusLabel {
    if (voucher.isRevoked) return 'Revoked';
    if (voucher.isRedeemed) return 'Redeemed';
    if (voucher.isExpired) return 'Expired';
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.confirmation_number,
                    color: _statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${voucher.minutes} minutes',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (voucher.userName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Redeemed by: ${voucher.userName}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            if (voucher.redeemedAt != null) ...[
              Text(
                'Redeemed: ${Helpers.formatDateTime(voucher.redeemedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Created: ${Helpers.formatDateTime(voucher.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const Spacer(),
                if (voucher.isActive) ...[
                  InkWell(
                    onTap: onCopy,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy,
                        size: 18,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onRevoke,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete,
                        size: 18,
                        color: AppColors.errorColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
