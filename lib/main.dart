import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/bottle_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/machine_provider.dart';
import 'screens/access_mode_selection_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/guest_bottle_scan_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/optional_registration_screen.dart';
import 'screens/voucher_entry_screen.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sentry disabled for development - configure DSN before production
  // await SentryFlutter.init((options) {
  //   options.dsn = 'YOUR_SENTRY_DSN_HERE';
  // }, appRunner: () => runApp(const MyApp()));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final storageService = StorageService();
    final apiService = ApiService(storageService: storageService);

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
      ],
      child: MaterialApp(
        title: 'Bottle WiFi Vendo',
        debugShowCheckedModeBanner: false,
        // Add Sentry's navigation observer for performance tracking
        navigatorObservers: [SentryNavigatorObserver()],
        // Wrap the app with Sentry's error boundary
        builder: (context, widget) {
          return widget ?? const SizedBox.shrink();
        },
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor,
            primary: AppColors.primaryColor,
            secondary: AppColors.accentColor,
            error: AppColors.errorColor,
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
        ),
        // Named routes for navigation
        routes: {
          '/': (context) => const SplashScreen(),
          '/access-selection': (context) => const AccessModeSelectionScreen(),
          '/login': (context) => const LoginScreen(),
          '/guest-scan': (context) => const GuestBottleScanScreen(),
          '/voucher-entry': (context) => const VoucherEntryScreen(),
          '/dashboard': (context) => const HomeDashboardScreen(),
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

    // NEW BEHAVIOR: Always show access mode selection first
    // Login is optional, not required
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AccessModeSelectionScreen(),
      ),
    );

    // OLD BEHAVIOR (commented out):
    // if (authProvider.isAuthenticated) {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: (context) => const HomeDashboardScreen()),
    //   );
    // } else {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: (context) => const LoginScreen()),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Bottle WiFi Vendo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
