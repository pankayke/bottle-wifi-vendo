# System Architecture Diagram

## Bottle WiFi Vendo - System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    BOTTLE WIFI VENDO SYSTEM                     │
│                Eco-Friendly WiFi Access for Students            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        USER INTERFACES                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐         ┌──────────────────┐             │
│  │   CLI (cli.py)   │         │  Demo (demo.py)  │             │
│  │                  │         │                  │             │
│  │  • Registration  │         │  • Scenarios     │             │
│  │  • Login         │         │  • Testing       │             │
│  │  • Collect       │         │  • Presentation  │             │
│  │  • Redeem        │         │                  │             │
│  │  • Check Status  │         │                  │             │
│  └──────────────────┘         └──────────────────┘             │
│           │                            │                        │
└───────────┼────────────────────────────┼────────────────────────┘
            │                            │
            └──────────┬─────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                     CORE APPLICATION                             │
│                        (app.py)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              BottleWiFiVendo Class                       │  │
│  ├──────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  Student Management:                                     │  │
│  │    • register_student()                                  │  │
│  │    • get_student_info()                                  │  │
│  │                                                          │  │
│  │  Bottle Collection:                                      │  │
│  │    • collect_bottles()                                   │  │
│  │    • Update student balance                              │  │
│  │    • Track environmental impact                          │  │
│  │                                                          │  │
│  │  Voucher Management:                                     │  │
│  │    • create_wifi_voucher()                               │  │
│  │    • activate_voucher()                                  │  │
│  │    • generate_voucher_code()                             │  │
│  │                                                          │  │
│  │  Environmental Tracking:                                 │  │
│  │    • get_environmental_impact()                          │  │
│  │    • Calculate CO2 savings                               │  │
│  │    • Tree equivalents                                    │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                      │
└───────────────────────────┼──────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CONFIGURATION LAYER                           │
│                       (config.py)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  • Voucher Pricing (1h, 6h, 24h, 7d)                            │
│  • Environmental Constants (CO2, Tree calculations)             │
│  • System Settings (Code length, Expiry)                        │
│  • Eco Messages                                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     DATABASE LAYER                               │
│                  (SQLite - wifi_vendo.db)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────┐  ┌───────────────────┐                     │
│  │   students     │  │ bottle_collections│                     │
│  ├────────────────┤  ├───────────────────┤                     │
│  │ id (PK)        │  │ id (PK)           │                     │
│  │ student_id     │  │ student_id (FK)   │                     │
│  │ name           │  │ bottles_count     │                     │
│  │ bottles_coll.  │  │ collected_at      │                     │
│  │ total_vouchers │  └───────────────────┘                     │
│  │ created_at     │                                             │
│  └────────────────┘  ┌───────────────────┐                     │
│                      │  wifi_vouchers    │                     │
│  ┌────────────────┐  ├───────────────────┤                     │
│  │ environmental_ │  │ id (PK)           │                     │
│  │ impact         │  │ voucher_code      │                     │
│  ├────────────────┤  │ student_id (FK)   │                     │
│  │ id (PK)        │  │ duration_hours    │                     │
│  │ total_bottles  │  │ bottles_used      │                     │
│  │ co2_saved_kg   │  │ created_at        │                     │
│  │ last_updated   │  │ expires_at        │                     │
│  └────────────────┘  │ activated         │                     │
│                      │ activated_at      │                     │
│                      └───────────────────┘                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘


## Data Flow Example

Student Collects Bottles:
──────────────────────────

1. Student brings 10 bottles
2. CLI calls collect_bottles("STU001", 10)
3. App records in bottle_collections table
4. App updates student.bottles_collected += 10
5. App updates environmental_impact:
   - total_bottles_collected += 10
   - co2_saved_kg += 0.82
6. Returns success confirmation


Student Redeems Voucher:
─────────────────────────

1. Student chooses 24h WiFi (costs 8 bottles)
2. CLI calls create_wifi_voucher("STU001", 24, 8)
3. App checks if student has >= 8 bottles
4. App generates secure voucher code
5. App creates record in wifi_vouchers table
6. App deducts 8 from student.bottles_collected
7. App increments student.total_vouchers
8. Returns voucher details with code


## Test Coverage

┌─────────────────────────────────────────────────────┐
│            Unit Tests (test_app.py)                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ✓ test_register_student                           │
│  ✓ test_collect_bottles                            │
│  ✓ test_create_voucher_success                     │
│  ✓ test_create_voucher_insufficient_bottles        │
│  ✓ test_activate_voucher                           │
│  ✓ test_environmental_impact                       │
│  ✓ test_multiple_students                          │
│                                                     │
│  Result: 7/7 PASSED ✅                              │
│                                                     │
└─────────────────────────────────────────────────────┘


## Security Analysis

┌─────────────────────────────────────────────────────┐
│          CodeQL Security Scan                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  • SQL Injection: ✅ PASS (Parameterized queries)  │
│  • Code Injection: ✅ PASS (No eval/exec)          │
│  • Path Traversal: ✅ PASS (Safe file handling)    │
│  • Secrets: ✅ PASS (Secure random generation)     │
│  • Dependencies: ✅ PASS (Zero external deps)      │
│                                                     │
│  Result: 0 Vulnerabilities Found ✅                 │
│                                                     │
└─────────────────────────────────────────────────────┘


## Environmental Impact Formula

Bottles → CO2 Savings:
─────────────────────

CO2_saved = bottles_count × 0.082 kg

(Each plastic bottle recycled saves 0.082 kg of CO2
emissions compared to producing new plastic)


Trees Equivalent:
─────────────────

trees = CO2_saved ÷ 21 kg

(One tree absorbs approximately 21 kg of CO2 per year)


Example: 100 bottles collected
  → 8.2 kg CO2 saved
  → 0.39 trees equivalent (1 year)
```
