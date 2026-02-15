import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/machine.dart';
import '../../providers/admin_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

/// Machine detail screen showing stats and info
class AdminMachineDetailScreen extends StatefulWidget {
  final Machine machine;

  const AdminMachineDetailScreen({super.key, required this.machine});

  @override
  State<AdminMachineDetailScreen> createState() =>
      _AdminMachineDetailScreenState();
}

class _AdminMachineDetailScreenState extends State<AdminMachineDetailScreen> {
  Machine get machine => widget.machine;

  Color get _statusColor {
    if (machine.isOnline) return AppColors.successColor;
    if (machine.isInMaintenance) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  String get _statusLabel {
    if (machine.isOnline) return 'Online';
    if (machine.isInMaintenance) return 'Maintenance';
    return 'Offline';
  }

  void _confirmDeleteMachine() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete_forever, color: Colors.red, size: 48),
        title: const Text('Delete Machine'),
        content: Text(
          'Are you sure you want to delete "${machine.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<AdminProvider>();
      final success = await provider.deleteMachine(machine.id);

      if (!mounted) return;

      if (success) {
        Helpers.showSnackbar(context, 'Machine deleted successfully');
        Navigator.pop(context); // Go back to machine list
      } else {
        Helpers.showSnackbar(
          context,
          provider.errorMessage ?? 'Failed to delete machine',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(machine.name),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status header
          _buildStatusHeader(),
          const SizedBox(height: 20),

          // Machine info
          _buildInfoCard(),
          const SizedBox(height: 16),

          // Statistics
          _buildStatsCard(),
          const SizedBox(height: 24),

          // Delete machine button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmDeleteMachine,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Delete Machine',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_statusColor, _statusColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.router, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machine.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Machine Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow('Machine ID', '#${machine.id}'),
            _infoRow(
              'MAC Address',
              machine.macAddress.isNotEmpty ? machine.macAddress : 'N/A',
            ),
            _infoRow(
              'IP Address',
              machine.ipAddress.isNotEmpty ? machine.ipAddress : 'N/A',
            ),
            _infoRow('Location', machine.location ?? 'Not set'),
            _infoRow(
              'Last Online',
              machine.lastOnline != null
                  ? Helpers.formatDateTime(machine.lastOnline!)
                  : 'Never',
            ),
            _infoRow('Created', Helpers.formatDateTime(machine.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _statItem(
                    Icons.recycling,
                    '${machine.totalBottlesProcessed}',
                    'Total Bottles',
                    AppColors.successColor,
                  ),
                ),
                Expanded(
                  child: _statItem(
                    Icons.timer,
                    '${machine.totalBottlesProcessed * 10}',
                    'Minutes Given',
                    AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
