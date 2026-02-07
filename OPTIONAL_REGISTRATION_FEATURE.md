# Optional Registration Feature

## Overview
Users can now optionally register an account after scanning multiple bottles. This allows them to save their credits instead of using WiFi immediately.

## How It Works

### Guest Flow
1. **Insert Bottle** - User scans bottle as guest (no account needed)
2. **Get WiFi** - Receives 30 minutes of instant WiFi
3. **Smart Suggestion** - After 3+ bottles, system suggests registration
4. **Optional Registration** - User can create account to save credits

### Registration Benefits
- 📊 Track bottle recycling history
- 💎 Earn bonus credits and rewards  
- ⚡ Access premium WiFi speeds
- 🔔 Get notifications for special offers
- 💰 Save credits for later use

## Backend Implementation

### New Service
**`GuestToUserConversionService.php`**
- `convertGuestToUser()` - Creates user account and transfers all guest sessions
- `getConversionPreview()` - Shows user their accumulated credits before registration
- `shouldSuggestRegistration()` - Returns true if user has 3+ bottles, 60+ minutes, or 1+ days of activity

### New Controller
**`GuestConversionController.php`**
- `POST /api/v1/guest/register` - Convert guest to registered user
- `GET /api/v1/guest/conversion-preview` - Preview credits before registration
- `GET /api/v1/guest/should-register` - Check if registration should be suggested

### Database Updates
**`guest_limits` table** - Added:
- `converted_to_user_id` - Foreign key to users table
- `converted_at` - Timestamp of conversion
- `minutes_earned_total` - Total minutes earned across all time

### Conversion Logic
When a guest registers:
1. Create new user account
2. Link all guest WiFi sessions to the new user
3. Create `internet_credit` record with accumulated minutes
4. Mark guest_limit as converted
5. Return authentication token for immediate login

## Frontend Implementation

### New Screen
**`OptionalRegistrationScreen`**
- Shows current stats (bottles scanned, minutes earned)
- Lists benefits of registration
- Registration form (name, email, password)
- Success dialog with credits summary

### Updated Screens
**`GuestWifiSessionScreen`**
- Shows registration suggestion banner (if 3+ bottles)
- "Create Free Account" button
- Checks `shouldSuggestRegistration` API on load

**`GuestService`**
- `convertToRegisteredUser()` - API call to register
- `getConversionPreview()` - Fetch accumulated credits
- `shouldSuggestRegistration()` - Check suggestion status

## API Endpoints

### Guest Registration
```http
POST /api/v1/guest/register
Content-Type: application/json

{
  "device_fingerprint": "abc123...",
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepass",
  "password_confirmation": "securepass"
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "user": {
    "id": 5,
    "name": "John Doe",
    "email": "john@example.com"
  },
  "token": "3|laravel_sanctum_token...",
  "credits": {
    "total_minutes": 90,
    "used_minutes": 30,
    "remaining_minutes": 60,
    "bottles_scanned": 3
  },
  "message": "Welcome! Your 3 bottles have been converted to 90 minutes of WiFi credit."
}
```

### Conversion Preview
```http
GET /api/v1/guest/conversion-preview?device_fingerprint=abc123...
```

**Response:**
```json
{
  "success": true,
  "preview": {
    "total_bottles_scanned": 3,
    "total_minutes_earned": 90,
    "minutes_used": 30,
    "minutes_remaining": 60,
    "sessions_count": 3,
    "first_scan": "2026-02-07T10:00:00Z",
    "last_scan": "2026-02-07T14:30:00Z"
  },
  "benefits": [
    "Track your bottle history",
    "Earn bonus credits and rewards",
    "Access premium WiFi speeds",
    "Get notifications for special offers",
    "Save credits for later use"
  ]
}
```

### Should Register Check
```http
GET /api/v1/guest/should-register?device_fingerprint=abc123...
```

**Response:**
```json
{
  "success": true,
  "should_suggest": true,
  "message": "Guest has scanned multiple bottles. Registration recommended."
}
```

## User Experience

### Registration Trigger
System suggests registration when guest has:
- **3+ bottles scanned**, OR
- **60+ minutes earned**, OR
- **1+ days of activity**

### Registration Flow
1. Guest sees orange banner: *"Save Your Credits!"*
2. Taps "Create Free Account" button
3. Views preview of accumulated credits
4. Fills registration form (name, email, password)
5. Submits form
6. Success dialog shows:
   - Total credits transferred
   - Bottles recycled count
   - Available WiFi minutes
7. Automatically logged in and redirected to dashboard

### Optional Nature
- Registration is **never forced**
- Guest can tap "Maybe Later" anytime
- Can continue scanning bottles without account
- Suggestion only appears after multiple bottles

