# Pre-Production Deployment Checklist

**Project**: Bottle WiFi Vendo  
**Version**: 1.0.0  
**Target Deployment Date**: ___________  
**Reviewed By**: ___________  
**Date Reviewed**: ___________

---

## A. Testing ✅

### Unit Tests
- [ ] **Flutter Unit Tests**
  ```bash
  flutter test test/
  ```
  - [ ] All tests passing (0 failures)
  - [ ] Code coverage > 80%
  - [ ] Generate coverage report: `flutter test --coverage`

- [ ] **Laravel Unit Tests**
  ```bash
  cd bottle-wifi-backend
  php artisan test --testsuite=Unit
  ```
  - [ ] All tests passing
  - [ ] Database tests included
  - [ ] API endpoint tests included

### Feature/Integration Tests
- [ ] **Laravel Feature Tests**
  ```bash
  php artisan test --testsuite=Feature
  ```
  - [ ] Authentication flow tested
  - [ ] Bottle submission flow tested
  - [ ] Credit management tested
  - [ ] Machine management tested

- [ ] **Flutter Integration Tests**
  ```bash
  flutter test integration_test/
  ```
  - [ ] Login/logout flow tested
  - [ ] Bottle scanning tested
  - [ ] Navigation tested

### Manual Testing
- [ ] **User Flows**
  - [ ] User registration and login
  - [ ] Password reset flow
  - [ ] Bottle submission (QR code scan)
  - [ ] Credit balance check
  - [ ] WiFi voucher generation
  - [ ] Machine status monitoring
  - [ ] Profile management

- [ ] **Edge Cases**
  - [ ] Network connectivity loss handling
  - [ ] Invalid QR code scanning
  - [ ] Duplicate bottle submission prevention
  - [ ] Concurrent user testing
  - [ ] Token expiration handling
  - [ ] Invalid input validation

- [ ] **Cross-Platform Testing**
  - [ ] Android device testing (min SDK 21)
  - [ ] iOS device testing (min iOS 12)
  - [ ] Different screen sizes tested
  - [ ] Different OS versions tested

### Load Testing
- [ ] **Performance Testing**
  - [ ] Load test with 100 concurrent users
  - [ ] Load test with 500 concurrent users
  - [ ] Load test with 1000 concurrent users
  - [ ] Database query performance verified
  - [ ] API response times < 500ms
  - [ ] Memory usage monitored
  - [ ] CPU usage monitored

- [ ] **Load Testing Tools**
  ```bash
  # See LOAD_TESTING_GUIDE.md for detailed instructions
  # Using Apache Bench or k6
  ```

- [ ] **Results Documented**
  - [ ] Average response time recorded
  - [ ] Error rate < 0.1%
  - [ ] Server resources adequate
  - [ ] Bottlenecks identified and resolved

### Security Audit
- [ ] **Automated Security Scan**
  - [ ] Run security vulnerability scan on dependencies
  - [ ] SQL injection testing
  - [ ] XSS vulnerability testing
  - [ ] CSRF protection verified
  - [ ] Rate limiting tested

- [ ] **Manual Security Review**
  - [ ] Authentication tokens secure
  - [ ] Password encryption verified (bcrypt)
  - [ ] API endpoints protected
  - [ ] Input validation on all forms
  - [ ] Sensitive data not logged
  - [ ] HTTPS enforced
  - [ ] Security headers configured
  - [ ] SSL certificate valid

- [ ] **Penetration Testing** (Optional but recommended)
  - [ ] Hired security expert or used service
  - [ ] Vulnerabilities documented
  - [ ] Fixes implemented and verified

---

## B. Configuration ⚙️

