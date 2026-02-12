import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/machine_provider.dart';
import '../utils/constants.dart';
import '../widgets/machine_card.dart';

/// Machine status monitoring screen
class MachineStatusScreen extends StatefulWidget {
  const MachineStatusScreen({super.key});

  @override
  State<MachineStatusScreen> createState() => _MachineStatusScreenState();
}

class _MachineStatusScreenState extends State<MachineStatusScreen> {
  @override
  void initState() {
    super.initState();
    // Defer provider calls to avoid notifyListeners() during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      context.read<MachineProvider>().startAutoRefresh();
    });
  }

  @override
  void dispose() {
    // Stop auto-refresh when leaving screen
    context.read<MachineProvider>().reset();
    super.dispose();
  }

  Future<void> _loadData() async {
    final machineProvider = context.read<MachineProvider>();
    await machineProvider.fetchMachineStatus();
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Machine Status'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Consumer<MachineProvider>(
        builder: (context, machineProvider, child) {
          if (machineProvider.machines.isEmpty && machineProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (machineProvider.machines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.router_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No machines found',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final healthSummary = machineProvider.machineHealthSummary;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                // Health summary
                Container(
                  color: AppColors.cardBackground,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HealthItem(
                        label: 'Online',
                        value: healthSummary['online'].toString(),
                        color: AppColors.successColor,
                        icon: Icons.check_circle,
                      ),
                      _HealthItem(
                        label: 'Offline',
                        value: healthSummary['offline'].toString(),
                        color: AppColors.errorColor,
                        icon: Icons.cancel,
                      ),
                      _HealthItem(
                        label: 'Maintenance',
                        value: healthSummary['maintenance'].toString(),
                        color: AppColors.warningColor,
                        icon: Icons.build,
                      ),
                    ],
                  ),
                ),

                // Machine list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: machineProvider.machines.length,
                    itemBuilder: (context, index) {
                      final machine = machineProvider.machines[index];
                      return MachineCard(machine: machine);
                    },
                  ),
                ),

                // Total bottles processed
                Container(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.recycling, color: AppColors.accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'Total Bottles: ${machineProvider.totalBottlesProcessed}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _HealthItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