## Security Features

### Email Validation
- Must be valid email format
- Must be unique (not already registered)

### Password Requirements
- Minimum 6 characters
- Must match confirmation

### Device Linking
- All guest sessions permanently linked to new user account
- Prevents duplicate credit claiming
- Device fingerprint marked as converted

## Testing

### Test Guest Registration
1. Run backend: `php artisan serve`
2. Run Flutter: `flutter run -d chrome`
3. Scan 3+ bottles as guest
4. Orange banner should appear: "Save Your Credits!"
5. Tap "Create Free Account"
6. Fill form and register
7. Verify success dialog shows correct credits
8. Verify automatic login and dashboard redirect

### Test API Directly
```bash
# 1. Scan 3 bottles as guest
curl -X POST http://localhost:8000/api/v1/guest/bottle-scan \
  -H "Content-Type: application/json" \
  -d '{
    "machine_identifier": "ESP32_001",
    "device_fingerprint": "test_user_fp_123"
  }'

# 2. Check if registration should be suggested
curl http://localhost:8000/api/v1/guest/should-register?device_fingerprint=test_user_fp_123

# 3. Get conversion preview
curl http://localhost:8000/api/v1/guest/conversion-preview?device_fingerprint=test_user_fp_123

# 4. Register account
curl -X POST http://localhost:8000/api/v1/guest/register \
  -H "Content-Type: application/json" \
  -d '{
    "device_fingerprint": "test_user_fp_123",
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }'
```

## Database Queries

### Check Guest Stats Before Conversion
```sql
SELECT 
  gl.*,
  COUNT(ws.id) as total_sessions,
  SUM(ws.allocated_minutes) as total_minutes
FROM guest_limits gl
LEFT JOIN wifi_sessions ws ON ws.device_fingerprint = gl.device_fingerprint
WHERE gl.device_fingerprint = 'test_user_fp_123'
GROUP BY gl.id;
```

### Check User Credits After Conversion
```sql
SELECT 
  u.name,
  u.email,
  ic.minutes_purchased,
  ic.minutes_used,
  ic.minutes_remaining,
  ic.source
FROM users u
JOIN internet_credits ic ON ic.user_id = u.id
WHERE u.email = 'test@example.com';
```

### Verify Session Transfer
```sql
SELECT 
  ws.session_token,
  ws.is_guest,
  ws.user_id,
  ws.allocated_minutes,
  u.email
FROM wifi_sessions ws
LEFT JOIN users u ON u.id = ws.user_id
WHERE ws.device_fingerprint = 'test_user_fp_123';
```

## Edge Cases Handled

### Email Already Exists
- Returns error: "Email already registered. Please login instead."
- Does not create duplicate account
- Guest sessions remain as guest

### No Guest Sessions
- Still allows registration
- Creates user with 0 credits
- Useful for users who want account before scanning

### Partial Session Usage
- Calculates remaining minutes: `total_earned - total_used`
- Transfers only unused minutes to credit balance
- Maintains accurate accounting

## Future Enhancements

1. **Bonus Credits** - Give 10% bonus minutes on registration
2. **Referral System** - Earn credits for inviting friends
3. **Loyalty Tiers** - Bronze/Silver/Gold based on bottles scanned
4. **Email Verification** - Optional email confirmation
5. **Social Login** - Google/Facebook OAuth
6. **Account Merging** - Combine multiple guest devices into one account

## Files Modified

### Backend
- ✅ `app/Services/GuestToUserConversionService.php` (NEW)
- ✅ `app/Http/Controllers/GuestConversionController.php` (NEW)
- ✅ `database/migrations/2024_01_09_000002_create_guest_limits_table.php` (UPDATED)
- ✅ `app/Models/GuestLimit.php` (UPDATED - added minutes_earned_total tracking)
- ✅ `routes/api.php` (UPDATED - added 3 new routes)

### Frontend
- ✅ `lib/screens/optional_registration_screen.dart` (NEW)
- ✅ `lib/screens/guest_wifi_session_screen.dart` (UPDATED - added registration banner)
- ✅ `lib/services/guest_service.dart` (UPDATED - added 3 conversion methods)
- ✅ `lib/main.dart` (UPDATED - added import)

## Key Takeaways

✅ **Zero Friction** - Registration is optional, not required
✅ **Smart Suggestions** - Only suggested after meaningful activity (3+ bottles)
✅ **Credit Transfer** - All guest sessions automatically linked to new account
✅ **Immediate Login** - User logged in automatically after registration
✅ **Security** - Device fingerprint prevents duplicate credit claiming
✅ **User Choice** - "Maybe Later" button allows skipping anytime