### Production Environment
- [ ] **Laravel Backend (.env)**
  ```bash
  # Copy production template
  cp .env.production.example .env
  ```
  - [ ] `APP_ENV=production`
  - [ ] `APP_DEBUG=false`
  - [ ] `APP_URL` set to production domain
  - [ ] `APP_KEY` generated (`php artisan key:generate`)
  - [ ] Database credentials configured
  - [ ] Redis credentials configured
  - [ ] Mail server configured
  - [ ] Queue driver configured
  - [ ] Sentry DSN configured
  - [ ] Backup storage configured

- [ ] **Flutter App**
  - [ ] Production API base URL configured
  - [ ] Sentry DSN configured
  - [ ] Debug mode disabled
  - [ ] App signing keys configured
  - [ ] Version number updated

### Debug & Error Reporting
- [ ] **Debug Mode**
  - [ ] `APP_DEBUG=false` in production
  - [ ] Debug logs disabled in Flutter release builds
  - [ ] Stack traces not exposed to users

- [ ] **Error Reporting**
  - [ ] Sentry configured and tested
  - [ ] Error notifications working
  - [ ] Critical errors sent to Slack/email
  - [ ] User-friendly error messages displayed

### Logging
- [ ] **Log Configuration**
  - [ ] Log rotation configured (daily logs)
  - [ ] Log retention policy set (30 days)
  - [ ] Separate logs for auth, performance, errors
  - [ ] Log storage adequate
  - [ ] Logs not containing sensitive data

- [ ] **Log Monitoring**
  - [ ] Log aggregation set up (optional: ELK stack)
  - [ ] Critical error alerts configured
  - [ ] Daily log review scheduled

