import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite factory based on platform.
  // Android/iOS use native sqflite; desktop uses FFI; web uses FFI-web.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize the local SQLite database (creates tables, seeds admin).
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
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
