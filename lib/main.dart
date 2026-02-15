import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/bottle_provider.dart';
import 'providers/credit_provider.dart';
import 'providers/insert_provider.dart';
import 'providers/machine_provider.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_settings_screen.dart';
import 'screens/admin/admin_shell_screen.dart';
import 'screens/shared/access_mode_screen.dart';
import 'screens/user/convert_credits_screen.dart';
import 'screens/user/forgot_password_screen.dart';
import 'screens/user/guest_scan_screen.dart';
import 'screens/user/guest_wifi_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/user/insert_screen.dart';
import 'screens/user/login_screen.dart';
import 'screens/user/profile_screen.dart';
import 'screens/user/register_screen.dart';
import 'screens/user/user_credits_screen.dart';
import 'screens/user/user_dashboard_screen.dart';
import 'screens/user/voucher_redeem_screen.dart';
import 'services/admin_api_service.dart';
import 'services/api_service.dart';
import 'services/database_helper.dart';
import 'services/guest_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';

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

      // Ignore transient WebGL / CanvasKit rendering errors on web.
      // These are non-fatal and should not replace the running app.
      final errorString = error.toString();
      final isRenderingError =
          errorString.contains('transferToImageBitmap') ||
          errorString.contains('WebGL') ||
          errorString.contains('OffscreenCanvas') ||
          errorString.contains('context is lost');
      if (kIsWeb && isRenderingError) {
        debugPrint('Ignored transient web rendering error.');
        return;
      }

      // Show crash on screen so we can read the error on the phone.
      runApp(CrashErrorApp(error: errorString));
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
    final guestService = GuestService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            apiService: apiService,
            storageService: storageService,
            guestService: guestService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BottleProvider(
            apiService: apiService,
            guestService: guestService,
          ),
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
        ChangeNotifierProvider(create: (_) => InsertProvider()),
      ],
      child: MaterialApp(
        title: 'Bottle WiFi Vendo',
        debugShowCheckedModeBanner: false,
        builder: (context, widget) {
          return widget ?? const SizedBox.shrink();
        },
        themeMode: ThemeMode.light,
        // Use the new emerald-green design system for user-facing app.
        // Admin screens retain their own inline styles.
        theme: buildAppTheme(),
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
          '/access': (context) => const AccessModeScreen(),
          // Admin routes
          '/admin/login': (context) => const AdminLoginScreen(),
          '/admin': (context) => const AdminShellScreen(),
          '/admin/settings': (context) => const AdminSettingsScreen(),
          // User routes
          '/user/home': (context) => const HomeScreen(),
          '/user/login': (context) => const LoginScreen(),
          '/user/forgot-password': (context) => const ForgotPasswordScreen(),
          '/user/register': (context) => const RegisterScreen(),
          '/user/guest-scan': (context) => const GuestScanScreen(),
          '/user/insert': (context) => const InsertScreen(),
          '/user/guest-wifi': (context) => const GuestWifiScreen(),
          '/user/credits-success': (context) => const UserCreditsScreen(),
          '/user/convert-credits': (context) => const ConvertCreditsScreen(),
          '/user/dashboard': (context) => const UserDashboardScreen(),
          '/user/profile': (context) => const ProfileScreen(),
          '/user/redeem': (context) => const VoucherRedeemScreen(),
        },
      ),
    );
  }
}

/// Splash screen with role-based routing.
/// Admin → AdminShellScreen, User → UserDashboard, else → AccessModeScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // Block admin access on web — redirect to user home instead.
      if (authProvider.isAdmin) {
        if (kIsWeb) {
          Navigator.of(context).pushReplacementNamed('/user/home');
          return;
        }
        Navigator.of(context).pushReplacementNamed('/admin');
        return;
      }
      // Regular user
      Navigator.of(context).pushReplacementNamed('/user/dashboard');
      return;
    }

    // Not authenticated — on web go straight to user home, on mobile
    // show access mode selection (which includes admin).
    if (kIsWeb) {
      Navigator.of(context).pushReplacementNamed('/user/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/access');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BWColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Bottle WiFi Vendo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withAlpha(200),
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
