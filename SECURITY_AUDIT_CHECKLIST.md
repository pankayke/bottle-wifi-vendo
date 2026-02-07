# Security Audit Checklist

Complete security audit checklist for Bottle WiFi Vendo before production deployment.

---

## 1. Authentication & Authorization

### Password Security
- [ ] Passwords hashed with bcrypt (Laravel default)
- [ ] Minimum password length enforced (8 characters)
- [ ] Password complexity requirements
- [ ] Password reset functionality secure
- [ ] Old passwords not reusable
- [ ] Account lockout after failed attempts

### Token Security
- [ ] JWT tokens used for API authentication
- [ ] Tokens have expiration time
- [ ] Refresh token mechanism implemented
- [ ] Tokens stored securely on client (flutter_secure_storage)
- [ ] Tokens transmitted over HTTPS only
- [ ] Token revocation possible

### Session Management
- [ ] Sessions expire after inactivity
- [ ] Logout invalidates tokens
- [ ] Concurrent session handling defined
- [ ] Session hijacking prevention

---

## 2. Input Validation & Sanitization

### API Endpoints
- [ ] All input validated server-side
- [ ] Laravel validation rules applied
- [ ] SQL injection prevention (using Eloquent ORM)
- [ ] NoSQL injection prevention (if applicable)
- [ ] Command injection prevention
- [ ] Path traversal prevention
- [ ] File upload validation (type, size, content)

### Client-Side
- [ ] Form validation in Flutter app
- [ ] XSS prevention in any web views
- [ ] User input sanitized before display
- [ ] HTML/JavaScript injection prevented

### Common Vulnerabilities
```bash
# Test SQL Injection
curl -X POST http://localhost:8000/api/login \
  -d "username=admin' OR '1'='1&password=test"

# Should be blocked by validation

# Test XSS
curl -X POST http://localhost:8000/api/profile \
  -d "name=<script>alert('XSS')</script>"

# Should be sanitized
```

---

## 3. API Security

### Endpoint Protection
- [ ] All sensitive endpoints require authentication
- [ ] Authorization checks on all resources
- [ ] Rate limiting implemented
  ```php
  // config/app.php
  'throttle:60,1' // 60 requests per minute
  ```
- [ ] CORS configured properly
- [ ] API versioning implemented
- [ ] Unused endpoints disabled

### Data Exposure
- [ ] Sensitive data not exposed in responses
- [ ] Error messages don't reveal system details
- [ ] Stack traces disabled in production
- [ ] Database IDs obfuscated (if needed)
- [ ] Pagination limits enforced

### API Testing
```bash
# Test rate limiting
for i in {1..100}; do
  curl http://localhost:8000/api/bottles
done

# Test unauthorized access
curl http://localhost:8000/api/admin/users

# Test CORS
curl -H "Origin: http://malicious-site.com" \
  http://localhost:8000/api/bottles
```

---

## 4. Data Protection

### Encryption
- [ ] HTTPS enforced (TLS 1.2+)
- [ ] Database encryption at rest (if required)
- [ ] Sensitive fields encrypted in database
- [ ] Secure communication between services
- [ ] Environment variables encrypted

### Sensitive Data Handling
- [ ] Credit card data never stored (if applicable)
- [ ] Personal data minimized
- [ ] Passwords never logged
- [ ] API keys not in source code
- [ ] Tokens not in URLs
- [ ] Sensitive data not in error messages

### Data Transmission
- [ ] All API calls over HTTPS
- [ ] Certificate pinning in mobile app (optional)
- [ ] Secure WebSocket connections (if used)

---

## 5. Database Security

### Access Control
- [ ] Database user has minimal permissions
- [ ] Database not accessible from public internet
- [ ] Strong database password
- [ ] Database credentials in environment variables
- [ ] Separate databases for dev/staging/production

### Query Security
- [ ] Prepared statements used (Eloquent default)
- [ ] Raw queries parameterized
- [ ] ORM used for all database operations
- [ ] SQL injection testing passed

### Backup Security
- [ ] Backups encrypted
- [ ] Backup access restricted
- [ ] Backup restoration tested
- [ ] Backup retention policy defined

---

## 6. Infrastructure Security

### Server Configuration
- [ ] Firewall configured
- [ ] Unnecessary services disabled
- [ ] SSH key authentication only
- [ ] Non-standard SSH port (optional)
- [ ] Regular security updates applied
- [ ] Server hardening completed

