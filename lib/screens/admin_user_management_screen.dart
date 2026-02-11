import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// User management screen for admin
class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _searchController = TextEditingController();
  String _filter = 'all'; // all, active, suspended

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<User> _getFilteredUsers(List<User> users) {
    var filtered = users;
    if (_filter == 'active') {
      filtered = filtered.where((u) => !u.isSuspended).toList();
    } else if (_filter == 'suspended') {
      filtered = filtered.where((u) => u.isSuspended).toList();
    }
    return filtered;
  }

  void _showSuspendDialog(User user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suspend ${user.name}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter suspension reason',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<AdminProvider>().suspendUser(
                user.id,
                reason,
              );
              if (mounted) {
                Helpers.showSnackbar(
                  context,
                  success
                      ? '${user.name} has been suspended'
                      : 'Failed to suspend user',
                  isError: !success,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _showAdjustCreditsDialog(User user) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adjust Credits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current credits: ${user.credits}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: 'Positive to add, negative to deduct',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter reason for adjustment',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text.trim());
              final reason = reasonController.text.trim();
              if (amount == null || reason.isEmpty) return;
              Navigator.pop(ctx);
              final success = await context.read<AdminProvider>().adjustCredits(
                user.id,
                amount,
                reason,
              );
              if (mounted) {
                Helpers.showSnackbar(
                  context,
                  success
                      ? 'Credits adjusted for ${user.name}'
                      : 'Failed to adjust credits',
                  isError: !success,
                );
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to permanently delete ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<AdminProvider>().deleteUser(
                user.id,
              );
              if (mounted) {
                Helpers.showSnackbar(
                  context,
                  success
                      ? '${user.name} has been deleted'
                      : 'Failed to delete user',
                  isError: !success,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, admin, _) {
        final users = _getFilteredUsers(admin.filteredUsers);

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            admin.setUserSearchQuery('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) => admin.setUserSearchQuery(value),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    isSelected: _filter == 'active',
                    onTap: () => setState(() => _filter = 'active'),
                    color: AppColors.successColor,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Suspended',
                    isSelected: _filter == 'suspended',
                    onTap: () => setState(() => _filter = 'suspended'),
                    color: AppColors.errorColor,
                  ),
                  const Spacer(),
                  Text(
                    '${users.length} users',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // User list
            Expanded(
              child: admin.isLoading && admin.users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => admin.loadUsers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _UserCard(
                            user: user,
                            onSuspend: () => _showSuspendDialog(user),
                            onResume: () async {
                              final success = await admin.resumeUser(user.id);
                              if (mounted) {
                                Helpers.showSnackbar(
                                  context,
                                  success
                                      ? '${user.name} resumed'
                                      : 'Failed to resume user',
                                  isError: !success,
                                );
                              }
                            },
                            onAdjustCredits: () =>
                                _showAdjustCreditsDialog(user),
                            onDelete: () => _showDeleteDialog(user),
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
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Users Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? chipColor : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onSuspend;
  final VoidCallback onResume;
  final VoidCallback onAdjustCredits;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onSuspend,
    required this.onResume,
    required this.onAdjustCredits,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: user.isSuspended
                  ? AppColors.errorColor.withOpacity(0.1)
                  : AppColors.primaryColor.withOpacity(0.1),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: user.isSuspended
                      ? AppColors.errorColor
                      : AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${user.credits} credits',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: user.isSuspended
                              ? AppColors.errorColor.withOpacity(0.1)
                              : AppColors.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isSuspended ? 'Suspended' : 'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: user.isSuspended
                                ? AppColors.errorColor
                                : AppColors.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            if (!user.isAdmin)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'suspend':
                      onSuspend();
                    case 'resume':
                      onResume();
                    case 'credits':
                      onAdjustCredits();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  if (user.isSuspended)
                    const PopupMenuItem(
                      value: 'resume',
                      child: ListTile(
                        leading: Icon(
                          Icons.play_circle,
                          color: AppColors.successColor,
                        ),
                        title: Text('Resume'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'suspend',
                      child: ListTile(
                        leading: Icon(Icons.block, color: AppColors.errorColor),
                        title: Text('Suspend'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'credits',
                    child: ListTile(
                      leading: Icon(Icons.stars, color: Colors.amber),
                      title: Text('Adjust Credits'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_forever,
                        color: AppColors.errorColor,
                      ),
                      title: Text('Delete'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
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
