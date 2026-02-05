#!/usr/bin/env python3
"""
Demo script showing the Bottle WiFi Vendo system in action
"""

from app import BottleWiFiVendo
import random

def print_section(title):
    print("\n" + "=" * 70)
    print(f"  {title}")
    print("=" * 70)

def demo_complete_flow():
    """Demonstrate a complete user flow"""
    
    print("\n" + "🌍" * 35)
    print(" " * 15 + "BOTTLE WIFI VENDO DEMO")
    print(" " * 10 + "Eco-Friendly WiFi Access for Students")
    print("🌍" * 35 + "\n")
    
    # Initialize system
    vendo = BottleWiFiVendo("demo.db")
    
    # Scenario 1: New student joins
    print_section("📚 SCENARIO 1: Student Registration")
    print("\nSarah is a new student who just heard about the program...")
    
    success = vendo.register_student("STU2024001", "Sarah Johnson")
    if success:
        print("✅ Sarah successfully registered!")
        print("💡 She's ready to start collecting bottles!")
    
    # Scenario 2: First bottle collection
    print_section("♻️  SCENARIO 2: First Bottle Collection")
    print("\nSarah collected 8 bottles from her dormitory...")
    
    vendo.collect_bottles("STU2024001", 8)
    student = vendo.get_student_info("STU2024001")
    print(f"✅ Bottles recorded: {student['bottles_collected']}")
    print(f"💚 CO2 saved: {8 * 0.082:.3f} kg")
    print("🌱 Great start, Sarah!")
    
    # Scenario 3: Getting first voucher
    print_section("🎟️  SCENARIO 3: Redeeming First Voucher")
    print("\nSarah wants 24 hours of WiFi for her weekend study session...")
    print("Cost: 8 bottles")
    
    voucher = vendo.create_wifi_voucher("STU2024001", 24, 8)
    if voucher:
        print(f"\n✅ Voucher Created!")
        print(f"🔑 Code: {voucher['voucher_code']}")
        print(f"⏱️  Duration: {voucher['duration_hours']} hours")
        print(f"📅 Valid until: {voucher['expires_at'][:10]}")
    
    # Scenario 4: Multiple students join
    print_section("👥 SCENARIO 4: Growing Community")
    print("\nMore students are joining the eco-friendly movement...")
    
    students_data = [
        ("STU2024002", "Mike Chen", 15),
        ("STU2024003", "Emma Williams", 12),
        ("STU2024004", "David Kumar", 20),
    ]
    
    for student_id, name, bottles in students_data:
        vendo.register_student(student_id, name)
        vendo.collect_bottles(student_id, bottles)
        print(f"✅ {name}: {bottles} bottles collected")
    
    # Scenario 5: Student uses more vouchers
    print_section("🎯 SCENARIO 5: Active Users")
    print("\nMike wants WiFi for the whole week...")
    
    # Mike needs to collect more bottles
    current = vendo.get_student_info("STU2024002")
    print(f"Mike currently has: {current['bottles_collected']} bottles")
    print(f"He needs 50 bottles for 7 days WiFi")
    
    needed = 50 - current['bottles_collected']
    print(f"\nMike collected {needed} more bottles from the cafeteria...")
    vendo.collect_bottles("STU2024002", needed)
    
    voucher = vendo.create_wifi_voucher("STU2024002", 168, 50)
    print(f"\n✅ 7-day voucher created: {voucher['voucher_code']}")
    
    # Scenario 6: Environmental Impact
    print_section("🌍 SCENARIO 6: Collective Impact")
    
    # Sarah collects more
    vendo.collect_bottles("STU2024001", 10)
    # Emma gets a voucher
    vendo.create_wifi_voucher("STU2024003", 6, 5)
    # David collects more
    vendo.collect_bottles("STU2024004", 25)
    
    impact = vendo.get_environmental_impact()
    
    print("\nAfter just a few days, our community achieved:")
    print(f"♻️  Total bottles collected: {impact['total_bottles_collected']}")
    print(f"💨 CO2 prevented: {impact['co2_saved_kg']} kg")
    print(f"🌳 Tree equivalent: {impact['trees_equivalent']} trees (1 year)")
    
    # Scenario 7: Student statistics
    print_section("📊 SCENARIO 7: Top Contributors")
    
    all_students = []
    for sid in ["STU2024001", "STU2024002", "STU2024003", "STU2024004"]:
        info = vendo.get_student_info(sid)
        if info:
            all_students.append(info)
    
    # Sort by bottles collected (descending)
    all_students.sort(key=lambda x: x['bottles_collected'], reverse=True)
    
    print("\nLeaderboard - Most Eco-Friendly Students:")
    for i, student in enumerate(all_students[:3], 1):
        print(f"{i}. {student['name']}: {student['bottles_collected']} bottles available")
    
    # Final summary
    print_section("🎉 DEMO SUMMARY")
    print("""
This demo showed how the Bottle WiFi Vendo system:

✅ Registers students easily
✅ Tracks bottle collections accurately  
✅ Generates secure WiFi vouchers
✅ Calculates environmental impact in real-time
✅ Encourages eco-friendly behavior
✅ Creates a sustainable community

Key Features:
- Simple and intuitive for students
- Transparent environmental tracking
- Flexible pricing options
- Scalable for any campus size
- Zero external dependencies

Benefits:
🎓 Affordable WiFi for students
🌱 Reduced plastic waste
💚 Environmental awareness
🏆 Community engagement
    """)
    
    print("=" * 70)
    print(" " * 15 + "Thank you for watching!")
    print(" " * 10 + "Together we can make a difference! 🌍")
    print("=" * 70 + "\n")
    
    # Cleanup
    import os
    if os.path.exists("demo.db"):
        os.remove("demo.db")

if __name__ == "__main__":
    demo_complete_flow()
