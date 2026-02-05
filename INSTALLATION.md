# 🔧 Installation & Deployment Guide

## System Requirements

- **Python**: 3.7 or higher
- **Operating System**: Linux, macOS, or Windows
- **Database**: SQLite (included with Python)
- **Dependencies**: None (uses only Python standard library)

## Installation Methods

### Method 1: Direct Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/pankayke/bottle-wifi-vendo.git
   cd bottle-wifi-vendo
   ```

2. **Verify Python version**
   ```bash
   python3 --version
   # Should be 3.7 or higher
   ```

3. **Run the system**
   ```bash
   # For demo/testing
   python3 app.py
   
   # For interactive CLI
   python3 cli.py
   ```

### Method 2: Virtual Environment (Recommended)

1. **Create virtual environment**
   ```bash
   python3 -m venv venv
   ```

2. **Activate virtual environment**
   ```bash
   # On Linux/macOS:
   source venv/bin/activate
   
   # On Windows:
   venv\Scripts\activate
   ```

3. **Run the application**
   ```bash
   python3 app.py
   ```

## Configuration

### Basic Configuration
Edit `config.py` to customize:

```python
# Voucher pricing in bottles
VOUCHER_PRICING = {
    "1_hour": 1,
    "6_hours": 5,
    "24_hours": 8,
    "7_days": 50,
}

# Environmental calculations
CO2_SAVED_PER_BOTTLE_KG = 0.082

# System settings
VOUCHER_CODE_LENGTH = 12
VOUCHER_EXPIRY_DAYS = 30
DATABASE_PATH = "wifi_vendo.db"
```

### Database Location
By default, the database is created in the current directory. To change:

```python
from app import BottleWiFiVendo

# Custom database path
vendo = BottleWiFiVendo("/path/to/your/database.db")
```

## Testing

### Run Unit Tests
```bash
python3 test_app.py
```

Expected output:
```
Running Bottle WiFi Vendo Tests
test_activate_voucher ... ok
test_collect_bottles ... ok
test_create_voucher_insufficient_bottles ... ok
test_create_voucher_success ... ok
test_environmental_impact ... ok
test_multiple_students ... ok
test_register_student ... ok

Ran 7 tests - OK
```

## Deployment Scenarios

### 1. Single Computer Kiosk

Perfect for a bottle collection station:

```bash
# Run CLI in fullscreen mode
python3 cli.py
```

**Hardware suggestions:**
- Touchscreen monitor
- Physical bottle counter/scanner (optional)
- Receipt printer for voucher codes (optional)

### 2. Web Server Deployment

For network-wide access, you can integrate with a web framework:

```python
# Example with Flask (requires: pip install flask)
from flask import Flask, request, jsonify
from app import BottleWiFiVendo

app = Flask(__name__)
vendo = BottleWiFiVendo()

@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    result = vendo.register_student(data['student_id'], data['name'])
    return jsonify({'success': result})

@app.route('/api/collect', methods=['POST'])
def collect():
    data = request.json
    result = vendo.collect_bottles(data['student_id'], data['bottles'])
    return jsonify({'success': result})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### 3. Automated Bottle Counter Integration

For IoT bottle counting devices:

```python
from app import BottleWiFiVendo
import serial  # pip install pyserial

vendo = BottleWiFiVendo()

# Read from bottle counter device
ser = serial.Serial('/dev/ttyUSB0', 9600)

while True:
    data = ser.readline().decode().strip()
    if data.startswith('STUDENT:'):
        parts = data.split(',')
        student_id = parts[0].split(':')[1]
        bottle_count = int(parts[1].split(':')[1])
        vendo.collect_bottles(student_id, bottle_count)
```

## Security Considerations

### 1. Database Protection
```bash
# Set appropriate permissions
chmod 600 wifi_vendo.db
```

### 2. Student ID Validation
Add validation in production:

```python
import re

def validate_student_id(student_id):
    # Example: Must be alphanumeric, 5-10 characters
    return bool(re.match(r'^[A-Z0-9]{5,10}$', student_id))
```

### 3. Rate Limiting
Prevent abuse by adding rate limits:

```python
from datetime import datetime, timedelta

last_collection = {}

def can_collect(student_id):
    now = datetime.now()
    if student_id in last_collection:
        if now - last_collection[student_id] < timedelta(hours=1):
            return False
    last_collection[student_id] = now
    return True
```

## Maintenance

### Database Backup
```bash
# Create backup
cp wifi_vendo.db wifi_vendo_backup_$(date +%Y%m%d).db

# Scheduled backup (cron)
0 2 * * * cp /path/to/wifi_vendo.db /backup/wifi_vendo_$(date +\%Y\%m\%d).db
```

### Database Cleanup
```python
# Remove expired vouchers (optional)
import sqlite3

conn = sqlite3.connect('wifi_vendo.db')
cursor = conn.cursor()
cursor.execute("""
    DELETE FROM wifi_vouchers 
    WHERE datetime(expires_at) < datetime('now')
    AND activated = FALSE
""")
conn.commit()
conn.close()
```

### Log Management
Add logging for production:

```python
import logging

logging.basicConfig(
    filename='wifi_vendo.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# In your code
logging.info(f"Student {student_id} collected {count} bottles")
logging.warning(f"Failed voucher creation for {student_id}")
```

## Troubleshooting

### Issue: Database locked
**Solution**: Ensure only one process accesses the database at a time, or use WAL mode:

```python
conn = sqlite3.connect('wifi_vendo.db')
conn.execute('PRAGMA journal_mode=WAL')
```

### Issue: Permission denied
**Solution**: Check file permissions:
```bash
chmod 755 app.py cli.py
```

### Issue: Python version too old
**Solution**: Use Python 3.7+:
```bash
python3.9 app.py  # Use specific version
```

## Performance Optimization

### For Large Deployments

1. **Index frequently queried fields**
   ```sql
   CREATE INDEX idx_student_id ON wifi_vouchers(student_id);
   CREATE INDEX idx_voucher_code ON wifi_vouchers(voucher_code);
   ```

2. **Use connection pooling** (for web deployments)

3. **Cache environmental impact** (update periodically instead of every collection)

## Integration Examples

### WiFi Router Integration (Mikrotik Example)
```python
# Generate hotspot user
def create_hotspot_user(voucher_code, duration_hours):
    import subprocess
    subprocess.run([
        'ssh', 'admin@router',
        f'/ip/hotspot/user/add name={voucher_code} limit-uptime={duration_hours}h'
    ])
```

### SMS Notification Integration
```python
# Send voucher via SMS (using Twilio)
from twilio.rest import Client

def send_voucher_sms(phone, voucher_code):
    client = Client(account_sid, auth_token)
    message = client.messages.create(
        body=f"Your WiFi code: {voucher_code}",
        from_='+1234567890',
        to=phone
    )
```

## Monitoring

### Basic Health Check
```python
# check_health.py
from app import BottleWiFiVendo

try:
    vendo = BottleWiFiVendo()
    impact = vendo.get_environmental_impact()
    print(f"✅ System healthy - {impact['total_bottles_collected']} bottles")
except Exception as e:
    print(f"❌ System error: {e}")
    exit(1)
```

Run periodically:
```bash
*/5 * * * * /usr/bin/python3 /path/to/check_health.py
```

## Support & Updates

- Check GitHub for updates: https://github.com/pankayke/bottle-wifi-vendo
- Report issues on GitHub Issues
- Contribute improvements via Pull Requests

## License

Open source for educational purposes. Feel free to adapt for your institution!
