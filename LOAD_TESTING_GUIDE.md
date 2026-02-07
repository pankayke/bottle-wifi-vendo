# Load Testing Guide

Complete guide for load testing the Bottle WiFi Vendo API before production deployment.

---

## Overview

Load testing ensures your application can handle the expected user load and identifies performance bottlenecks before going live.

**Target**: 1000 concurrent users  
**Tools**: k6 (recommended) or Apache Bench  
**Duration**: 15-30 minutes per test

---

## Installation

### Option 1: k6 (Recommended)

**Windows:**
```powershell
choco install k6
# Or download from: https://k6.io/docs/getting-started/installation/
```

**macOS:**
```bash
brew install k6
```

**Linux:**
```bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### Option 2: Apache Bench (ab)

Included with Apache HTTP Server or install separately:

**Windows:**
```powershell
# Included with XAMPP or download Apache binaries
```

**macOS/Linux:**
```bash
sudo apt-get install apache2-utils  # Ubuntu/Debian
brew install httpd  # macOS
```

---

## Test Scenarios

### 1. Authentication Load Test

**File**: `load-tests/auth-test.js`

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },  // Ramp up to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 500 },  // Ramp up to 500 users
    { duration: '5m', target: 500 },  // Stay at 500 users
    { duration: '2m', target: 1000 }, // Ramp up to 1000 users
    { duration: '5m', target: 1000 }, // Stay at 1000 users
    { duration: '2m', target: 0 },    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.01'],   // Error rate should be less than 1%
  },
};

const BASE_URL = 'https://your-api-domain.com/api';

export default function() {
  // Login request
  const loginPayload = JSON.stringify({
    username: `testuser${__VU}`,  // __VU is virtual user number
    password: 'TestPassword123!',
  });

  const loginParams = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const loginRes = http.post(`${BASE_URL}/login`, loginPayload, loginParams);

  check(loginRes, {
    'login status is 200': (r) => r.status === 200,
    'login response time < 500ms': (r) => r.timings.duration < 500,
    'has token': (r) => r.json('token') !== undefined,
  });

  sleep(1); // Think time between requests
}
```

**Run the test:**
```bash
k6 run load-tests/auth-test.js
```

### 2. API Endpoint Load Test

