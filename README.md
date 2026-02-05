# 🌍 Bottle WiFi Vendo - Eco-Friendly WiFi Access for Students

An innovative WiFi vending system that promotes environmental sustainability by rewarding students with WiFi access vouchers for recycling plastic bottles.

## 🎯 Purpose

This project combines two important goals:
1. **Provide affordable WiFi access** to students
2. **Promote environmental sustainability** through bottle recycling

Students can collect plastic bottles and exchange them for WiFi access vouchers, creating a win-win situation for both education and the environment.

## ♻️ How It Works

1. **Collect Bottles**: Students bring plastic bottles to the collection point
2. **Earn Credits**: Each bottle is recorded in their account
3. **Redeem WiFi**: Exchange bottles for WiFi access vouchers
4. **Track Impact**: See your environmental contribution in real-time

### Pricing (in bottles)
- 1 hour WiFi = 1 bottle
- 6 hours WiFi = 5 bottles (save 1 bottle!)
- 24 hours WiFi = 8 bottles (save 4 bottles!)
- 7 days WiFi = 50 bottles (best value!)

## 🌱 Environmental Impact

Every bottle recycled makes a difference:
- **0.082 kg CO2** saved per bottle
- Approximately **12 bottles** = equivalent to one tree's yearly CO2 absorption
- Real-time tracking of collective environmental impact

## 🚀 Quick Start

### Prerequisites
- Python 3.7 or higher
- No external dependencies required!

### Installation

1. Clone the repository:
```bash
git clone https://github.com/pankayke/bottle-wifi-vendo.git
cd bottle-wifi-vendo
```

2. Run the application:
```bash
python3 app.py
```

## 📖 Usage Examples

### Register a Student
```python
from app import BottleWiFiVendo

vendo = BottleWiFiVendo()
vendo.register_student("STU001", "John Doe")
```

### Record Bottle Collection
```python
# Student brought 10 bottles
vendo.collect_bottles("STU001", 10)
```

### Create WiFi Voucher
```python
# Exchange 5 bottles for 6 hours of WiFi
voucher = vendo.create_wifi_voucher("STU001", duration_hours=6, bottles_required=5)
print(f"Your voucher code: {voucher['voucher_code']}")
```

### Check Student Balance
```python
student = vendo.get_student_info("STU001")
print(f"Bottles available: {student['bottles_collected']}")
```

### View Environmental Impact
```python
impact = vendo.get_environmental_impact()
print(f"Total CO2 saved: {impact['co2_saved_kg']} kg")
```

## 🏗️ Database Schema

The system uses SQLite with four main tables:

### Students
- Tracks registered students and their bottle balance
- Records total vouchers redeemed

### Bottle Collections
- Logs every bottle collection transaction
- Maintains history for auditing

### WiFi Vouchers
- Stores generated voucher codes
- Tracks activation status and expiration

### Environmental Impact
- Aggregates total environmental contribution
- Calculates CO2 savings

## 🎓 Features for Students

- **Simple Registration**: Quick student ID and name
- **Balance Tracking**: Always know how many bottles you have
- **Flexible Options**: Choose WiFi duration based on your needs
- **History**: View your voucher redemption history
- **Impact Dashboard**: See your personal environmental contribution

## 🌿 Eco-Friendly Features

- Real-time CO2 savings calculation
- Tree equivalency metrics
- Collective impact visualization
- Encouragement messages for recycling
- Transparent environmental reporting

## 🔧 Configuration

Edit `config.py` to customize:
- Voucher pricing
- Expiration periods
- Welcome bonuses
- Environmental calculations
- System messages

## 📊 Example Output

```
============================================================
Bottle WiFi Vendo - Eco-Friendly WiFi Access for Students
============================================================

📚 Registering student...
♻️  Student collected 10 bottles...
🎟️  Creating WiFi voucher (costs 5 bottles)...

✅ Voucher Created Successfully!
   Code: A3X9K2M8P1Q7
   Duration: 24 hours
   Expires: 2026-03-07
   Bottles Used: 5

============================================================
📊 Student Information
============================================================
Name: John Doe
ID: STU001
Bottles Collected: 5
Total Vouchers: 1

============================================================
🌍 Environmental Impact
============================================================
Total Bottles Collected: 10
CO2 Saved: 0.82 kg
Equivalent to 0.04 trees for a year
============================================================
```

## 💡 Benefits

### For Students
- Free/affordable WiFi access
- Learn about environmental responsibility
- Convenient and gamified recycling
- Community contribution visibility

### For Environment
- Reduces plastic waste
- Promotes recycling culture
- Measurable environmental impact
- Encourages sustainable habits

### For Institutions
- Engages students in sustainability
- Easy to implement and maintain
- No external dependencies
- Scalable solution

## 🤝 Contributing

Contributions are welcome! Some ideas for enhancements:
- Web interface for better user experience
- Mobile app integration
- QR code voucher system
- Leaderboards for top recyclers
- Integration with campus WiFi systems
- Bottle collection kiosks with sensors

## 📝 License

This project is open source and available for educational purposes.

## 🌟 Impact Goals

Our vision is to:
- Remove 10,000+ bottles from the environment annually
- Provide affordable internet access to 1,000+ students
- Save 820+ kg of CO2 emissions per year
- Create a model for other institutions worldwide

---

**Together, we can make education accessible and our planet cleaner! 🌍💚**
