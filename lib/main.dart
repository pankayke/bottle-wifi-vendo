import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bottle_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/machine_provider.dart';
import 'screens/access_mode_selection_screen.dart';
import 'screens/admin_shell_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guest_bottle_scan_screen.dart';
import 'screens/login_screen.dart';
import 'screens/voucher_entry_screen.dart';
import 'services/admin_api_service.dart';
import 'services/api_service.dart';
import 'services/database_helper.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // Catch all unhandled async errors and Flutter framework errors so the app
  // doesn't silently crash — instead errors are shown on screen.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Forward Flutter framework errors (widget build errors, etc.)
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exception}\n${details.stack}');
      };

      // Initialize the local SQLite database (creates tables, seeds admin).
      // On Android the sqflite plugin handles SQLite natively — no setup needed.
      try {
        await DatabaseHelper.instance.database;
      } catch (e, stack) {
        debugPrint('Database initialization failed: $e\n$stack');
        // Show a visible error instead of crashing silently.
        runApp(CrashErrorApp(error: 'DB Init Failed: $e'));
        return;
      }

      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error\n$stack');
      // Show crash on screen so we can read the error on the phone.
      runApp(CrashErrorApp(error: error.toString()));
    },
  );
}

/// Minimal error screen shown when the app fails to start.
/// Displays the error message on screen so it can be read on a
/// physical device without needing logcat.
class CrashErrorApp extends StatelessWidget {
  final String error;
  const CrashErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'App Crash Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final storageService = StorageService();
    final apiService = ApiService(storageService: storageService);
    final adminApiService = AdminApiService(storageService: storageService);

    return MultiProvider(
      providers: [
        // Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BottleProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CreditProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => MachineProvider(apiService: apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(adminApiService: adminApiService),
        ),
      ],
      child: MaterialApp(
        title: 'Bottle WiFi Vendo',
        debugShowCheckedModeBanner: false,
        builder: (context, widget) {
          return widget ?? const SizedBox.shrink();
        },
        themeMode: ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor,
            primary: AppColors.primaryColor,
            secondary: AppColors.accentColor,
            error: AppColors.errorColor,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.backgroundColor,
          cardTheme: const CardThemeData(
            elevation: AppConstants.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppConstants.defaultBorderRadius),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.defaultBorderRadius,
              ),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
        ),
        // On web hard refresh, always start from SplashScreen for auth check
        // regardless of the current URL hash (e.g. /#/login).
        onGenerateInitialRoutes: (String initialRoute) {
          return [
            MaterialPageRoute(
              settings: const RouteSettings(name: '/'),
              builder: (_) => const SplashScreen(),
            ),
          ];
        },
        routes: {
          '/': (context) => const SplashScreen(),
          '/access-selection': (context) => const AccessModeSelectionScreen(),
          '/login': (context) => const LoginScreen(),
          '/guest-scan': (context) => const GuestBottleScanScreen(),
          '/voucher-entry': (context) => const VoucherEntryScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/admin': (context) => const AdminShellScreen(),
        },
      ),
    );
  }
}

/// Splash screen with authentication check
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay initialization until after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // Redirect based on user role
      if (authProvider.user?.isAdmin == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminShellScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
      return;
    }

    // Not authenticated — show access mode selection
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AccessModeSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi, size: 100, color: Colors.white),
            SizedBox(height: 24),
            Text(
              'Bottle WiFi Vendo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
