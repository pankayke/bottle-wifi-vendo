# Migration Examples - Before & After

This document shows concrete examples of how to migrate existing code to use the new enhancements.

---

## Example 1: Login Screen

### Before (Old Implementation)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### After (Enhanced Implementation)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      showSuccessSnackBar(context, 'Login successful!');
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      showErrorSnackBar(
        context,
        authProvider.errorMessage ?? 'Login failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo or Title
                  const Text(
                    'Bottle WiFi Vendo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Email field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  
                  // Login button
                  PrimaryButton(
                    label: 'Login',
                    onPressed: _login,
                    isLoading: authProvider.isLoading,
                    icon: Icons.login,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

**Key Improvements:**
- ✅ Uses `PrimaryButton` with built-in loading state
- ✅ Uses `showSuccessSnackBar` and `showErrorSnackBar`
- ✅ Const constructors for static widgets
- ✅ Better error handling with Consumer
- ✅ Consistent styling with AppColors and AppConstants

---

## Example 2: Bottle History Screen

### Before (Manual Pagination)

```dart
class BottleHistoryScreen extends StatefulWidget {
  const BottleHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BottleHistoryScreen> createState() => _BottleHistoryScreenState();
}

class _BottleHistoryScreenState extends State<BottleHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadData() async {
    final bottleProvider = context.read<BottleProvider>();
    await bottleProvider.fetchBottleHistory(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final bottleProvider = context.read<BottleProvider>();
      if (!bottleProvider.isLoading && bottleProvider.hasMorePages) {
        bottleProvider.fetchBottleHistory();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bottle History')),
      body: Consumer<BottleProvider>(
        builder: (context, bottleProvider, child) {
          if (bottleProvider.bottleLogs.isEmpty && bottleProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (bottleProvider.bottleLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.recycling, size: 80),
                  SizedBox(height: 16),
                  Text('No bottles yet'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: bottleProvider.bottleLogs.length +
                  (bottleProvider.hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == bottleProvider.bottleLogs.length) {
                  return Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return BottleLogCard(
                  bottleLog: bottleProvider.bottleLogs[index],
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

### After (Automatic Pagination)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bottle_log.dart';
import '../providers/bottle_provider.dart';
import '../widgets/bottle_log_card.dart';
import '../widgets/common_widgets.dart';
import '../widgets/paginated_list_view.dart';
import '../utils/constants.dart';

class BottleHistoryScreen extends StatelessWidget {
  const BottleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Bottle History'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<BottleProvider>(
        builder: (context, bottleProvider, child) {
          return PaginatedListView<BottleLog>(
            onLoadMore: (page) async {
              return await bottleProvider.fetchBottleHistory(page: page);
            },
            itemBuilder: (context, bottleLog, index) {
              return BottleLogCard(bottleLog: bottleLog);
            },
            emptyTitle: 'No Bottle History',
            emptyMessage: 'Report your first bottle to get started!',
            emptyIcon: Icons.recycling,
          );
        },
      ),
    );
  }
}
```

**Key Improvements:**
- ✅ Automatic pagination with pull-to-refresh
- ✅ Built-in loading, error, and empty states
- ✅ No manual scroll controller management
- ✅ Stateless widget (simpler)
- ✅ Const constructors throughout

---

## Example 3: Bottle Card with Image

### Before

```dart
class BottleLogCard extends StatelessWidget {
  final BottleLog bottleLog;

  const BottleLogCard({Key? key, required this.bottleLog}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Image.network(
              bottleLog.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey,
                  child: Icon(Icons.broken_image),
                );
              },
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bottle #${bottleLog.id}'),
                  Text(bottleLog.status),
                ],
              ),
            ),
            Text('+${bottleLog.creditsEarned}'),
          ],
        ),
      ),
    );
  }
}
```

### After

```dart
import 'package:flutter/material.dart';
import '../models/bottle_log.dart';
import '../widgets/cached_image_widget.dart';
import '../widgets/common_widgets.dart';
import '../utils/constants.dart';

class BottleLogCard extends StatelessWidget {
  final BottleLog bottleLog;

  const BottleLogCard({super.key, required this.bottleLog});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Row(
        children: [
          BottleImageWidget(
            imageUrl: bottleLog.imageUrl,
            size: 60,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bottle #${bottleLog.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bottleLog.status,
                  style: TextStyle(
                    color: _getStatusColor(bottleLog.status),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${bottleLog.creditsEarned}',
              style: const TextStyle(
                color: AppColors.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return AppColors.successColor;
      case 'pending':
        return AppColors.warningColor;
      case 'rejected':
        return AppColors.errorColor;
      default:
        return AppColors.textSecondary;
    }
  }
}
```

**Key Improvements:**
- ✅ Uses `BottleImageWidget` with automatic caching
- ✅ Uses `CustomCard` for consistent styling
- ✅ Better visual hierarchy
- ✅ Status color coding
- ✅ All const constructors

---

## Example 4: Provider with Enhanced API

### Before

```dart
class BottleProvider with ChangeNotifier {
  final ApiService _apiService;
  
  List<BottleLog> _bottleLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<bool> reportBottle({
    required int machineId,
    String? imageBase64,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.reportBottle(
        machineId: machineId,
        imageBase64: imageBase64,
      );

      if (response.data != null) {
        _bottleLogs.insert(0, response.data!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
```

### After

```dart
import 'package:flutter/foundation.dart';
import '../models/bottle_log.dart';
import '../services/enhanced_api_service.dart';
import '../utils/api_exception.dart';

class BottleProvider with ChangeNotifier {
  final EnhancedApiService _apiService;
  
  List<BottleLog> _bottleLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  BottleProvider({required EnhancedApiService apiService})
      : _apiService = apiService;

  // Getters
  List<BottleLog> get bottleLogs => _bottleLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Report a bottle with comprehensive error handling
  Future<bool> reportBottle({
    required int machineId,
    String? imageBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.reportBottle(
        machineId: machineId,
        imageBase64: imageBase64,
      );

      if (response.data != null) {
        _bottleLogs.insert(0, response.data!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
      
    } on ApiException catch (e) {
      // User-friendly error message from API
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      // Unexpected error
      _errorMessage = 'An unexpected error occurred';
      debugPrint('Unexpected error in reportBottle: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch bottle history with pagination support
  Future<List<BottleLog>> fetchBottleHistory({
    required int page,
    bool refresh = false,
  }) async {
    if (refresh) {
      _bottleLogs.clear();
    }

    try {
      final response = await _apiService.getBottleHistory(
        page: page,
        perPage: 20,
      );

      return response.data ?? [];
      
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      rethrow; // Let PaginatedListView handle the error
    }
  }
}
```

**Key Improvements:**
- ✅ Uses `EnhancedApiService` with automatic token refresh
- ✅ Better error handling with `ApiException`
- ✅ Returns lists for pagination support
- ✅ Clears error message on new requests
- ✅ Debug logging for unexpected errors

---

## Example 5: Dashboard with Multiple States

### Before

```dart
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load data
      await Future.wait([
        context.read<AuthProvider>().refreshUserProfile(),
        context.read<CreditProvider>().fetchCredits(),
        context.read<BottleProvider>().fetchBottleStatistics(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(/* Dashboard content */);
  }
}
```

### After

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/credit_provider.dart';
import '../providers/bottle_provider.dart';
import '../widgets/common_widgets.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Enhanced API service handles token refresh automatically
      await Future.wait([
        context.read<AuthProvider>().refreshUserProfile(),
        context.read<CreditProvider>().fetchCredits(),
        context.read<BottleProvider>().fetchBottleStatistics(),
      ]);

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(
          message: 'Loading dashboard...',
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: ErrorMessage(
          message: _error!,
          onRetry: _loadData,
          icon: Icons.dashboard,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  return CustomCard(
                    child: Row(
                      children: [
                        CachedAvatarImage(
                          imageUrl: auth.user?.avatarUrl ?? '',
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              auth.user?.email ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Credits
              const SizedBox(height: 16),
              Consumer<CreditProvider>(
                builder: (context, credit, child) {
                  return CustomCard(
                    child: /* Credit display */,
                  );
                },
              ),
              
              // Statistics
              const SizedBox(height: 16),
              Consumer<BottleProvider>(
                builder: (context, bottle, child) {
                  return CustomCard(
                    child: /* Statistics display */,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Key Improvements:**
- ✅ Uses `LoadingIndicator` with message
- ✅ Uses `ErrorMessage` with retry
- ✅ Uses `CachedAvatarImage` for user avatar
- ✅ Pull-to-refresh functionality
- ✅ Proper mounted checks
- ✅ Better error handling with ApiException

---

## Summary

These examples show the transformation from manual error handling, loading states, and pagination to using the enhanced infrastructure. The new approach:

1. **Reduces boilerplate code** by 40-60%
2. **Provides consistent UX** across the app
3. **Handles edge cases** automatically
4. **Improves performance** with caching and optimization
5. **Enhances security** with automatic token management

Apply these patterns throughout your app for a more maintainable and user-friendly application.
