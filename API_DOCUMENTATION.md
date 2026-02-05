# Bottle WiFi Vendo System - Backend API

Production-ready Laravel backend for a Bottle WiFi Vendo System that rewards users with internet credits for recycling bottles.

## System Overview

The system allows users to:
- Insert bottles into ESP32-powered machines
- Earn internet access credits (10 minutes per bottle)
- Request and manage WiFi sessions
- Track bottle insertion history and statistics

## Architecture

### Clean Architecture Principles

```
app/
├── Http/
│   ├── Controllers/API/     # Thin controllers (HTTP layer)
│   └── Middleware/           # Authentication middleware
├── Services/                 # Business logic layer
│   ├── AuthService.php
│   ├── BottleService.php
│   ├── InternetService.php
│   └── MachineService.php
├── Models/                   # Data models with relationships
│   ├── User.php
│   ├── Machine.php
│   ├── BottleLog.php
│   ├── InternetCredit.php
│   └── WifiSession.php
```

## Database Schema

### Users
- `id`, `name`, `email`, `password`
- `api_token` - API authentication token
- `total_credits` - Lifetime credits earned
- `phone_number`

### Machines
- `id`, `name`, `location`
- `status` - active | inactive | maintenance
- `last_online` - Heartbeat timestamp

### BottleLogs
- `id`, `user_id`, `machine_id`
- `credits_earned` - Minutes awarded (default: 10)
- `created_at` - Insertion timestamp

### InternetCredits
- `id`, `user_id`, `minutes`, `minutes_used`
- `minutes_remaining` - Computed column
- `status` - active | used | expired
- `expires_at` - Optional expiration

### WifiSessions
- `id`, `user_id`, `machine_id`, `internet_credit_id`
- `start_time`, `end_time`, `duration_minutes`
- `ip_address`, `mac_address`
- `status` - active | completed | disconnected

## API Endpoints

### Base URL
```
http://localhost:8000/api/v1
```

### Authentication

#### Register User
```http
POST /register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "phone_number": "+1234567890"
}

Response: 201 Created
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "user": { ... },
    "token": "api_token_here"
  }
}
```

#### Login
```http
POST /login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}

Response: 200 OK
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": { ... },
    "token": "api_token_here"
  }
}
```

#### Logout (Protected)
```http
POST /logout
Authorization: Bearer {api_token}

Response: 200 OK
{
  "success": true,
  "message": "Logout successful"
}
```

### Bottle Operations

#### Report Bottle Insertion (ESP32)
```http
POST /bottle-detected
Content-Type: application/json

{
  "user_id": 1,
  "machine_id": 1
}

Response: 201 Created
{
  "success": true,
  "message": "Bottle processed successfully",
  "data": {
    "credits_earned": 10,
    "total_available_minutes": 40,
    "bottle_log": { ... }
  }
}
```

#### Get Bottle History (Protected)
```http
GET /bottle/history?limit=50
Authorization: Bearer {api_token}

Response: 200 OK
{
  "success": true,
  "data": {
    "history": [ ... ]
  }
}
```

#### Get Bottle Statistics (Protected)
```http
GET /bottle/statistics
Authorization: Bearer {api_token}

Response: 200 OK
{
  "success": true,
  "data": {
    "total_bottles": 25,
    "total_credits_earned": 250,
    "today_bottles": 5
  }
}
```

### Internet Access

#### Request Internet Access (Protected)
```http
POST /request-internet
Authorization: Bearer {api_token}
Content-Type: application/json

{
  "machine_id": 1,
  "requested_minutes": 30,
  "mac_address": "AA:BB:CC:DD:EE:FF",
  "ip_address": "192.168.1.100"
}

Response: 201 Created
{
  "success": true,
  "message": "Internet access granted",
  "data": {
    "session_id": 1,
    "allocated_minutes": 30,
    "start_time": "2026-02-05T10:30:00.000000Z",
    "machine": { ... }
  }
}
```

#### End WiFi Session (Protected)
```http
POST /internet/end-session
Authorization: Bearer {api_token}
Content-Type: application/json

{
  "session_id": 1
}

Response: 200 OK
{
  "success": true,
  "message": "Session ended successfully",
  "data": {
    "session_id": 1,
    "duration_minutes": 28,
    "end_time": "2026-02-05T10:58:00.000000Z"
  }
}
```

#### Get User Credits (Protected)
```http
GET /user-credits
Authorization: Bearer {api_token}

Response: 200 OK
{
  "success": true,
  "data": {
    "total_available_minutes": 120,
    "credits": [ ... ],
    "total_credits_awarded": 250
  }
}
```

#### Get Session Status (Protected)
```http
GET /internet/session-status
Authorization: Bearer {api_token}

Response: 200 OK
{
  "success": true,
  "data": {
    "active_session": true,
    "session": { ... },
    "elapsed_minutes": 15,
    "machine": { ... }
  }
}
```

### Machine Management

#### Get Machine Status
```http
GET /machine/status?machine_id=1

Response: 200 OK
{
  "success": true,
  "data": {
    "machine": { ... },
    "is_online": true,
    "active_sessions": 2,
    "total_bottles_collected": 150,
    "today_bottles_collected": 12
  }
}
```

#### Machine Heartbeat (ESP32)
```http
POST /machine/heartbeat
Content-Type: application/json

{
  "machine_id": 1
}

Response: 200 OK
{
  "success": true,
  "message": "Heartbeat updated",
  "data": {
    "machine": { ... },
    "is_online": true
  }
}
```

#### Get All Machines (Protected)
```http
GET /machines
Authorization: Bearer {api_token}

Response: 200 OK
{
  "success": true,
  "data": {
    "machines": [ ... ]
  }
}
```

