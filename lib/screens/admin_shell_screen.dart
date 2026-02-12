import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../utils/constants.dart';
import 'admin_dashboard_screen.dart';
import 'admin_machine_management_screen.dart';
import 'admin_user_management_screen.dart';
import 'admin_voucher_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_settings_screen.dart';

/// Admin navigation shell with bottom navigation bar
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.router_outlined),
      selectedIcon: Icon(Icons.router),
      label: 'Machines',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Users',
    ),
    NavigationDestination(
      icon: Icon(Icons.confirmation_number_outlined),
      selectedIcon: Icon(Icons.confirmation_number),
      label: 'Vouchers',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardScreen(onSwitchTab: _switchToTab),
      const AdminMachineManagementScreen(),
      const AdminUserManagementScreen(),
      const AdminVoucherScreen(),
      const AdminAnalyticsScreen(),
    ];
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
    });
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _getTitle(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshCurrentTab,
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
              ),
              tooltip: 'Settings',
            ),
          ],
        ),
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: _destinations,
          backgroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.black26,
          indicatorColor: AppColors.primaryColor.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'Machine Management';
      case 2:
        return 'User Management';
      case 3:
        return 'Voucher Management';
      case 4:
        return 'Analytics';
      default:
        return 'Admin';
    }
  }

  void _refreshCurrentTab() {
    final provider = context.read<AdminProvider>();
    switch (_currentIndex) {
      case 0:
        provider.loadDashboardStats();
        break;
      case 1:
        provider.loadMachines();
        break;
      case 2:
        provider.loadUsers();
        break;
      case 3:
        provider.loadVouchers();
        break;
      case 4:
        provider.loadBottleLogs();
        break;
    }
  }
}
