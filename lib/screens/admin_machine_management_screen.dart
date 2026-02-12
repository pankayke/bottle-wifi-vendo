import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/machine.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'admin_machine_detail_screen.dart';

/// Machine management screen for admin
class AdminMachineManagementScreen extends StatefulWidget {
  const AdminMachineManagementScreen({super.key});

  @override
  State<AdminMachineManagementScreen> createState() =>
      _AdminMachineManagementScreenState();
}

class _AdminMachineManagementScreenState
    extends State<AdminMachineManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadMachines();
    });
  }

  void _showAddMachineDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final macController = TextEditingController();
    final ipController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text('Add New Machine'),
          ],
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Machine Name *',
                    hintText: 'e.g., Vendo Machine #1',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    hintText: 'e.g., Building A, 1st Floor',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: macController,
                  decoration: const InputDecoration(
                    labelText: 'MAC Address',
                    hintText: 'e.g., AA:BB:CC:DD:EE:FF',
                    prefixIcon: Icon(Icons.wifi),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    hintText: 'e.g., 192.168.1.100',
                    prefixIcon: Icon(Icons.lan),
                  ),
                ),
              ],
            ),
          ),
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
                      if (!formKey.currentState!.validate()) return;
                      final success = await admin.createMachine(
                        name: nameController.text.trim(),
                        location: locationController.text.trim(),
                        macAddress: macController.text.trim().isNotEmpty
                            ? macController.text.trim()
                            : null,
                        ipAddress: ipController.text.trim().isNotEmpty
                            ? ipController.text.trim()
                            : null,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!context.mounted) return;
                      Helpers.showSnackbar(
                        context,
                        success
                            ? 'Machine added successfully!'
                            : admin.errorMessage ?? 'Failed to add machine',
                        isError: !success,
                      );
                    },
              icon: admin.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add Machine'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        if (admin.isLoading && admin.machines.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => admin.loadMachines(),
            child: admin.machines.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: admin.machines.length,
                    itemBuilder: (context, index) {
                      return _MachineCard(
                        machine: admin.machines[index],
                        onStatusChange: (status) {
                          admin.updateMachineStatus(
                            admin.machines[index].id,
                            status,
                          );
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminMachineDetailScreen(
                                machine: admin.machines[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'addMachineFab',
            onPressed: _showAddMachineDialog,
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Machine'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.router_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Machines Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first ESP32 vendo machine',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _MachineCard extends StatelessWidget {
  final Machine machine;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onTap;

  const _MachineCard({
    required this.machine,
    required this.onStatusChange,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.router, color: _statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (machine.location != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            machine.location!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem(
                    Icons.recycling,
                    '${machine.totalBottlesProcessed}',
                    'Bottles',
                  ),
                  _buildInfoItem(
                    Icons.access_time,
                    machine.lastOnline != null
                        ? Helpers.formatDateTime(machine.lastOnline!)
                        : 'Never',
                    'Last Seen',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatusChange(
                        machine.isActive ? 'maintenance' : 'active',
                      ),
                      icon: Icon(
                        machine.isActive ? Icons.build : Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text(
                        machine.isActive ? 'Maintenance' : 'Activate',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: machine.isActive
                            ? AppColors.warningColor
                            : AppColors.successColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text(
                        'Details',
                        style: TextStyle(fontSize: 12),
                      ),
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

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
