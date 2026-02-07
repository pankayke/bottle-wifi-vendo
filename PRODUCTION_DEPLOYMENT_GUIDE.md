# Production Deployment Guide

Complete step-by-step guide for deploying Bottle WiFi Vendo to production.

---

## Pre-Deployment Checklist

Before deploying, ensure you've completed:

- [ ] All items in [PRE_PRODUCTION_CHECKLIST.md](PRE_PRODUCTION_CHECKLIST.md)
- [ ] Load testing completed successfully
- [ ] Security audit passed
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Team trained on support procedures

---

## Server Requirements

### Minimum Server Specifications

**Application Server:**
- CPU: 2 cores (4+ recommended)
- RAM: 4 GB (8+ GB recommended)
- Storage: 50 GB SSD
- OS: Ubuntu 22.04 LTS or similar
- Network: 100 Mbps upload/download

**Database Server:**
- CPU: 2 cores
- RAM: 4 GB
- Storage: 100 GB SSD
- MySQL 8.0 or MariaDB 10.6+

**Redis Server:**
- RAM: 2 GB
- Storage: 10 GB

---

## Step 1: Server Setup

### 1.1 Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.2 Install Required Software

```bash
# PHP 8.2
sudo apt install -y php8.2 php8.2-fpm php8.2-mysql php8.2-xml \
  php8.2-mbstring php8.2-curl php8.2-zip php8.2-bcmath \
  php8.2-gd php8.2-redis php8.2-intl

# Nginx
sudo apt install -y nginx

# MySQL
sudo apt install -y mysql-server

# Redis
sudo apt install -y redis-server

# Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Node.js & NPM (if needed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Git
sudo apt install -y git

# Supervisor (for queue workers)
sudo apt install -y supervisor
```

### 1.3 Secure MySQL

```bash
sudo mysql_secure_installation
```

Answer prompts:
- Set root password: Yes
- Remove anonymous users: Yes
- Disallow root login remotely: Yes
- Remove test database: Yes
- Reload privilege tables: Yes

---

## Step 2: Database Setup

### 2.1 Create Database

```bash
sudo mysql -u root -p
```

```sql
CREATE DATABASE bottle_wifi_production CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'bottle_wifi_user'@'localhost' IDENTIFIED BY 'SECURE_PASSWORD_HERE';
GRANT ALL PRIVILEGES ON bottle_wifi_production.* TO 'bottle_wifi_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 2.2 Optimize MySQL

Edit `/etc/mysql/mysql.conf.d/mysqld.cnf`:

```ini
[mysqld]
innodb_buffer_pool_size = 2G
innodb_log_file_size = 512M
max_connections = 200
query_cache_size = 0
query_cache_type = OFF
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 1
```

Restart MySQL:
```bash
sudo systemctl restart mysql
```

---

## Step 3: Deploy Application Code

### 3.1 Create Directory

```bash
sudo mkdir -p /var/www/bottle-wifi-vendo
sudo chown -R $USER:$USER /var/www/bottle-wifi-vendo
```

### 3.2 Clone Repository

```bash
cd /var/www/bottle-wifi-vendo
git clone https://github.com/your-username/bottle-wifi-vendo.git .
```

Or upload files via SFTP/SCP.

### 3.3 Install Dependencies

```bash
cd /var/www/bottle-wifi-vendo/bottle-wifi-backend

# Install PHP dependencies
composer install --no-dev --optimize-autoloader

