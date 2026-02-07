# Laravel Backend Setup Guide

This Flutter app requires a Laravel backend with specific API endpoints. Follow these steps to set up the backend.

## Quick Setup

### 1. Create Laravel Project

```bash
composer create-project laravel/laravel bottle-wifi-backend
cd bottle-wifi-backend
```

### 2. Install Required Packages

```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

### 3. Configure CORS

Edit `bootstrap/app.php` (Laravel 11+) or create `config/cors.php` (Laravel 10):

**For Laravel 11+:**
```php
<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->api(prepend: [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
        ]);

        $middleware->alias([
            'verified' => \App\Http\Middleware\EnsureEmailIsVerified::class,
        ]);

        // Enable CORS
        $middleware->append(\Illuminate\Http\Middleware\HandleCors::class);
    })
    ->withExceptions(function (Exceptions $exceptions) {
        //
    })->create();
```

**For Laravel 10:**
```bash
composer require fruitcake/laravel-cors
```

Then update `app/Http/Kernel.php`:
```php
protected $middleware = [
    // ...
    \Fruitcake\Cors\HandleCors::class,
];
```

### 4. Create Database Tables

Create migration files:

```bash
php artisan make:migration create_bottle_logs_table
php artisan make:migration create_internet_credits_table
php artisan make:migration create_machines_table
php artisan make:migration create_wifi_sessions_table
```

**Migration: bottle_logs**
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bottle_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('machine_id')->constrained()->onDelete('cascade');
            $table->enum('status', ['pending', 'verified', 'rejected'])->default('pending');
            $table->integer('credits_awarded')->default(0);
            $table->string('image_path')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bottle_logs');
    }
};
```

**Migration: internet_credits**
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('internet_credits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->integer('total_minutes')->default(0);
            $table->integer('used_minutes')->default(0);
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('internet_credits');
    }
};
```

**Migration: machines**
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('machines', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('mac_address')->unique();
            $table->string('ip_address')->nullable();
            $table->enum('status', ['online', 'offline', 'maintenance'])->default('offline');
            $table->boolean('is_active')->default(true);
            $table->integer('bottles_processed')->default(0);
            $table->timestamp('last_online_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('machines');
    }
};
```

**Migration: wifi_sessions**
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('wifi_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('machine_id')->constrained()->onDelete('cascade');
            $table->integer('duration_minutes');
            $table->enum('status', ['active', 'completed', 'expired'])->default('active');
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wifi_sessions');
    }
};
```

**Update users table migration** to add credits field:
```php
$table->integer('credits')->default(0);
$table->string('phone_number')->nullable();
```

Run migrations:
```bash
php artisan migrate
```

### 5. Create API Routes

Edit `routes/api.php`:

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BottleController;
use App\Http\Controllers\CreditController;
use App\Http\Controllers\MachineController;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    // Auth endpoints
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user/profile', [AuthController::class, 'profile']);

    // Bottle endpoints
    Route::post('/bottle/report', [BottleController::class, 'report']);
    Route::get('/bottle/history', [BottleController::class, 'history']);
    Route::get('/bottle/statistics', [BottleController::class, 'statistics']);

    // Internet/Credit endpoints
    Route::post('/internet/request', [CreditController::class, 'requestInternet']);
    Route::get('/internet/credits', [CreditController::class, 'viewCredits']);
    Route::get('/internet/active-session', [CreditController::class, 'activeSession']);

    // Machine endpoints
    Route::get('/machines/status', [MachineController::class, 'status']);
    Route::post('/machines/heartbeat', [MachineController::class, 'heartbeat']);
});
```

### 6. Create Controllers

**AuthController:**
```bash
php artisan make:controller AuthController
```

```php
<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'credits' => 0,
            'phone_number' => $request->phone_number,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully',
            'data' => [
                'user' => $user,
                'token' => $token,
            ]
        ], 201);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => $user,
                'token' => $token,
            ]
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    public function profile(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $request->user(),
        ]);
    }
}
```

**BottleController:**
```bash
php artisan make:controller BottleController
```

```php
<?php

namespace App\Http\Controllers;

use App\Models\BottleLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BottleController extends Controller
{
    public function report(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'machine_id' => 'required|exists:machines,id',
            'image' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $bottleLog = BottleLog::create([
            'user_id' => $request->user()->id,
            'machine_id' => $request->machine_id,
            'status' => 'verified', // Auto-verify for demo
            'credits_awarded' => 5, // Award 5 credits
            'image_path' => $request->image,
            'verified_at' => now(),
        ]);

        // Award credits to user
        $request->user()->increment('credits', 5);

        return response()->json([
            'success' => true,
            'message' => 'Bottle reported successfully',
            'data' => $bottleLog,
        ], 201);
    }

    public function history(Request $request)
    {
        $logs = BottleLog::where('user_id', $request->user()->id)
            ->with('machine')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $logs,
        ]);
    }

    public function statistics(Request $request)
    {
        $stats = [
            'total_bottles' => BottleLog::where('user_id', $request->user()->id)->count(),
            'verified_bottles' => BottleLog::where('user_id', $request->user()->id)
                ->where('status', 'verified')->count(),
            'pending_bottles' => BottleLog::where('user_id', $request->user()->id)
                ->where('status', 'pending')->count(),
            'total_credits_earned' => BottleLog::where('user_id', $request->user()->id)
                ->where('status', 'verified')->sum('credits_awarded'),
            'this_week' => BottleLog::where('user_id', $request->user()->id)
                ->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])
                ->count(),
            'this_month' => BottleLog::where('user_id', $request->user()->id)
                ->whereMonth('created_at', now()->month)
                ->count(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }
}
```

