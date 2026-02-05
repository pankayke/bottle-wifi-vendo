import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/credit_provider.dart';
import '../providers/machine_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Internet request button widget
class InternetRequestButton extends StatelessWidget {
  const InternetRequestButton({super.key});

  Future<void> _requestInternet(BuildContext context) async {
    final machineProvider = context.read<MachineProvider>();
    final creditProvider = context.read<CreditProvider>();

    // Check if there's already an active session
    if (creditProvider.hasActiveSession) {
      Helpers.showSnackbar(
        context,
        'You already have an active session',
        isError: true,
      );
      return;
    }

    // Get available machines
    final onlineMachines = machineProvider.onlineMachines;
    if (onlineMachines.isEmpty) {
      Helpers.showSnackbar(
        context,
        'No machines available. Please try again later.',
        isError: true,
      );
      return;
    }

    // Show machine selection dialog
    final selectedMachine = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Machine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: onlineMachines.map((machine) {
            return ListTile(
              title: Text(machine.name),
              subtitle: Text(machine.location ?? ''),
              leading: Icon(Icons.router, color: AppColors.accentColor),
              onTap: () => Navigator.of(context).pop(machine.id),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedMachine == null || !context.mounted) return;

    // Show duration selection dialog
    final selectedMinutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [15, 30, 60, 120].map((minutes) {
            return ListTile(
              title: Text(Helpers.formatCredits(minutes)),
              trailing: Text(
                '$minutes credits',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              onTap: () => Navigator.of(context).pop(minutes),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedMinutes == null || !context.mounted) return;

    // Request internet access
    Helpers.showLoadingDialog(context);

    final success = await creditProvider.requestInternet(
      machineId: selectedMachine,
      minutes: selectedMinutes,
    );

    if (context.mounted) {
      Helpers.hideLoadingDialog(context);

      if (success) {
        Helpers.showSnackbar(context, 'Internet access granted successfully!');
      } else {
        Helpers.showSnackbar(
          context,
          creditProvider.errorMessage ?? 'Failed to request internet access',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CreditProvider>(
      builder: (context, creditProvider, child) {
        final hasActiveSession = creditProvider.hasActiveSession;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: hasActiveSession
                ? null
                : () => _requestInternet(context),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
            ),
            icon: const Icon(Icons.wifi, size: 24),
            label: Text(
              hasActiveSession ? 'Session Active' : 'Request Internet Access',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