### Web Server
- [ ] Nginx/Apache security headers configured
  ```nginx
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-Content-Type-Options "nosniff";
  add_header X-XSS-Protection "1; mode=block";
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";
  add_header Content-Security-Policy "default-src 'self'";
  ```
- [ ] Directory listing disabled
- [ ] Hidden files not accessible
- [ ] Error pages don't reveal server info

### SSL/TLS
- [ ] Valid SSL certificate installed
- [ ] TLS 1.2+ only
- [ ] Strong cipher suites
- [ ] SSL Labs grade A or higher
- [ ] Certificate auto-renewal configured
- [ ] HTTP redirects to HTTPS

---

## 7. Application Security

### Laravel Configuration
- [ ] `APP_DEBUG=false` in production
- [ ] `APP_ENV=production`
- [ ] CSRF protection enabled
- [ ] Secure session configuration
  ```php
  // config/session.php
  'secure' => true,
  'http_only' => true,
  'same_site' => 'lax',
  ```
- [ ] File permissions correct (755 for directories, 644 for files)
- [ ] Storage directory writable but not executable

### Dependency Security
```bash
# Check for vulnerabilities in PHP dependencies
composer audit

# Check for outdated packages
composer outdated

# Update dependencies
composer update
```

```bash
# Check Flutter dependencies
flutter pub outdated

# Check for security advisories
flutter pub upgrade --dry-run
```

### Code Security
- [ ] No hardcoded credentials
- [ ] No commented-out sensitive code
- [ ] Debug code removed
- [ ] Proper error handling
- [ ] Logging doesn't include sensitive data
- [ ] Code obfuscation in Flutter release build

---

## 8. Mobile App Security

### Flutter App
- [ ] Release mode build tested
- [ ] Code obfuscation enabled
  ```bash
  flutter build apk --obfuscate --split-debug-info=./debug-info
  ```
- [ ] Secure storage for tokens
- [ ] Root/Jailbreak detection (optional)
- [ ] Certificate pinning (optional)
- [ ] App signing configured
- [ ] ProGuard rules configured (Android)

### API Communication
- [ ] HTTPS only
- [ ] Certificate validation
- [ ] Timeout configurations
- [ ] Retry logic with backoff
- [ ] Network error handling

---

## 9. Logging & Monitoring

### Logging
- [ ] Authentication attempts logged
- [ ] Failed login attempts logged
- [ ] Admin actions logged
- [ ] Sensitive data not logged
- [ ] Log rotation configured
- [ ] Log access restricted

### Monitoring
- [ ] Sentry error tracking active
- [ ] Uptime monitoring configured
- [ ] Performance monitoring active
- [ ] Security alerts configured
- [ ] Anomaly detection (optional)

---

## 10. Business Logic Security

### Authorization
- [ ] Users can only access their own data
- [ ] Admin/user roles properly enforced
- [ ] Resource ownership verified
- [ ] Horizontal privilege escalation prevented
- [ ] Vertical privilege escalation prevented

### Transaction Security
- [ ] Bottle submissions prevent duplicates
- [ ] Credit transactions atomic
- [ ] Race conditions prevented
- [ ] Idempotency for critical operations
- [ ] Audit trail for financial transactions

### Rate Limiting
- [ ] API rate limiting per user
- [ ] Bottle submission rate limiting
- [ ] Login attempt rate limiting
- [ ] Password reset rate limiting

---

## 11. Third-Party Integrations

### External Services
- [ ] API keys securely stored
- [ ] Webhooks verified (signatures)
- [ ] Third-party SSL certificates validated
- [ ] Timeout configurations
- [ ] Error handling for service failures

### Dependencies
- [ ] Regular dependency updates
- [ ] Security advisories monitored
- [ ] Unused dependencies removed
- [ ] License compliance checked

---

## 12. Incident Response

### Preparation
- [ ] Incident response plan documented
- [ ] Contact list for security incidents
- [ ] Backup restoration process tested
- [ ] Data breach notification process defined
- [ ] Legal compliance requirements documented

### Detection
- [ ] Monitoring alerts configured
- [ ] Log analysis tools in place
- [ ] Anomaly detection configured
- [ ] Security event escalation defined

---

## Security Testing Tools

### Automated Scanners

**1. OWASP ZAP**
```bash
# Download from https://www.zaproxy.org/
# Scan your API
zap-cli quick-scan http://your-api-domain.com
```