**CreditController:**
```bash
php artisan make:controller CreditController
```

```php
<?php

namespace App\Http\Controllers;

use App\Models\InternetCredit;
use App\Models\WifiSession;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CreditController extends Controller
{
    public function requestInternet(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'machine_id' => 'required|exists:machines,id',
            'duration' => 'required|integer|min:15',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();
        
        // Check if user has enough credits
        if ($user->credits < $request->duration) {
            return response()->json([
                'success' => false,
                'message' => 'Insufficient credits',
            ], 400);
        }

        // Deduct credits
        $user->decrement('credits', $request->duration);

        // Create session
        $session = WifiSession::create([
            'user_id' => $user->id,
            'machine_id' => $request->machine_id,
            'duration_minutes' => $request->duration,
            'status' => 'active',
            'started_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Internet session started',
            'data' => $session,
        ], 201);
    }

    public function viewCredits(Request $request)
    {
        $user = $request->user();
        
        $credit = InternetCredit::firstOrCreate(
            ['user_id' => $user->id],
            [
                'total_minutes' => $user->credits,
                'used_minutes' => 0,
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $credit,
        ]);
    }

    public function activeSession(Request $request)
    {
        $session = WifiSession::where('user_id', $request->user()->id)
            ->where('status', 'active')
            ->with('machine')
            ->first();

        if (!$session) {
            return response()->json([
                'success' => false,
                'message' => 'No active session',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $session,
        ]);
    }
}
```

**MachineController:**
```bash
php artisan make:controller MachineController
```

```php
<?php

namespace App\Http\Controllers;

use App\Models\Machine;
use Illuminate\Http\Request;

class MachineController extends Controller
{
    public function status(Request $request)
    {
        $machines = Machine::all();

        return response()->json([
            'success' => true,
            'data' => $machines,
        ]);
    }

    public function heartbeat(Request $request)
    {
        $validator = \Validator::make($request->all(), [
            'machine_id' => 'required|exists:machines,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors()
            ], 422);
        }

        $machine = Machine::find($request->machine_id);
        $machine->update([
            'status' => 'online',
            'last_online_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Heartbeat received',
            'data' => $machine,
        ]);
    }
}
```

### 7. Create Models

**BottleLog Model:**
```bash
php artisan make:model BottleLog
```

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BottleLog extends Model
{
    protected $fillable = [
        'user_id',
        'machine_id',
        'status',
        'credits_awarded',
        'image_path',
        'rejection_reason',
        'verified_at',
    ];

    protected $casts = [
        'verified_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function machine(): BelongsTo
    {
        return $this->belongsTo(Machine::class);
    }
}
```

**InternetCredit Model:**
```bash
php artisan make:model InternetCredit
```

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class InternetCredit extends Model
{
    protected $fillable = [
        'user_id',
        'total_minutes',
        'used_minutes',
        'expires_at',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

**Machine Model:**
```bash
php artisan make:model Machine
```

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Machine extends Model
{
    protected $fillable = [
        'name',
        'mac_address',
        'ip_address',
        'status',
        'is_active',
        'bottles_processed',
        'last_online_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'last_online_at' => 'datetime',
    ];
}
```

**WifiSession Model:**
```bash
php artisan make:model WifiSession
```

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class WifiSession extends Model
{
    protected $fillable = [
        'user_id',
        'machine_id',
        'duration_minutes',
        'status',
        'started_at',
        'ended_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function machine(): BelongsTo
    {
        return $this->belongsTo(Machine::class);
    }
}
```

**Update User Model:**

Add to `app/Models/User.php`:
```php
protected $fillable = [
    'name',
    'email',
    'password',
    'credits',
    'phone_number',
];
```

### 8. Seed Demo Data

Create seeder:
```bash
php artisan make:seeder MachineSeeder
```

```php
<?php

namespace Database\Seeders;

use App\Models\Machine;
use Illuminate\Database\Seeder;

class MachineSeeder extends Seeder
{
    public function run(): void
    {
        Machine::create([
            'name' => 'Machine 1',
            'mac_address' => '00:11:22:33:44:55',
            'ip_address' => '192.168.1.100',
            'status' => 'online',
            'is_active' => true,
        ]);

        Machine::create([
            'name' => 'Machine 2',
            'mac_address' => '00:11:22:33:44:66',
            'ip_address' => '192.168.1.101',
            'status' => 'online',
            'is_active' => true,
        ]);
    }
}
```

Run seeder:
```bash
php artisan db:seed --class=MachineSeeder
```

### 9. Start Laravel Server

```bash
php artisan serve
```

The API will be available at `http://localhost:8000`

## Testing the API

You can test the API using curl or Postman:

### Register
```bash
curl -X POST http://localhost:8000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## Flutter App Configuration

Once your Laravel backend is running, update the Flutter app's API URL in `lib/utils/constants.dart`:

```dart
static const String baseUrl = 'http://localhost:8000/api';
```

For mobile devices testing on same network:
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000/api';
```

## Troubleshooting

### CORS Issues
Make sure CORS is properly configured in Laravel. For development, you can add this to `.env`:
```
SESSION_DRIVER=cookie
SANCTUM_STATEFUL_DOMAINS=localhost:8000,127.0.0.1:8000
```

### Route Not Found
Make sure your routes are in `routes/api.php` and not `routes/web.php`.

### 401 Unauthorized
Check that the Bearer token is being sent correctly in the Authorization header.

## Production Deployment

When deploying to production:
1. Update `.env` with production database credentials
2. Set `APP_ENV=production`
3. Run `php artisan config:cache`
4. Run `php artisan route:cache`
5. Configure proper CORS origins
6. Use HTTPS for API endpoints
7. Update Flutter app's baseUrl to production URL