# Install Node dependencies (if applicable)
npm install --production
npm run build
```

---

## Step 4: Configure Environment

### 4.1 Copy Environment File

```bash
cd /var/www/bottle-wifi-vendo/bottle-wifi-backend
cp .env.production.example .env
```

### 4.2 Edit .env File

```bash
nano .env
```

Update all values:
- Database credentials
- App URL
- Mail configuration
- Redis configuration
- Sentry DSN
- Slack webhooks
- All API keys

### 4.3 Generate Application Key

```bash
php artisan key:generate
```

---

## Step 5: Run Migrations and Seeders

### 5.1 Run Migrations

```bash
php artisan migrate --force
```

### 5.2 Seed Production Data

```bash
php artisan db:seed --class=ProductionSeeder
```

### 5.3 Create Admin Account

The seeder creates an admin account. Change the password immediately:

```bash
php artisan tinker
```

```php
$admin = User::where('email', 'admin@bottlewifi.com')->first();
$admin->password = Hash::make('YourSecurePassword123!');
$admin->save();
```

---

## Step 6: Configure Nginx

### 6.1 Create Nginx Config

```bash
sudo nano /etc/nginx/sites-available/bottle-wifi-vendo
```

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    root /var/www/bottle-wifi-vendo/bottle-wifi-backend/public;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;

    index index.php;

    charset utf-8;

    # Maximum upload size
    client_max_body_size 20M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 6.2 Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/bottle-wifi-vendo /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Step 7: Install SSL Certificate

### 7.1 Install Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 7.2 Obtain Certificate

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

### 7.3 Auto-Renewal

```bash
sudo certbot renew --dry-run
```

---

## Step 8: Configure Queue Workers

### 8.1 Create Supervisor Config

```bash
sudo nano /etc/supervisor/conf.d/bottle-wifi-worker.conf
```

```ini
[program:bottle-wifi-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/bottle-wifi-vendo/bottle-wifi-backend/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=4
redirect_stderr=true
stdout_logfile=/var/www/bottle-wifi-vendo/bottle-wifi-backend/storage/logs/worker.log
stopwaitsecs=3600
```

### 8.2 Start Workers

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start bottle-wifi-worker:*
```

---

## Step 9: Set File Permissions

```bash
cd /var/www/bottle-wifi-vendo/bottle-wifi-backend

# Set ownership
sudo chown -R www-data:www-data .

# Set directory permissions
sudo find . -type d -exec chmod 755 {} \;

# Set file permissions
sudo find . -type f -exec chmod 644 {} \;

# Storage and cache must be writable
sudo chmod -R 775 storage bootstrap/cache
sudo chown -R www-data:www-data storage bootstrap/cache
```

---

## Step 10: Deploy Flutter App

### 10.1 Update API Base URL

In Flutter project, update `lib/utils/constants.dart`:

```dart
static const String baseUrl = 'https://your-domain.com/api';
```

### 10.2 Update Sentry DSN

In `lib/main.dart`:

```dart
options.dsn = 'YOUR_FLUTTER_SENTRY_DSN';
```

### 10.3 Build for Android

```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

### 10.4 Build for iOS

```bash
flutter build ios --release
```

### 10.5 Publish to Stores

- **Google Play Store**: Follow Google Play Console upload process
- **Apple App Store**: Follow App Store Connect submission process

---

## Step 11: Set Up Monitoring

### 11.1 Enable Sentry

Already configured in .env. Verify by triggering a test error.

### 11.2 Configure UptimeRobot

1. Create account at uptimerobot.com
2. Add monitor: https://your-domain.com/health
3. Set check interval: 5 minutes
4. Configure alert contacts

### 11.3 Set Up Backup System

```bash
# Copy backup script
chmod +x /var/www/bottle-wifi-vendo/bottle-wifi-backend/backup.sh

# Add to crontab
crontab -e
```

Add:
```
0 2 * * * /var/www/bottle-wifi-vendo/bottle-wifi-backend/backup.sh
```

---

## Step 12: Final Checks

### 12.1 Test Health Endpoints

```bash
curl https://your-domain.com/health
curl https://your-domain.com/health/detailed
curl https://your-domain.com/health/database
```

### 12.2 Test Mobile App

1. Install app on test device
2. Register new account
3. Submit bottle
4. Check credit award
5. Generate WiFi voucher

### 12.3 Monitor Logs

```bash
tail -f /var/www/bottle-wifi-vendo/bottle-wifi-backend/storage/logs/laravel.log
```

---

## Step 13: DNS Configuration

Point your domain to server IP:

```
A Record:
your-domain.com -> YOUR_SERVER_IP

A Record:
www.your-domain.com -> YOUR_SERVER_IP
```

Wait for DNS propagation (up to 48 hours).

---

## Step 14: Post-Deployment

### 14.1 Monitor for 24 Hours

Check hourly for first 24 hours:
- Error rates in Sentry
- Server resource usage
- Database performance
- API response times
- User signups and submissions

### 14.2 Send Announcement

Inform users that app is live:
- Email announcement
- Social media posts
- In-app notifications

---

## Troubleshooting

### Application Errors

```bash
# Check Laravel logs
tail -f storage/logs/laravel.log

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Check PHP-FPM logs
sudo tail -f /var/log/php8.2-fpm.log
```

### Permission Issues

```bash
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### Database Connection Issues

```bash
# Test connection
php artisan tinker
DB::connection()->getPdo();
```

### Queue Not Processing

```bash
# Check supervisor status
sudo supervisorctl status

# Restart workers
sudo supervisorctl restart bottle-wifi-worker:*
```

---

## Rollback Plan

If deployment fails:

```bash
# Enable maintenance mode
php artisan down

# Restore database
gunzip < /var/backups/bottle-wifi/database_TIMESTAMP.sql.gz | mysql -u bottle_wifi_user -p bottle_wifi_production

# Restore files
tar -xzf /var/backups/bottle-wifi/storage_TIMESTAMP.tar.gz -C /var/www/bottle-wifi-vendo/bottle-wifi-backend

# Clear caches
php artisan cache:clear
php artisan config:clear

# Disable maintenance mode
php artisan up
```

---

## Security Hardening (Post-Deployment)

1. Configure firewall (UFW)
2. Set up fail2ban for SSH protection
3. Enable automatic security updates
4. Regular security audits
5. Implement intrusion detection

---

## Maintenance Schedule

**Daily:**
- Check error logs
- Monitor server resources
- Verify backups completed

**Weekly:**
- Review performance metrics
- Check for security updates
- Test backup restoration

**Monthly:**
- Security audit
- Performance optimization
- Update dependencies

---

## Support Contacts

- **Technical Issues**: tech@your-domain.com
- **Emergency**: +[phone number]
- **On-Call Engineer**: [name and contact]

---

**Deployment completed!** 🎉

Your Bottle WiFi Vendo application is now live in production.
