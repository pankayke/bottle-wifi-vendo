# Development Guide - Bottle WiFi Vendo

## 🏗️ Project Structure

This is a monorepo containing:
- **Flutter Mobile App** (root directory)
- **Laravel Backend API** (`bottle-wifi-backend/` subdirectory)

## 🚀 Quick Start

### Prerequisites

- PHP 8.2+ with extensions: `pdo_mysql`, `mbstring`, `xml`, `bcmath`
- Composer 2.x
- MySQL 8.0+
- Flutter SDK 3.x
- Chrome browser (for Flutter web)

### Initial Setup

**1. Configure Laravel Backend:**

```powershell
cd bottle-wifi-backend

# Copy environment file
Copy-Item .env.example .env

# Install dependencies
composer install

# Generate application key
php artisan key:generate

# Create database
# In MySQL: CREATE DATABASE bottle_wifi_vendo;

# Run migrations and seeders
php artisan migrate
php artisan db:seed
```

**⚠️ Important:** Save the credentials output by `php artisan db:seed` - you'll need the API tokens and machine keys!

**2. Configure Flutter App:**

```powershell
cd ..  # Back to root

# Install dependencies
flutter pub get

# Update API base URL in lib/services/api_service.dart if needed
# Default is http://localhost:8000/api/v1
```

### Running Development Servers

#### Option A: Automated Script (Easiest)

```powershell
# From project root
.\start-dev.ps1
```

This opens two PowerShell windows:
- Window 1: Laravel backend (`http://localhost:8000`)
- Window 2: Flutter app (Chrome)

#### Option B: Manual (Two Terminals)

**Terminal 1 - Laravel Backend:**
```powershell
cd bottle-wifi-backend
php artisan serve
```

**Terminal 2 - Flutter App:**
```powershell
# From project root
flutter run -d chrome
```

#### Option C: VS Code Task

Press `F1` → Type `Tasks: Run Task` → Select `Run Flutter App`

Then manually start Laravel in a terminal:
```powershell
cd bottle-wifi-backend
php artisan serve
```

## 🧪 Testing

### Laravel Backend Tests

```powershell
cd bottle-wifi-backend

# Run all tests
php artisan test

# Run specific test suite
php artisan test tests/Feature/AuthControllerTest.php

# Run with coverage (requires Xdebug)
php artisan test --coverage
```

### Flutter Tests

```powershell
# From project root
flutter test
```

## 📡 API Testing

### Using cURL

**Register a user:**
```powershell
curl -X POST http://localhost:8000/api/v1/register `
  -H "Content-Type: application/json" `
  -d '{\"name\":\"John Doe\",\"email\":\"john@example.com\",\"password\":\"password123\",\"password_confirmation\":\"password123\"}'
```

**Login:**
```powershell
curl -X POST http://localhost:8000/api/v1/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"test@example.com\",\"password\":\"password123\"}'
```

**Test authenticated endpoint:**
```powershell
$token = "your_api_token_here"
curl http://localhost:8000/api/v1/credits `
  -H "Authorization: Bearer $token"
```

### Using Postman

1. Import collection from `bottle-wifi-backend/QUICKSTART.md`
2. Set base URL: `http://localhost:8000/api/v1`
3. For authenticated requests, add header: `Authorization: Bearer {token}`

## 🔧 Common Tasks

### Reset Database

```powershell
cd bottle-wifi-backend
php artisan migrate:fresh --seed
```

### Clear Laravel Cache

```powershell
php artisan cache:clear
php artisan config:clear
php artisan route:clear
```

### Hot Reload Flutter

Press `r` in the Flutter terminal to hot reload
Press `R` to hot restart
Press `q` to quit

### View Laravel Logs

```powershell
cd bottle-wifi-backend
Get-Content storage/logs/laravel.log -Tail 50 -Wait
```

## 📱 Testing on Physical Devices

### Android/iOS

1. Start Laravel backend on your local network
2. Find your IP address: `ipconfig` (Windows) / `ifconfig` (Mac/Linux)
3. Update Flutter `api_service.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.x.x:8000/api/v1';
   ```
4. Run Flutter app:
   ```powershell
   flutter run -d <device-id>
   ```

### Allow Network Access (Windows)

If you encounter firewall issues:
```powershell
php artisan serve --host=0.0.0.0 --port=8000
```

Then allow PHP in Windows Firewall when prompted.

## 🐛 Troubleshooting

### Laravel won't start

**Issue:** "Address already in use"
```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process
taskkill /F /PID <process_id>
```

**Issue:** Database connection failed
- Verify MySQL is running
- Check `.env` database credentials
- Ensure database exists: `CREATE DATABASE bottle_wifi_vendo;`

### Flutter issues

**Issue:** "No devices found"
```powershell
flutter doctor
flutter devices
```

**Issue:** Dependencies out of sync
```powershell
flutter clean
flutter pub get
```

### API returns 500 errors

```powershell
cd bottle-wifi-backend

# Check logs
Get-Content storage/logs/laravel.log -Tail 20

# Ensure database is migrated
php artisan migrate:status
```

## 🔐 Security Notes

- `.env` file contains sensitive credentials - **never commit to Git**
- API tokens from seeder are for **development only**
- Change `APP_KEY` for production
- Use HTTPS in production
- Rotate machine API keys regularly

## 📦 Building for Production

### Laravel Backend

See `PRODUCTION_DEPLOYMENT_GUIDE.md` for complete instructions.

### Flutter App

**Web:**
```powershell
flutter build web --release
```

**Android:**
```powershell
flutter build apk --release
# or for app bundle:
flutter build appbundle --release
```

**iOS:**
```powershell
flutter build ios --release
```

## 📚 Additional Documentation

- [API Documentation](bottle-wifi-backend/API_DOCUMENTATION.md)
- [Quick Start Guide](bottle-wifi-backend/QUICKSTART.md)
- [Production Deployment](PRODUCTION_DEPLOYMENT_GUIDE.md)
- [Security Audit](SECURITY_AUDIT_CHECKLIST.md)

## 🆘 Getting Help

1. Check existing documentation in project root
2. Review Laravel logs: `storage/logs/laravel.log`
3. Run tests to verify system state
4. Check GitHub issues for similar problems

## 🔄 Development Workflow

1. Pull latest changes: `git pull`
2. Update dependencies:
   - Laravel: `composer update` (in bottle-wifi-backend/)
   - Flutter: `flutter pub get` (in root)
3. Run migrations: `php artisan migrate`
4. Run tests before committing
5. Commit with clear messages
6. Push to feature branch, create PR

---

**Happy Coding! 🚀**
