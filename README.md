# 🍾 Bottle WiFi Vendo - Laravel Backend

![Laravel](https://img.shields.io/badge/Laravel-12.x-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-8.2+-777BB4?style=for-the-badge&logo=php&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-21%20Passed-success?style=for-the-badge)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-blue?style=for-the-badge)

**Production-ready Laravel backend API for a Bottle WiFi Vendo System** that rewards users with internet access credits for recycling bottles.

## 📖 Overview

This is a **Laravel 12 backend API** that powers a bottle recycling incentive system. Users insert bottles into ESP32-powered machines and earn internet access credits (10 minutes per bottle). The system manages:

- 🔐 User authentication with API tokens
- 🍾 Bottle insertion logging and credit awarding
- 📶 WiFi session management
- 🤖 ESP32 machine monitoring and heartbeat
- 📊 Usage statistics and history tracking

## ✨ Features

### Core Functionality
- **User Management** - Registration, login, API token authentication
- **Bottle Processing** - ESP32 reports bottle insertions, system awards credits
- **Credit System** - 10 minutes per bottle, 30-day expiration, automatic tracking
- **Session Management** - Request internet access, manage active sessions
- **Machine Monitoring** - Heartbeat system, status tracking, statistics

### Technical Highlights
- ✅ Clean Architecture (Controllers → Services → Models)
- ✅ SOLID Principles
- ✅ RESTful API Design
- ✅ Comprehensive Testing (21 tests, 100% pass rate)
- ✅ Eloquent ORM with proper relationships
- ✅ Transaction handling for data integrity
- ✅ Input validation on all endpoints
- ✅ Secure API token authentication

## 🚀 Quick Start

### Prerequisites
- PHP 8.2+
- MySQL 8.0+
- Composer

### Installation

```bash
# Clone repository
git clone https://github.com/pankayke/bottle-wifi-vendo.git
cd bottle-wifi-vendo

# Install dependencies
composer install

# Configure environment
cp .env.example .env
php artisan key:generate

# Configure database in .env
DB_CONNECTION=mysql
DB_DATABASE=bottle_wifi
DB_USERNAME=root
DB_PASSWORD=

# Run migrations & seed demo data
php artisan migrate --seed

# Start server
php artisan serve
```

API available at: `http://localhost:8000/api/v1`

### Demo Credentials
```
Email: test@example.com
Password: password123
```

## 📡 API Endpoints

### Public Endpoints
```http
POST   /api/v1/register              # User registration
POST   /api/v1/login                 # User login
POST   /api/v1/bottle-detected       # ESP32: Report bottle insertion
POST   /api/v1/machine/heartbeat     # ESP32: Machine heartbeat
GET    /api/v1/machine/status        # Get machine status
```

### Protected Endpoints (Requires Bearer Token)
```http
POST   /api/v1/logout                # Logout user
GET    /api/v1/user                  # Get user details
GET    /api/v1/bottle/history        # Get bottle insertion history
GET    /api/v1/bottle/statistics     # Get user statistics
POST   /api/v1/request-internet      # Request internet access
POST   /api/v1/internet/end-session  # End WiFi session
GET    /api/v1/internet/session-status # Check session status
GET    /api/v1/user-credits          # Get available credits
GET    /api/v1/machines              # List all machines
POST   /api/v1/machine               # Create machine
PUT    /api/v1/machine/status        # Update machine status
```

## 📚 Documentation

- **[API Documentation](API_DOCUMENTATION.md)** - Complete API reference with examples
- **[Quick Start Guide](QUICK_START.md)** - Detailed setup and testing guide

## 🧪 Testing

```bash
# Run all tests
php artisan test

# Run specific test suite
php artisan test --filter=AuthTest
php artisan test --filter=BottleTest
php artisan test --filter=InternetTest
php artisan test --filter=MachineTest
```

**Test Results:**
```
Tests:    21 passed (88 assertions)
Duration: 2.43s
```

## 🏗️ Architecture

### Clean Architecture Layers
```
app/
├── Http/
│   ├── Controllers/API/    # Thin HTTP controllers
│   │   ├── AuthController.php
│   │   ├── BottleController.php
│   │   ├── InternetController.php
│   │   └── MachineController.php
│   └── Middleware/
│       └── ApiTokenAuthentication.php
├── Services/               # Business logic layer
│   ├── AuthService.php
│   ├── BottleService.php
│   ├── InternetService.php
│   └── MachineService.php
└── Models/                 # Data models with relationships
    ├── User.php
    ├── Machine.php
    ├── BottleLog.php
    ├── InternetCredit.php
    └── WifiSession.php
```

### Database Schema
- **users** - User accounts with API tokens
- **machines** - ESP32 devices with status tracking
- **bottle_logs** - Bottle insertion history
- **internet_credits** - Credit balance and expiration
- **wifi_sessions** - Active and completed sessions

## 🔌 Integration

### ESP32 Integration
```cpp
// Send bottle detection
POST /api/v1/bottle-detected
{
  "user_id": 1,
  "machine_id": 1
}

// Send heartbeat every 1-2 minutes
POST /api/v1/machine/heartbeat
{
  "machine_id": 1
}
```

### Flutter/Mobile App Integration
All 16 endpoints are ready for consumption with:
- JSON responses
- Proper HTTP status codes
- Bearer token authentication
- Comprehensive error messages

## 🔒 Security

- ✅ API token authentication (Bearer tokens)
- ✅ Bcrypt password hashing
- ✅ Input validation on all endpoints
- ✅ SQL injection protection (Eloquent ORM)
- ✅ Mass assignment protection
- ✅ Token revocation on logout

## 💼 Business Logic

**Credit System:**
- 10 minutes per bottle
- 30-day credit expiration
- Automatic credit stacking and deduction

**Session Management:**
- One active session per user
- Duration tracking
- Machine-specific binding
- Automatic credit deduction on end

**Machine Monitoring:**
- 5-minute online threshold
- Status: active/inactive/maintenance
- Real-time statistics

## 📊 Project Stats

- **16 API Endpoints**
- **5 Database Tables**
- **4 Service Classes**
- **4 Controller Classes**
- **5 Eloquent Models**
- **21 Feature Tests**
- **88 Test Assertions**
- **100% Test Pass Rate**

## 🛠️ Built With

- [Laravel 12](https://laravel.com/) - PHP Framework
- [MySQL](https://www.mysql.com/) - Database
- [PHPUnit](https://phpunit.de/) - Testing Framework

## 📝 License

This project is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).

## 👨‍💻 Author

**pankayke**

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

---

**Built with ❤️ using Laravel | Production-Ready | Clean Architecture | Fully Tested**

