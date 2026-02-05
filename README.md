# Bottle WiFi Vendo - Flutter Mobile App

Professional Flutter mobile application for the Bottle WiFi Vendo system integrating with Laravel backend API.

## Features

- **Authentication System**: Complete login/register with Bearer token authentication
- **Dashboard**: User credits, active sessions, bottle history, and statistics
- **Bottle Management**: Report bottles, view history, and track statistics
- **Internet Access**: Request WiFi access, manage sessions, and view credits
- **Machine Monitoring**: Real-time machine status and heartbeat monitoring
- **Clean Architecture**: SOLID principles, separation of concerns, and modular structure

## Project Structure

```
lib/
├── models/              # Data models (User, BottleLog, Credit, Machine, WifiSession)
├── services/            # API and storage services
├── providers/           # State management (Provider pattern)
├── screens/             # UI screens
├── widgets/             # Reusable widgets
├── utils/               # Helpers, constants, validators
└── main.dart           # App entry point
```

## Setup Instructions

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure API URL

Update the base URL in `lib/utils/constants.dart`:

```dart
static const String baseUrl = 'https://your-laravel-api.com/api';
```

Replace with your actual Laravel API URL.

### 3. Run the App

```bash
flutter run
```

## API Integration

The app integrates with 16 Laravel API endpoints:

### Authentication
- `POST /login` - User login
- `POST /register` - User registration
- `POST /logout` - User logout

### Bottle Management
- `POST /bottle/report` - Report a bottle
- `GET /bottle/history` - Get bottle history (paginated)
- `GET /bottle/statistics` - Get bottle statistics

### Internet Access
- `POST /internet/request` - Request internet access
- `GET /internet/credits` - View user credits
- `GET /internet/session` - Get active session

### Machine Management
- `GET /machines/status` - Get machine status
- `POST /machines/heartbeat` - Send machine heartbeat

### User
- `GET /user/profile` - Get user profile

## Key Technologies

- **Flutter SDK**: ^3.10.7
- **State Management**: Provider ^6.1.2
- **HTTP Client**: http ^1.2.1
- **Secure Storage**: flutter_secure_storage ^9.2.2
- **Date Formatting**: intl ^0.19.0

## Demo Credentials

For testing purposes, you can use:

```
Email: demo@bottlewifi.com
Password: password123
```

*Note: Replace with actual demo credentials from your Laravel backend*

## Architecture

### Models
All API response models with `fromJson`/`toJson` serialization:
- `User` - User data and credits
- `BottleLog` - Bottle detection events
- `InternetCredit` - Available WiFi minutes
- `Machine` - Vendo machine information
- `WifiSession` - Active internet sessions

### Services
- `ApiService` - Central HTTP service for all API calls
- `StorageService` - Secure token and user data storage

### Providers
- `AuthProvider` - Authentication state management
- `BottleProvider` - Bottle history and statistics
- `CreditProvider` - Credits and session management
- `MachineProvider` - Machine monitoring

### Screens
- `LoginScreen` - User authentication
- `RegisterScreen` - New user registration
- `DashboardScreen` - Main dashboard
- `BottleHistoryScreen` - Bottle logs and statistics
- `MachineStatusScreen` - Machine monitoring

### Widgets
Reusable UI components:
- `CreditCardWidget` - Display user credits
- `SessionStatusWidget` - Active session indicator
- `InternetRequestButton` - Request WiFi access
- `QuickStatsWidget` - Statistics overview
- `BottleLogCard` - Bottle log item
- `MachineCard` - Machine status item

## Error Handling

All API calls implement comprehensive error handling:
- Network errors
- Timeout handling
- HTTP status code handling (401, 422, 500, etc.)
- User-friendly error messages

## Security

- Bearer token authentication
- Secure storage for sensitive data
- Input validation on all forms
- Password obscuring in UI

## Testing

Run unit tests:
```bash
flutter test
```

## Build for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Performance Considerations

- Pagination for large lists
- Lazy loading for bottle history
- Auto-refresh with configurable intervals
- Proper disposal of timers and controllers
- Optimized state management

## Contributing

Follow Flutter best practices and maintain clean architecture principles:
1. Keep business logic in providers
2. Separate UI from logic
3. Use dependency injection
4. Write tests for critical flows
5. Document complex logic

## License

Proprietary - All rights reserved

## Support

For issues or questions, contact the development team.

---

**Built with Flutter - Production Ready**