#### Create Machine (Protected)
```http
POST /machine
Authorization: Bearer {api_token}
Content-Type: application/json

{
  "name": "Machine Delta",
  "location": "Building D - Floor 1",
  "status": "active"
}

Response: 201 Created
{
  "success": true,
  "message": "Machine created successfully",
  "data": {
    "machine": { ... }
  }
}
```

## Installation & Setup

### Prerequisites
- PHP 8.2+
- MySQL 8.0+
- Composer

### Installation Steps

1. **Clone repository**
```bash
git clone <repository-url>
cd bottle_wifi
```

2. **Install dependencies**
```bash
composer install
```

3. **Configure environment**
```bash
cp .env.example .env
php artisan key:generate
```

4. **Configure database in `.env`**
```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=bottle_wifi
DB_USERNAME=root
DB_PASSWORD=
```

5. **Run migrations**
```bash
php artisan migrate
```

6. **Seed database (optional)**
```bash
php artisan db:seed
```

This creates:
- Test user: `test@example.com` / `password123`
- 3 demo machines
- API token (shown in console output)

7. **Start server**
```bash
php artisan serve
```

API available at: `http://localhost:8000/api/v1`

## Testing

### Run all tests
```bash
php artisan test
```

### Run specific test suite
```bash
php artisan test --filter=AuthTest
php artisan test --filter=BottleTest
php artisan test --filter=InternetTest
php artisan test --filter=MachineTest
```

### Test Coverage
- Authentication (register, login, logout)
- Bottle insertion and credit awarding
- Internet access request and session management
- Machine status and heartbeat
- Error scenarios and validation

## Security Features

### API Token Authentication
- Bearer token authentication
- Tokens stored securely in database
- Token regeneration on login
- Token revocation on logout

### Input Validation
- All inputs validated using Laravel validators
- SQL injection protection via Eloquent ORM
- XSS protection built-in
- CSRF protection for web routes

### Password Security
- Bcrypt hashing
- Minimum 8 characters
- Confirmation required on registration

## Business Logic

### Credit System
- **Per Bottle**: 10 minutes internet access
- **Credit Expiration**: 30 days (configurable)
- **Credit Status**: active, used, expired
- **Auto-deduction**: Minutes deducted when session ends

### Session Management
- **One Active Session**: User can only have one active session
- **Session Tracking**: Monitors start time, end time, duration
- **Machine Binding**: Session tied to specific machine
- **Credit Deduction**: Automatic when session completes

### Machine Monitoring
- **Heartbeat System**: ESP32 sends periodic heartbeat
- **Online Status**: Machine considered online if heartbeat within 5 minutes
- **Status Types**: active, inactive, maintenance
- **Statistics Tracking**: Bottles collected, active sessions

## ESP32 Integration

### Required Endpoints for ESP32
1. **Heartbeat**: POST `/machine/heartbeat`
2. **Bottle Detection**: POST `/bottle-detected`

### ESP32 Sample Code (Arduino)
```cpp
#include <WiFi.h>
#include <HTTPClient.h>

const char* ssid = "your_wifi";
const char* password = "your_password";
const String apiUrl = "http://your-server.com/api/v1";
const int machineId = 1;

void sendBottleDetected(int userId) {
  HTTPClient http;
  http.begin(apiUrl + "/bottle-detected");
  http.addHeader("Content-Type", "application/json");
  
  String payload = "{\"user_id\":" + String(userId) + 
                   ",\"machine_id\":" + String(machineId) + "}";
  
  int httpCode = http.POST(payload);
  String response = http.getString();
  http.end();
}

void sendHeartbeat() {
  HTTPClient http;
  http.begin(apiUrl + "/machine/heartbeat");
  http.addHeader("Content-Type", "application/json");
  
  String payload = "{\"machine_id\":" + String(machineId) + "}";
  http.POST(payload);
  http.end();
}
```

## Flutter Mobile App Integration

The API is designed for consumption by a Flutter mobile app:
- JSON responses for all endpoints
- RESTful design
- Token-based authentication
- Comprehensive error messages
- Proper HTTP status codes

## Production Deployment

### Checklist
- [ ] Set `APP_DEBUG=false` in `.env`
- [ ] Set strong `APP_KEY`
- [ ] Configure production database
- [ ] Set up HTTPS/SSL
- [ ] Configure CORS for mobile app
- [ ] Set up logging and monitoring
- [ ] Configure queue workers for background jobs
- [ ] Set up automated backups
- [ ] Enable rate limiting
- [ ] Configure caching (Redis recommended)

### Performance Optimization
- Use database indexing (already implemented)
- Enable query caching
- Use Laravel Octane for high performance
- Implement Redis for session storage
- Use CDN for static assets

## Monitoring & Maintenance

### Key Metrics to Monitor
- Machine online/offline status
- Session durations
- Credit balance trends
- Bottle insertion rates
- API response times
- Error rates

### Scheduled Tasks (Add to cron)
```php
// Mark expired credits
Schedule::command('credits:expire')->daily();

// Clean old sessions
Schedule::command('sessions:cleanup')->daily();

// Machine health check
Schedule::command('machines:check')->everyFiveMinutes();
```

## Troubleshooting

### Common Issues

**MySQL Connection Error**
- Verify MySQL is running
- Check DB credentials in `.env`
- Ensure database exists

**API Token Not Working**
- Verify token in Authorization header
- Format: `Bearer {token}`
- Check token hasn't been revoked

**Insufficient Credits Error**
- User needs to insert bottles
- Check credit expiration
- Verify active credit status

## License

MIT License

## Support

For issues and questions:
- Create an issue on GitHub
- Contact: support@example.com

---

**Built with Laravel 12 | Production-Ready | Clean Architecture**
