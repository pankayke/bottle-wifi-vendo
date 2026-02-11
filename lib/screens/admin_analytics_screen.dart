import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/bottle_log.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Analytics screen for admin - bottle logs, filters, export
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  DateTimeRange? _dateRange;
  int? _selectedMachineId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadBottleLogs();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _applyFilters();
    }
  }

  void _applyFilters() {
    context.read<AdminProvider>().loadBottleLogs(
      machineId: _selectedMachineId,
      from: _dateRange?.start,
      to: _dateRange?.end,
    );
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _selectedMachineId = null;
    });
    context.read<AdminProvider>().loadBottleLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        return Column(
          children: [
            // Filter bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDateRange,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _dateRange != null
                                ? '${Helpers.formatDate(_dateRange!.start)} - ${Helpers.formatDate(_dateRange!.end)}'
                                : 'Select Date Range',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_dateRange != null || _selectedMachineId != null)
                        IconButton(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: 'Clear Filters',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Summary row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryChip(
                        label: 'Total Records',
                        value: '${admin.bottleLogs.length}',
                        icon: Icons.list,
                        color: AppColors.primaryColor,
                      ),
                      _SummaryChip(
                        label: 'Credits',
                        value:
                            '${admin.bottleLogs.fold<int>(0, (sum, b) => sum + b.creditsAwarded)}',
                        icon: Icons.stars,
                        color: AppColors.warningColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Logs list
            Expanded(
              child: admin.isLoading && admin.bottleLogs.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : admin.bottleLogs.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => admin.loadBottleLogs(
                        machineId: _selectedMachineId,
                        from: _dateRange?.start,
                        to: _dateRange?.end,
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: admin.bottleLogs.length,
                        itemBuilder: (context, index) {
                          return _BottleLogRow(
                            log: admin.bottleLogs[index],
                            index: index + 1,
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Bottle Logs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bottle scan data will appear here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottleLogRow extends StatelessWidget {
  final BottleLog log;
  final int index;

  const _BottleLogRow({required this.log, required this.index});

  Color get _statusColor {
    switch (log.status) {
      case 'verified':
        return AppColors.successColor;
      case 'pending':
        return AppColors.warningColor;
      case 'rejected':
        return AppColors.errorColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Index
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.machineName ?? 'Machine #${log.machineId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Helpers.formatDateTime(log.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Credits
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${log.creditsAwarded} min',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.successColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    log.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