### SSL Certificates
- [ ] **SSL Setup**
  - [ ] SSL certificate purchased/obtained (Let's Encrypt)
  - [ ] Certificate installed on server
  - [ ] Certificate auto-renewal configured
  - [ ] HTTPS redirect enabled
  - [ ] Certificate valid for all subdomains
  - [ ] Certificate expiry monitoring active

- [ ] **SSL Verification**
  - [ ] HTTPS accessible
  - [ ] No mixed content warnings
  - [ ] SSL Labs test grade A or higher
  - [ ] HTTP/2 enabled

### DNS Configuration
- [ ] **Domain Setup**
  - [ ] Domain purchased and registered
  - [ ] A record pointing to server IP
  - [ ] CNAME records for subdomains (if any)
  - [ ] MX records for email (if applicable)
  - [ ] TTL set appropriately
  - [ ] DNS propagation verified (48 hours)

- [ ] **CDN Configuration** (Optional)
  - [ ] CDN service configured (Cloudflare, AWS CloudFront)
  - [ ] Static assets served through CDN
  - [ ] Cache rules configured

---

## C. Data 📊

### Database Setup
- [ ] **Production Database**
  - [ ] Database server installed and configured
  - [ ] Database created
  - [ ] Database user created with appropriate permissions
  - [ ] Database backups configured
  - [ ] Database performance tuned

### Migrations
- [ ] **Run Migrations**
  ```bash
  php artisan migrate --force
  ```
  - [ ] All migrations executed successfully
  - [ ] Database schema verified
  - [ ] Indexes created
  - [ ] Foreign keys configured

- [ ] **Migration Backup**
  - [ ] Pre-migration database backup created
  - [ ] Rollback plan documented
  - [ ] Migration logs saved

### Seeders
- [ ] **Initial Data**
  ```bash
  php artisan db:seed --class=ProductionSeeder
  ```
  - [ ] Admin account created
  - [ ] Default settings seeded
  - [ ] Machine data imported
  - [ ] Initial credit packages created
  - [ ] Test data removed

### Admin Account
- [ ] **Admin Creation**
  - [ ] Admin user created
  - [ ] Strong password set
  - [ ] Admin email configured
  - [ ] Admin credentials stored securely
  - [ ] Admin permissions verified

### Machine Data
- [ ] **Machine Import**
  - [ ] Machine locations added
  - [ ] Machine QR codes generated
  - [ ] Machine status verified
  - [ ] Machine photos uploaded (if applicable)
  - [ ] Machine test submissions working

---

## D. Monitoring 📡

### Error Tracking
- [ ] **Sentry Setup**
  - [ ] Sentry project created for Flutter
  - [ ] Sentry project created for Laravel
  - [ ] DSN configured in both apps
  - [ ] Error reporting tested
  - [ ] Alert rules configured
  - [ ] Team members invited

- [ ] **Error Alerts**
  - [ ] Critical errors -> Slack/Email immediately
  - [ ] Warning errors -> Daily digest
  - [ ] Error grouping configured
  - [ ] False positives filtered

### Uptime Monitoring
- [ ] **Monitoring Service**
  - [ ] UptimeRobot or Pingdom configured
  - [ ] Health endpoint monitored (`/health`)
  - [ ] Check interval: 5 minutes
  - [ ] Multiple geo-locations enabled
  - [ ] Expected status code: 200

- [ ] **Uptime Alerts**
  - [ ] Email alert on downtime
  - [ ] SMS alert on critical downtime (optional)
  - [ ] Escalation policy defined
  - [ ] Response time threshold set

### Backup System
- [ ] **Database Backups**
  - [ ] Automatic daily backups configured
  - [ ] Backup retention: 30 days
  - [ ] Backup storage location secure
  - [ ] Backup encryption enabled
  - [ ] Backup tested (restore test)

- [ ] **Backup Schedule**
  ```bash
  # Daily backup at 2 AM
  0 2 * * * /path/to/backup-script.sh
  ```
  - [ ] Backup script created
  - [ ] Cron job scheduled
  - [ ] Backup verification automated
  - [ ] Backup failure alerts configured

- [ ] **Application Backups**
  - [ ] Code repository backed up
  - [ ] Environment files backed up (encrypted)
  - [ ] Uploaded files backed up
  - [ ] Configuration files backed up

### Alert Channels
- [ ] **Alert Configuration**
  - [ ] Slack webhook configured
  - [ ] Email alerts configured
  - [ ] SMS alerts configured (optional)
  - [ ] PagerDuty integrated (optional)

- [ ] **Alert Testing**
  - [ ] Test error sent successfully
  - [ ] Test downtime alert received
  - [ ] Test slow query alert received
  - [ ] All team members receive alerts

---

## E. Legal & Compliance ⚖️

### Privacy Policy
- [ ] **Privacy Policy Document**
  - [ ] Privacy policy created (see `PRIVACY_POLICY.md`)
  - [ ] Data collection practices documented
  - [ ] Data usage explained
  - [ ] Data storage location specified
  - [ ] User rights explained
  - [ ] Contact information provided

- [ ] **Privacy Policy Implementation**
  - [ ] Privacy policy accessible in app
  - [ ] Privacy policy shown during signup
  - [ ] Privacy policy accepted by users
  - [ ] Privacy policy date versioned

### Terms of Service
- [ ] **ToS Document**
  - [ ] Terms of service created (see `TERMS_OF_SERVICE.md`)
  - [ ] User obligations defined
  - [ ] Service limitations explained
  - [ ] Liability disclaimers included
  - [ ] Termination conditions specified
  - [ ] Dispute resolution process defined

- [ ] **ToS Implementation**
  - [ ] ToS accessible in app
  - [ ] ToS acceptance required for signup
  - [ ] ToS version tracked
  - [ ] ToS updates communicated to users

### GDPR Compliance (EU Users)
- [ ] **GDPR Requirements**
  - [ ] Legal basis for data processing identified
  - [ ] Privacy policy GDPR-compliant
  - [ ] Cookie consent implemented (if using cookies)
  - [ ] Data portability enabled
  - [ ] Right to deletion implemented
  - [ ] Data breach notification process defined
  - [ ] DPO appointed (if required)

- [ ] **User Rights Implementation**
  - [ ] Data export functionality
  - [ ] Account deletion functionality
  - [ ] Data correction functionality
  - [ ] Consent withdrawal option

### Data Retention
- [ ] **Retention Policy**
  - [ ] Data retention periods defined
  - [ ] Inactive account handling defined
  - [ ] Data deletion schedule created
  - [ ] Archived data accessible
  - [ ] Retention policy documented

- [ ] **Data Retention Implementation**
  ```bash
  # Auto-delete old data
  php artisan cleanup:old-data
  ```
  - [ ] Automated cleanup scripts created
  - [ ] Data anonymization for analytics
  - [ ] Backup retention separate from production

### Additional Legal Documents
- [ ] **Other Documents** (if applicable)
  - [ ] Refund policy
  - [ ] Cookie policy
  - [ ] Acceptable use policy
  - [ ] Copyright notices
  - [ ] Licensing information

---

## F. Deployment Checklist 🚀

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Security audit completed
- [ ] Database backed up
- [ ] Deployment plan documented
- [ ] Rollback plan prepared
- [ ] Team notified of deployment

### Deployment
- [ ] Code deployed to production
- [ ] Database migrations run
- [ ] Cache cleared
- [ ] Config cached (`php artisan config:cache`)
- [ ] Routes cached (`php artisan route:cache`)
- [ ] Views cached (`php artisan view:cache`)
- [ ] Queue workers restarted
- [ ] Application restarted

### Post-Deployment
- [ ] Smoke tests passed
- [ ] Health endpoints responding
- [ ] Critical user flows tested
- [ ] Error monitoring verified
- [ ] Performance metrics normal
- [ ] Team notified of successful deployment

---

## G. Performance Optimization ⚡

- [ ] **API Optimization**
  - [ ] Database queries optimized
  - [ ] N+1 queries eliminated
  - [ ] Caching implemented
  - [ ] API pagination implemented
  - [ ] Response compression enabled

- [ ] **Flutter App Optimization**
  - [ ] Images optimized
  - [ ] App size minimized
  - [ ] Release build tested
  - [ ] Obfuscation enabled
  - [ ] Tree shaking enabled

---

## H. Documentation 📚

- [ ] **Technical Documentation**
  - [ ] API documentation complete
  - [ ] Database schema documented
  - [ ] Deployment guide created
  - [ ] Troubleshooting guide created
  - [ ] Architecture diagram created

- [ ] **User Documentation**
  - [ ] User manual created
  - [ ] FAQ document created
  - [ ] Tutorial videos (optional)
  - [ ] Support contact information

---

## Final Sign-Off

### Checklist Completion
- [ ] All critical items completed (A, B, C, D)
- [ ] Legal compliance verified (E)
- [ ] Documentation complete (H)
- [ ] Stakeholder approval obtained

### Deployment Authorization
- **Project Manager**: _________________ Date: _______
- **Technical Lead**: _________________ Date: _______
- **Security Officer**: _________________ Date: _______
- **Legal Counsel**: _________________ Date: _______ (if applicable)

### Go-Live Decision
- [ ] **APPROVED FOR PRODUCTION DEPLOYMENT**
- [ ] **NOT APPROVED** - Issues to resolve: _______________

---

## Post-Launch Monitoring (First 24 Hours)

- [ ] Hour 1: Monitor error rates, response times
- [ ] Hour 2: Verify user signups working
- [ ] Hour 4: Check database performance
- [ ] Hour 8: Review logs for issues
- [ ] Hour 24: Full system health check
- [ ] Week 1: Daily monitoring and user feedback review

---

## Support Plan

- **On-Call Contact**: _____________________
- **Phone**: _____________________
- **Email**: _____________________
- **Backup Contact**: _____________________
- **Escalation Path**: _____________________

---

## Notes & Issues

_Document any issues encountered during checklist completion:_

---

**Checklist Version**: 1.0  
**Last Updated**: February 7, 2026  
**Next Review Date**: _____________________
