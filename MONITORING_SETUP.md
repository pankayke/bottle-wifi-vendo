# Monitoring & Error Tracking Setup Guide

This guide covers the complete setup and configuration of monitoring, error tracking, and performance monitoring for the Bottle WiFi Vendo application.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Flutter App Monitoring](#flutter-app-monitoring)
3. [Laravel Backend Monitoring](#laravel-backend-monitoring)
4. [External Services Setup](#external-services-setup)
5. [Alert Configuration](#alert-configuration)
6. [Best Practices](#best-practices)

---

## Overview

The application includes comprehensive monitoring across three main areas:

### A. Error Tracking
- ✅ Sentry integration for real-time error tracking
- ✅ Automatic error capturing and reporting
- ✅ Failed authentication attempt tracking
- ✅ API error monitoring

### B. Performance Monitoring
- ✅ API response time tracking
- ✅ Database query performance monitoring
- ✅ Server resource monitoring (CPU, memory, disk)
- ✅ Slow request alerts

### C. Uptime Monitoring
- ✅ Health check endpoints for external monitoring
- ✅ Component-specific health checks
- ✅ System metrics and statistics

---

## Flutter App Monitoring

### 1. Install Dependencies

The Sentry Flutter SDK has been added to `pubspec.yaml`:

```bash
flutter pub get
```

### 2. Configure Sentry DSN

Update `lib/main.dart` with your Sentry DSN:

```dart
options.dsn = 'YOUR_SENTRY_DSN_HERE';
```

**Get your Sentry DSN:**
1. Go to [sentry.io](https://sentry.io)
2. Create a new project (Flutter)
3. Copy the DSN from project settings

### 3. Environment Configuration

Set environment variables for different builds:

```bash
# Development
flutter run --dart-define=ENVIRONMENT=development --dart-define=DEBUG=true

# Production
flutter build apk --dart-define=ENVIRONMENT=production
```

### 4. Using the Monitoring Service

The `MonitoringService` provides methods for tracking:

**Track API Calls:**
```dart
final result = await MonitoringService.trackApiCall(
  endpoint: '/api/bottles',
  method: 'GET',
  operation: () => apiService.getBottles(),
);
```

**Track Authentication:**
```dart
await MonitoringService.trackAuthenticationAttempt(
  username: username,
  success: true,
);
```

**Track Custom Events:**
```dart
await MonitoringService.trackEvent(
  name: 'Bottle Submitted',
  properties: {'bottle_id': bottleId},
  level: SentryLevel.info,
);
```

**Track Errors:**
```dart
await MonitoringService.trackError(
  error: error,
  stackTrace: stackTrace,
  context: 'Bottle submission failed',
  extraData: {'bottle_id': bottleId},
);
```

### 5. Integrating with Existing Code

Update your API service to use monitoring:

```dart
// In your API service method
Future<List<Bottle>> getBottles() async {
  return MonitoringService.trackApiCall(
    endpoint: '/api/bottles',
    method: 'GET',
    operation: () async {
      final response = await dio.get('/api/bottles');
      return (response.data as List)
          .map((json) => Bottle.fromJson(json))
          .toList();
    },
  );
}
```

---

## Laravel Backend Monitoring

### 1. Install Sentry Laravel SDK

```bash
cd bottle-wifi-backend
composer require sentry/sentry-laravel
```

### 2. Publish Sentry Configuration

```bash
php artisan sentry:publish --dsn=YOUR_SENTRY_DSN_HERE
```

### 3. Update Environment Variables

Add to `.env`:

```env
# Sentry Configuration
SENTRY_LARAVEL_DSN=your-sentry-dsn-here
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=1.0
SENTRY_PROFILES_SAMPLE_RATE=1.0

# Enable Query Logging
DB_LOG_QUERIES=true

# Slack Alerts (Optional)
LOG_SLACK_WEBHOOK_URL=your-slack-webhook-url
LOG_SLACK_USERNAME="Bottle WiFi Alerts"
```

### 4. Register Service Providers

Add to `config/app.php` in the `providers` array:

```php
App\Providers\QueryMonitoringServiceProvider::class,
```

### 5. Register Middleware

Add to `bootstrap/app.php`:

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->append([
        \App\Http\Middleware\PerformanceMonitoring::class,
        \App\Http\Middleware\AuthenticationTracking::class,
    ]);
})
```

### 6. Health Check Endpoints

The following endpoints are available for monitoring:

| Endpoint | Purpose | Use Case |
|----------|---------|----------|
| `GET /health` | Basic health check | Uptime monitoring (Pingdom/UptimeRobot) |
| `GET /health/detailed` | Full system health | Detailed monitoring dashboard |
| `GET /health/database` | Database connectivity | Database-specific monitoring |
| `GET /health/cache` | Cache system status | Cache performance tracking |
| `GET /health/metrics` | System metrics | Performance analysis |
| `GET /health/ping` | Simple ping | Basic connectivity check |
| `GET /health/version` | API version info | Deployment verification |

**Example Response:**

```json
{
  "status": "healthy",
  "timestamp": "2026-02-07T10:30:00Z",
  "checks": {
    "database": {
      "status": "healthy",
      "response_time_ms": 12.45,
      "connections": 5
    },
    "cache": {
      "status": "healthy",
      "response_time_ms": 3.21,
      "driver": "redis"
    },
    "disk": {
      "status": "healthy",
      "usage_percent": 45.23
    },
    "memory": {
      "status": "healthy",
      "usage_percent": 62.18
    },
    "cpu": {
      "status": "healthy",
      "load_average": {"1min": 0.45, "5min": 0.52, "15min": 0.48}
    }
  }
}
```

---

## External Services Setup

### 1. Sentry Setup

**Create Sentry Account & Project:**

1. Visit [sentry.io](https://sentry.io) and create an account
2. Create two projects:
   - **Flutter Project** for mobile app
   - **Laravel Project** for backend API
3. Copy both DSN values

**Configure Alerts:**

1. Go to **Alerts** → **Create Alert Rule**
2. Recommended alerts:
   - **High Error Rate**: Trigger when errors > 10/minute
   - **Slow Transactions**: Alert on API calls > 2 seconds
   - **Failed Requests**: Track failed authentications
   - **Memory Usage**: Alert on memory > 90%

**Set Up Integrations:**

- **Slack Integration**: Get notified on critical errors
- **Email Notifications**: Configure for high-priority alerts
- **Issue Assignment**: Auto-assign errors to team members

### 2. Uptime Monitoring Setup

#### Option A: Pingdom

1. Visit [pingdom.com](https://www.pingdom.com)
2. Create HTTP Check:
   - **URL**: `https://your-api-domain.com/health`
   - **Check Interval**: 1 minute
   - **Alert Policy**: Send alert after 2 failed checks
3. Add Contact Methods:
   - Email alerts
   - SMS alerts (optional)
   - Slack integration

#### Option B: UptimeRobot

1. Visit [uptimerobot.com](https://uptimerobot.com)
2. Create Monitor:
   - **Monitor Type**: HTTP(s)
   - **URL**: `https://your-api-domain.com/health`
   - **Monitoring Interval**: 5 minutes (free tier)
   - **Alert Contacts**: Email, SMS
3. Expected HTTP Status: 200

**Recommended Monitors:**

| Monitor Name | URL | Expected Status | Interval |
|--------------|-----|-----------------|----------|
| API Health | `/health` | 200 | 1 min |
| Database Health | `/health/database` | 200 | 5 min |
| API Version | `/health/version` | 200 | 5 min |

### 3. Performance Monitoring Tools

#### New Relic (Recommended for Production)

```bash
# Install New Relic PHP Agent
composer require newrelic/php-agent

# Configure in .env
NEW_RELIC_LICENSE_KEY=your-license-key
NEW_RELIC_APP_NAME="Bottle WiFi Vendo API"
```

#### Laravel Telescope (Development)

```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

Access at: `https://your-domain.com/telescope`

---

## Alert Configuration

### 1. Slack Alerts

**Create Slack Webhook:**

1. Go to Slack → Apps → Incoming Webhooks
2. Create webhook for your channel
3. Copy webhook URL to `.env`:

```env
LOG_SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

**Test Alert:**

```bash
php artisan tinker
Log::channel('alerts')->critical('Test alert from Bottle WiFi Vendo');
```

### 2. Email Alerts

Configure in `config/mail.php`:

```php
'from' => [
    'address' => env('MAIL_FROM_ADDRESS', 'alerts@bottlewifi.com'),
    'name' => env('MAIL_FROM_NAME', 'Bottle WiFi Alerts'),
],
```

### 3. Custom Alert Thresholds

Edit thresholds in monitoring classes:

**Performance Monitoring** (`app/Http/Middleware/PerformanceMonitoring.php`):
```php
// Alert on slow requests (>2000ms)
if ($executionTime > 2000) {
    $this->alertSlowRequest($request, $executionTime);
}
```

**Resource Monitoring** (`app/Services/ResourceMonitoringService.php`):
```php
// Disk space alerts
if ($usagePercent > 90) {
    $status = 'critical';  // Alert sent
} elseif ($usagePercent > 80) {
    $status = 'warning';   // Warning sent
}
```

---

## Best Practices

### 1. Error Tracking

✅ **DO:**
- Filter sensitive data before sending to Sentry
- Add context to error reports (user ID, request data)
- Set appropriate severity levels
- Group similar errors

❌ **DON'T:**
- Send passwords or tokens to error tracking
- Report expected errors (validation failures)
- Ignore error grouping and duplicates

### 2. Performance Monitoring

✅ **DO:**
- Set realistic performance thresholds
- Monitor database query counts
- Track slow endpoints separately
- Review performance trends weekly

❌ **DON'T:**
- Alert on every slow request (use aggregates)
- Ignore cache performance
- Set thresholds too low (alert fatigue)

### 3. Uptime Monitoring

✅ **DO:**
- Use multiple monitoring services
- Set up redundant alert channels
- Monitor from multiple geographic locations
- Test monitoring alerts regularly

❌ **DON'T:**
- Rely on single monitoring service
- Set overly aggressive check intervals
- Ignore health check endpoint failures

### 4. Log Management

✅ **DO:**
- Rotate logs daily/weekly
- Keep auth logs for 30+ days
- Use separate log files for different purposes
- Archive old logs to S3/storage

❌ **DON'T:**
- Keep unlimited logs (disk space)
- Log sensitive information
- Mix different log types in one file

### 5. Alert Fatigue Prevention

✅ **DO:**
- Use alert aggregation (X failures in Y minutes)
- Set up escalation policies
- Review and adjust thresholds regularly
- Use different channels for different severities

❌ **DON'T:**
- Send every error as critical
- Alert the entire team for minor issues
- Ignore repeated alerts

---

## Testing Your Monitoring Setup

### 1. Test Error Tracking

**Flutter:**
```dart
// Trigger a test error
throw Exception('Test error for monitoring');
```

**Laravel:**
```bash
php artisan tinker
throw new \Exception('Test error for Sentry');
```

### 2. Test Performance Alerts

```bash
# Create a slow endpoint temporarily
Route::get('/test-slow', function () {
    sleep(3); // Simulate 3-second response
    return response()->json(['status' => 'ok']);
});
```

### 3. Test Health Checks

```bash
# Test all health endpoints
curl http://localhost:8000/health
curl http://localhost:8000/health/detailed
curl http://localhost:8000/health/database
curl http://localhost:8000/health/cache
curl http://localhost:8000/health/metrics
```

### 4. Test Failed Authentication Tracking

```bash
# Make failed login attempt
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"wrong"}'
```

Check logs in `storage/logs/auth.log`

---

## Monitoring Dashboard URLs

After setup, access monitoring at:

- **Sentry Dashboard**: https://sentry.io/organizations/YOUR_ORG/issues/
- **UptimeRobot**: https://uptimerobot.com/dashboard
- **API Health**: https://your-domain.com/health/detailed
- **Telescope** (dev): https://your-domain.com/telescope

---

## Weekly Monitoring Checklist

- [ ] Review Sentry error trends
- [ ] Check uptime reports (should be >99.9%)
- [ ] Review slow query logs
- [ ] Check disk space usage
- [ ] Verify alert configurations are working
- [ ] Review authentication failure patterns
- [ ] Check API response time trends
- [ ] Update alert thresholds if needed

---

## Troubleshooting

### Sentry Not Receiving Errors

1. Verify DSN is correct in `.env`
2. Check `SENTRY_ENVIRONMENT` is set
3. Run `php artisan config:clear`
4. Test with: `\Sentry\captureMessage('Test message');`

### Health Checks Failing

1. Check database connectivity
2. Verify cache configuration
3. Review `storage/logs/laravel.log`
4. Test individual checks: `/health/database`, `/health/cache`

### No Performance Logs

1. Verify middleware is registered
2. Check `storage/logs/performance.log` exists
3. Ensure log directory is writable: `chmod -R 777 storage/logs`

### Alerts Not Sending

1. Verify Slack webhook URL in `.env`
2. Test: `Log::channel('alerts')->error('Test');`
3. Check `storage/logs/laravel.log` for errors

---

## Support & Resources

- **Sentry Documentation**: https://docs.sentry.io/
- **Laravel Logging**: https://laravel.com/docs/logging
- **UptimeRobot API**: https://uptimerobot.com/api/
- **New Relic Laravel**: https://docs.newrelic.com/docs/apm/agents/php-agent/

---

## Summary

Your application now has comprehensive monitoring covering:

✅ **Error Tracking**: Real-time error capture with Sentry  
✅ **Performance Monitoring**: API response times, database queries, resource usage  
✅ **Uptime Monitoring**: Health check endpoints for external services  
✅ **Authentication Tracking**: Failed login attempt detection  
✅ **Alert System**: Multi-channel alerts for critical issues  

**Next Steps:**
1. Configure Sentry DSN in both Flutter and Laravel
2. Set up UptimeRobot or Pingdom with `/health` endpoint
3. Configure Slack webhooks for alerts
4. Test all monitoring endpoints
5. Set up weekly review schedule

For questions or issues, refer to the troubleshooting section or consult the official documentation links above.
