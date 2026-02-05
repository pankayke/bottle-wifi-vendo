# SETUP GUIDE - Bottle WiFi Vendo Flutter App

## Quick Start

Follow these steps to get the app running:

### Step 1: Install Flutter Dependencies

Open a terminal in the project directory and run:

```bash
flutter pub get
```

This will download all required packages specified in pubspec.yaml.

### Step 2: Configure Your Laravel API URL

Open the file: `lib/utils/constants.dart`

Find this line:
```dart
static const String baseUrl = 'https://your-laravel-api.com/api';
```

Replace `https://your-laravel-api.com/api` with your actual Laravel backend URL.

Example:
```dart
static const String baseUrl = 'https://api.bottlewifi.com/api';
```

### Step 3: Run the App

Choose your target device:

#### For Android Emulator:
```bash
flutter run
```

#### For iOS Simulator (Mac only):
```bash
flutter run -d ios
```

#### For Chrome (Web testing):
```bash
flutter run -d chrome
```

### Step 4: Login

Use your Laravel backend credentials to login, or register a new account.

Demo credentials (if configured in your backend):
- Email: `demo@bottlewifi.com`
- Password: `password123`

---

## Project File Structure

```
bottle_wifi/
│
├── lib/
│   ├── models/                      # Data Models
│   │   ├── api_response.dart        # Generic API response wrapper
│   │   ├── bottle_log.dart          # Bottle detection log model
│   │   ├── internet_credit.dart     # User credits model
│   │   ├── machine.dart             # Vendo machine model
│   │   ├── user.dart                # User model
│   │   └── wifi_session.dart        # WiFi session model
│   │
│   ├── services/                    # Business Logic Services
│   │   ├── api_service.dart         # HTTP API client (all endpoints)
│   │   └── storage_service.dart     # Secure token/data storage
│   │
│   ├── providers/                   # State Management
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── bottle_provider.dart     # Bottle management state
│   │   ├── credit_provider.dart     # Credits/session state
│   │   └── machine_provider.dart    # Machine monitoring state
│   │
│   ├── screens/                     # UI Screens
│   │   ├── login_screen.dart        # Login UI
│   │   ├── register_screen.dart     # Registration UI
│   │   ├── dashboard_screen.dart    # Main dashboard
│   │   ├── bottle_history_screen.dart  # Bottle logs
│   │   └── machine_status_screen.dart  # Machine monitoring
│   │
│   ├── widgets/                     # Reusable UI Components
│   │   ├── bottle_log_card.dart     # Bottle log item
│   │   ├── credit_card_widget.dart  # Credits display
│   │   ├── internet_request_button.dart  # Request WiFi button
│   │   ├── machine_card.dart        # Machine status item
│   │   ├── quick_stats_widget.dart  # Statistics display
│   │   └── session_status_widget.dart   # Active session display
│   │
│   ├── utils/                       # Utilities
│   │   ├── api_exception.dart       # Custom exception handling
│   │   ├── constants.dart           # App constants & API URLs
│   │   ├── helpers.dart             # Helper functions
│   │   └── validators.dart          # Form validators
│   │
│   └── main.dart                    # App entry point
│
├── android/                         # Android native code
├── ios/                             # iOS native code
├── web/                             # Web support
├── test/                            # Unit tests
├── pubspec.yaml                     # Dependencies
└── README.md                        # Documentation
```

---

## API Endpoints Required

Your Laravel backend must implement these endpoints:

### Authentication
- `POST /api/login` - User login
- `POST /api/register` - User registration
- `POST /api/logout` - User logout

### Bottle
- `POST /api/bottle/report` - Report a bottle
- `GET /api/bottle/history?page={page}&per_page={per_page}` - Get history
- `GET /api/bottle/statistics` - Get statistics

### Internet
- `POST /api/internet/request` - Request internet access
- `GET /api/internet/credits` - View user credits
- `GET /api/internet/session` - Get active session

### Machines
- `GET /api/machines/status` - Get all machines
- `POST /api/machines/heartbeat` - Send heartbeat

### User
- `GET /api/user/profile` - Get user profile

---

## Expected API Response Formats

### Login Response
```json
{
  "success": true,
  "message": "Login successful",
  "token": "bearer_token_here",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "credits": 120,
    "created_at": "2024-01-01T00:00:00.000000Z",
    "updated_at": "2024-01-01T00:00:00.000000Z"
  }
}
```

### Bottle History Response
```json
{
  "success": true,
  "bottles": [
    {
      "id": 1,
      "user_id": 1,
      "machine_id": 1,
      "machine_name": "Machine A",
      "credits_awarded": 10,
      "status": "verified",
      "timestamp": "2024-01-01T10:00:00.000000Z",
      "created_at": "2024-01-01T10:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 100
  }
}
```

### Internet Credits Response
```json
{
  "success": true,
  "credits": {
    "total_minutes": 120,
    "used_minutes": 30,
    "remaining_minutes": 90,
    "is_active": true
  }
}
```

### Machine Status Response
```json
{
  "success": true,
  "machines": [
    {
      "id": 1,
      "name": "Machine A",
      "mac_address": "00:11:22:33:44:55",
      "ip_address": "192.168.1.100",
      "status": "active",
      "is_online": true,
      "location": "Building A",
      "total_bottles_processed": 150,
      "last_online": "2024-01-01T10:00:00.000000Z",
      "created_at": "2024-01-01T00:00:00.000000Z",
      "updated_at": "2024-01-01T10:00:00.000000Z"
    }
  ]
}
```

---

## Troubleshooting

### Issue: "Cannot connect to API"
- Check that the API URL in `constants.dart` is correct
- Ensure your Laravel backend is running
- Check network connectivity
- Verify CORS is enabled on your Laravel backend

### Issue: "401 Unauthorized"
- Token may have expired, try logging out and logging back in
- Check Laravel Sanctum configuration

### Issue: "Packages not found"
- Run `flutter pub get` again
- Try `flutter clean` then `flutter pub get`

### Issue: "Build failed"
- Check Flutter version: `flutter --version`
- Ensure Flutter SDK ^3.10.7 is installed
- Run `flutter doctor` to check for issues

---

## Development Tips

1. **Hot Reload**: Press `r` in the terminal while app is running
2. **Hot Restart**: Press `R` in the terminal
3. **Debugging**: Use VS Code or Android Studio debugger
4. **Logs**: Check console output for API errors
5. **State**: Use Provider DevTools to debug state changes

---

## Next Steps

1. Configure your backend API URL
2. Run `flutter pub get`
3. Test the app with `flutter run`
4. Customize UI colors in `lib/utils/constants.dart`
5. Add additional features as needed

---

## Support

For issues, check:
- Flutter documentation: https://flutter.dev
- Provider documentation: https://pub.dev/packages/provider
- Project README.md

**Happy Coding!**