**2. SQLMap (SQL Injection)**
```bash
# Install
pip install sqlmap

# Test endpoint
sqlmap -u "http://your-api-domain.com/api/login" --data="username=test&password=test"
```

**3. Nikto (Web Server Scanner)**
```bash
# Install
apt-get install nikto

# Scan
nikto -h http://your-api-domain.com
```

**4. Composer Audit**
```bash
cd bottle-wifi-backend
composer audit
```

### Manual Testing

**1. Authentication Bypass**
```bash
# Try accessing protected endpoint without token
curl http://your-api-domain.com/api/user/profile

# Try with invalid token
curl -H "Authorization: Bearer invalid_token" \
  http://your-api-domain.com/api/user/profile

# Try with expired token
curl -H "Authorization: Bearer expired_token" \
  http://your-api-domain.com/api/user/profile
```

**2. Authorization Testing**
```bash
# Try accessing another user's data
curl -H "Authorization: Bearer user1_token" \
  http://your-api-domain.com/api/users/2/profile

# Should return 403 Forbidden
```

**3. Input Validation**
```bash
# Test with malicious input
curl -X POST http://your-api-domain.com/api/bottles/submit \
  -d "qr_code=../../../etc/passwd"

curl -X POST http://your-api-domain.com/api/bottles/submit \
  -d "qr_code=<script>alert('XSS')</script>"
```

**4. Rate Limiting**
```bash
# Hit endpoint rapidly
for i in {1..100}; do
  curl http://your-api-domain.com/api/bottles &
done

# Should get 429 Too Many Requests
```

---

## Security Audit Report Template

```markdown
# Security Audit Report
**Date**: ___________
**Auditor**: ___________
**Application**: Bottle WiFi Vendo v1.0.0

## Executive Summary
- Overall Risk Level: [Low/Medium/High/Critical]
- Critical Issues Found: X
- High Issues Found: X
- Medium Issues Found: X
- Low Issues Found: X

## Findings

### Critical Issues
1. **Issue Title**
   - Description: ...
   - Impact: ...
   - Recommendation: ...
   - Status: [Open/Fixed]

### High Issues
...

### Medium Issues
...

### Low Issues
...

## Testing Performed
- [ ] Authentication testing
- [ ] Authorization testing
- [ ] Input validation testing
- [ ] SQL injection testing
- [ ] XSS testing
- [ ] CSRF testing
- [ ] Session management testing
- [ ] Cryptography testing
- [ ] Business logic testing
- [ ] API security testing

## Recommendations
1. ...
2. ...
3. ...

## Sign-Off
Auditor: _________________ Date: _______
Technical Lead: _________________ Date: _______
```

---

## Security Checklist Summary

### Critical (Must Fix Before Launch)
- [ ] All passwords hashed with bcrypt
- [ ] HTTPS enforced everywhere
- [ ] SQL injection prevention verified
- [ ] Authentication on all sensitive endpoints
- [ ] APP_DEBUG=false in production
- [ ] Secure session configuration
- [ ] No hardcoded credentials

### High Priority  (Should Fix Before Launch)
- [ ] Rate limiting implemented
- [ ] CSRF protection enabled
- [ ] XSS prevention implemented
- [ ] Security headers configured
- [ ] Sensitive data encrypted
- [ ] Error messages sanitized
- [ ] File upload validation

### Medium Priority (Fix Soon After Launch)
- [ ] Certificate pinning in mobile app
- [ ] Advanced rate limiting
- [ ] Anomaly detection
- [ ] Security monitoring enhanced
- [ ] Automated security scans scheduled

### Nice to Have
- [ ] Penetration testing by expert
- [ ] Bug bounty program
- [ ] Security training for team
- [ ] Regular security audits scheduled

---

## Post-Audit Actions

1. **Fix Critical Issues**: Address all critical security issues immediately
2. **Document Findings**: Update security documentation
3. **Retest**: Verify fixes with security testing
4. **Get Sign-Off**: Security officer approval
5. **Plan Future Audits**: Schedule quarterly security reviews

---

## Additional Resources

- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Laravel Security: https://laravel.com/docs/security
- Flutter Security: https://flutter.dev/docs/deployment/security
- NIST Guidelines: https://www.nist.gov/cyberframework

---

**Security Audit Completion Date**: ____________  
**Approved By**: ____________  
**Next Audit Date**: ____________