**File**: `load-tests/api-test.js`

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 500 },
    { duration: '3m', target: 1000 },
    { duration: '5m', target: 1000 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = 'https://your-api-domain.com/api';
const TOKEN = 'YOUR_TEST_AUTH_TOKEN'; // Generate a test token

export default function() {
  const params = {
    headers: {
      'Authorization': `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
    },
  };

  // Test multiple endpoints
  const endpoints = [
    '/bottles',
    '/credits',
    '/machines',
    '/user/profile',
  ];

  endpoints.forEach((endpoint) => {
    const res = http.get(`${BASE_URL}${endpoint}`, params);
    
    check(res, {
      [`${endpoint} status is 200`]: (r) => r.status === 200,
      [`${endpoint} response time < 500ms`]: (r) => r.timings.duration < 500,
    });

    sleep(0.5);
  });

  sleep(1);
}
```

### 3. Bottle Submission Load Test

**File**: `load-tests/bottle-submission-test.js`

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export let options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '3m', target: 200 },
    { duration: '2m', target: 500 },
    { duration: '3m', target: 500 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // Submission can take a bit longer
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = 'https://your-api-domain.com/api';
const TOKEN = 'YOUR_TEST_AUTH_TOKEN';

export default function() {
  const submitPayload = JSON.stringify({
    machine_id: randomIntBetween(1, 10),
    qr_code: `BOTTLE${__VU}${Date.now()}`,
    weight: randomIntBetween(10, 500),
  });

  const params = {
    headers: {
      'Authorization': `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
    },
  };

  const res = http.post(`${BASE_URL}/bottles/submit`, submitPayload, params);

  check(res, {
    'bottle submission status is 200 or 201': (r) => r.status === 200 || r.status === 201,
    'submission response time < 1000ms': (r) => r.timings.duration < 1000,
    'credits awarded': (r) => r.json('credits_awarded') !== undefined,
  });

  sleep(2); // Users don't submit bottles immediately
}
```

### 4. Database Read Heavy Test

**File**: `load-tests/read-heavy-test.js`

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 200 },
    { duration: '3m', target: 1000 },
    { duration: '5m', target: 1000 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<300'], // Reads should be faster
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = 'https://your-api-domain.com/api';
const TOKEN = 'YOUR_TEST_AUTH_TOKEN';

export default function() {
  const params = {
    headers: {
      'Authorization': `Bearer ${TOKEN}`,
    },
  };

  // Simulate user browsing through pages
  const requests = [
    http.get(`${BASE_URL}/bottles?page=1`, params),
    http.get(`${BASE_URL}/machines`, params),
    http.get(`${BASE_URL}/credits/balance`, params),
    http.get(`${BASE_URL}/user/statistics`, params),
  ];

  requests.forEach((res) => {
    check(res, {
      'read status is 200': (r) => r.status === 200,
      'read response time < 300ms': (r) => r.timings.duration < 300,
    });
  });

  sleep(1);
}
```

---

## Running Load Tests

### Step 1: Prepare Test Data

```bash
# Create test users and data
cd bottle-wifi-backend
php artisan test:prepare-load-test
```

### Step 2: Run Individual Tests

```bash
# Authentication test
k6 run load-tests/auth-test.js

# API endpoints test
k6 run load-tests/api-test.js

# Bottle submission test
k6 run load-tests/bottle-submission-test.js

# Read-heavy test
k6 run load-tests/read-heavy-test.js
```

### Step 3: Run Full Suite

```bash
# Run all tests sequentially with results logging
k6 run load-tests/auth-test.js --out json=results/auth-results.json
k6 run load-tests/api-test.js --out json=results/api-results.json
k6 run load-tests/bottle-submission-test.js --out json=results/submit-results.json
k6 run load-tests/read-heavy-test.js --out json=results/read-results.json
```

---

## Alternative: Apache Bench (Quick Tests)

### Simple Load Test

```bash
# 1000 requests, 100 concurrent users
ab -n 1000 -c 100 https://your-api-domain.com/health

# With authentication
ab -n 1000 -c 100 -H "Authorization: Bearer YOUR_TOKEN" https://your-api-domain.com/api/bottles

# POST request
ab -n 500 -c 50 -p post-data.json -T application/json https://your-api-domain.com/api/login
```

### Sample POST data file (post-data.json)

```json
{
  "username": "testuser",
  "password": "TestPassword123!"
}
```

---

## Monitoring During Load Tests

### 1. Server Monitoring

**Check server resources:**

```bash
# CPU, Memory, Disk usage
htop

# Or install monitoring tools
sudo apt-get install sysstat
iostat -x 1  # Disk I/O
vmstat 1     # Memory and CPU
```

### 2. Database Monitoring

```bash
# MySQL/MariaDB
mysql -u root -p -e "SHOW FULL PROCESSLIST;"
mysql -u root -p -e "SHOW ENGINE INNODB STATUS\G"

# Monitor slow queries
tail -f /var/log/mysql/slow-query.log
```

### 3. Application Monitoring

```bash
# Laravel logs
tail -f bottle-wifi-backend/storage/logs/laravel.log

# Performance logs
tail -f bottle-wifi-backend/storage/logs/performance.log

# Query logs
tail -f bottle-wifi-backend/storage/logs/query.log
```

### 4. Web Server Monitoring

```bash
# Nginx access logs
tail -f /var/log/nginx/access.log

# Nginx error logs
tail -f /var/log/nginx/error.log

# Apache access logs
tail -f /var/log/apache2/access.log
```

---

## Analyzing Results

### k6 Results

k6 provides comprehensive output including:

- **Request Rate**: Requests per second
- **Response Time**: Average, median, p95, p99
- **Error Rate**: Percentage of failed requests
- **Throughput**: Data transferred

**Sample output:**
```
✓ login status is 200
✓ login response time < 500ms

checks.........................: 100.00% ✓ 50000 ✗ 0
data_received..................: 15 MB   250 kB/s
data_sent......................: 10 MB   167 kB/s
http_req_blocked...............: avg=1.2ms   min=1µs     med=3µs     max=150ms  p(95)=5ms
http_req_duration..............: avg=250ms   min=100ms   med=200ms   max=2s     p(95)=450ms
http_req_failed................: 0.00%   ✓ 0     ✗ 50000
http_reqs......................: 50000   833/s
iteration_duration.............: avg=1.2s    min=1s      med=1.1s    max=3s
iterations.....................: 50000   833/s
vus............................: 1000    min=0   max=1000
vus_max........................: 1000    min=1000 max=1000
```

### Performance Targets

| Metric | Target | Acceptable | Critical |
|--------|--------|------------|----------|
| Response Time (p95) | < 300ms | < 500ms | < 1000ms |
| Response Time (p99) | < 500ms | < 1000ms | < 2000ms |
| Error Rate | < 0.1% | < 1% | < 5% |
| Throughput | > 500 req/s | > 200 req/s | > 100 req/s |
| CPU Usage | < 70% | < 85% | < 95% |
| Memory Usage | < 70% | < 85% | < 95% |

---

## Optimization Tips

### If Performance is Poor

1. **Database Optimization**
   - Add indexes to frequently queried columns
   - Optimize slow queries
   - Enable query caching
   - Consider read replicas

2. **Caching**
   - Implement Redis caching
   - Cache frequently accessed data
   - Use CDN for static assets

3. **Application Optimization**
   - Optimize N+1 queries
   - Implement pagination
   - Enable response compression
   - Use queue for heavy tasks

4. **Server Resources**
   - Increase server CPU/RAM
   - Use load balancer
   - Scale horizontally

---

## Load Test Checklist

- [ ] Test environment set up
- [ ] Test data prepared
- [ ] Monitoring tools configured
- [ ] Authentication load test passed
- [ ] API endpoints load test passed
- [ ] Bottle submission load test passed
- [ ] Read-heavy operations test passed
- [ ] 100 concurrent users tested
- [ ] 500 concurrent users tested
- [ ] 1000 concurrent users tested
- [ ] Response times within acceptable range
- [ ] Error rate < 1%
- [ ] Server resources adequate
- [ ] Database performance acceptable
- [ ] Bottlenecks identified and documented
- [ ] Optimizations implemented
- [ ] Retest after optimizations
- [ ] Results documented
- [ ] Team informed of results

---

## Troubleshooting

### High Response Times

- Check database query performance
- Review application logs for slow operations
- Verify network latency
- Check for resource constraints

### High Error Rates

- Review error logs
- Check for database connection issues
- Verify authentication token validity
- Check for rate limiting

### Server Resource Issues

- Add horizontal scaling (more servers)
- Upgrade server resources
- Optimize application code
- Implement caching

---

## Post-Test Actions

1. **Document Results**
   - Save all test outputs
   - Screenshot key metrics
   - Note any issues encountered

2. **Optimize**
   - Fix identified bottlenecks
   - Implement caching strategies
   - Optimize database queries

3. **Retest**
   - Run tests again after optimizations
   - Verify improvements
   - Document final results

4. **Sign Off**
   - Get stakeholder approval
   - Update deployment checklist
   - Proceed with production deployment

---

## Additional Resources

- k6 Documentation: https://k6.io/docs/
- Apache Bench Guide: https://httpd.apache.org/docs/2.4/programs/ab.html
- Laravel Performance: https://laravel.com/docs/performance
- Database Optimization: https://dev.mysql.com/doc/refman/8.0/en/optimization.html
