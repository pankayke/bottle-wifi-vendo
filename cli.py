#!/usr/bin/env python3
"""
Command-line interface for Bottle WiFi Vendo system
Student-friendly interface for easy interaction
"""

import sys
from app import BottleWiFiVendo
from config import VOUCHER_PRICING, ECO_MESSAGES
import random


class CLI:
    """Command-line interface for the vending system"""
    
    def __init__(self):
        self.vendo = BottleWiFiVendo()
        self.current_student = None
    
    def clear_screen(self):
        """Clear the terminal screen"""
        print("\n" * 2)
    
    def print_header(self):
        """Print application header"""
        print("=" * 70)
        print(" " * 10 + "🌍 BOTTLE WIFI VENDO 🌍")
        print(" " * 5 + "Eco-Friendly WiFi Access for Students")
        print("=" * 70)
        print()
    
    def print_menu(self):
        """Print main menu"""
        print("\n" + "─" * 70)
        print("MAIN MENU")
        print("─" * 70)
        print("1. 📚 Register New Student")
        print("2. 🔑 Login as Student")
        print("3. ♻️  Collect Bottles")
        print("4. 🎟️  Get WiFi Voucher")
        print("5. 📊 Check My Balance")
        print("6. 🌍 View Environmental Impact")
        print("7. ℹ️  Help")
        print("8. 🚪 Exit")
        print("─" * 70)
    
    def register_student(self):
        """Register a new student"""
        print("\n" + "=" * 70)
        print("📚 STUDENT REGISTRATION")
        print("=" * 70)
        
        student_id = input("Enter Student ID: ").strip()
        if not student_id:
            print("❌ Student ID cannot be empty!")
            return
        
        name = input("Enter Full Name: ").strip()
        if not name:
            print("❌ Name cannot be empty!")
            return
        
        if self.vendo.register_student(student_id, name):
            print(f"\n✅ Welcome {name}!")
            print("🎉 Registration successful!")
            print(random.choice(ECO_MESSAGES))
            self.current_student = student_id
        else:
            print("❌ Student ID already exists!")
    
    def login(self):
        """Login as existing student"""
        print("\n" + "=" * 70)
        print("🔑 STUDENT LOGIN")
        print("=" * 70)
        
        student_id = input("Enter Student ID: ").strip()
        student = self.vendo.get_student_info(student_id)
        
        if student:
            print(f"\n✅ Welcome back, {student['name']}!")
            self.current_student = student_id
        else:
            print("❌ Student not found! Please register first.")
    
    def collect_bottles(self):
        """Record bottle collection"""
        if not self.current_student:
            print("❌ Please login first!")
            return
        
        print("\n" + "=" * 70)
        print("♻️  BOTTLE COLLECTION")
        print("=" * 70)
        
        try:
            count = int(input("How many bottles are you bringing? "))
            if count <= 0:
                print("❌ Please enter a positive number!")
                return
            
            self.vendo.collect_bottles(self.current_student, count)
            print(f"\n✅ {count} bottles recorded!")
            print(f"💚 You saved approximately {count * 0.082:.3f} kg of CO2!")
            print(random.choice(ECO_MESSAGES))
            
            # Show updated balance
            student = self.vendo.get_student_info(self.current_student)
            print(f"\n📦 Your bottle balance: {student['bottles_collected']} bottles")
            
        except ValueError:
            print("❌ Please enter a valid number!")
    
    def get_voucher(self):
        """Create a WiFi voucher"""
        if not self.current_student:
            print("❌ Please login first!")
            return
        
        print("\n" + "=" * 70)
        print("🎟️  WIFI VOUCHER OPTIONS")
        print("=" * 70)
        
        student = self.vendo.get_student_info(self.current_student)
        print(f"📦 Your bottle balance: {student['bottles_collected']} bottles\n")
        
        print("Available vouchers:")
        print("1. 🕐 1 Hour    - 1 bottle")
        print("2. 🕕 6 Hours   - 5 bottles  (Save 1 bottle!)")
        print("3. 📅 24 Hours  - 8 bottles  (Save 4 bottles!)")
        print("4. 📆 7 Days    - 50 bottles (Best value!)")
        print("5. ⬅️  Back")
        
        choice = input("\nSelect option (1-5): ").strip()
        
        voucher_map = {
            "1": (1, 1),
            "2": (6, 5),
            "3": (24, 8),
            "4": (168, 50),  # 7 days = 168 hours
        }
        
        if choice == "5":
            return
        
        if choice not in voucher_map:
            print("❌ Invalid choice!")
            return
        
        duration, bottles_required = voucher_map[choice]
        
        voucher = self.vendo.create_wifi_voucher(
            self.current_student,
            duration,
            bottles_required
        )
        
        if voucher:
            print("\n" + "=" * 70)
            print("✅ VOUCHER CREATED SUCCESSFULLY!")
            print("=" * 70)
            print(f"🎟️  Voucher Code: {voucher['voucher_code']}")
            print(f"⏱️  Duration: {duration} hours")
            print(f"📅 Valid Until: {voucher['expires_at'][:10]}")
            print(f"♻️  Bottles Used: {bottles_required}")
            print("=" * 70)
            print("\n💡 Tip: Save this voucher code to activate your WiFi!")
        else:
            print(f"\n❌ Insufficient bottles! You need {bottles_required} bottles.")
            print(f"📦 You currently have: {student['bottles_collected']} bottles")
            print("♻️  Collect more bottles to get this voucher!")
    
    def check_balance(self):
        """Check student balance and stats"""
        if not self.current_student:
            print("❌ Please login first!")
            return
        
        student = self.vendo.get_student_info(self.current_student)
        
        print("\n" + "=" * 70)
        print("📊 YOUR ACCOUNT")
        print("=" * 70)
        print(f"👤 Name: {student['name']}")
        print(f"🆔 Student ID: {student['student_id']}")
        print(f"📦 Bottles Available: {student['bottles_collected']}")
        print(f"🎟️  Total Vouchers Redeemed: {student['total_vouchers']}")
        print(f"📅 Member Since: {student['created_at'][:10]}")
        print("=" * 70)
        
        # Show what they can afford
        print("\n💡 With your current bottles, you can get:")
        if student['bottles_collected'] >= 50:
            print("   ✅ 7 Days WiFi (50 bottles)")
        if student['bottles_collected'] >= 8:
            print("   ✅ 24 Hours WiFi (8 bottles)")
        if student['bottles_collected'] >= 5:
            print("   ✅ 6 Hours WiFi (5 bottles)")
        if student['bottles_collected'] >= 1:
            print("   ✅ 1 Hour WiFi (1 bottle)")
        if student['bottles_collected'] < 1:
            print("   ♻️  Collect bottles to get WiFi vouchers!")
    
    def view_impact(self):
        """View environmental impact statistics"""
        impact = self.vendo.get_environmental_impact()
        
        print("\n" + "=" * 70)
        print("🌍 ENVIRONMENTAL IMPACT")
        print("=" * 70)
        print(f"♻️  Total Bottles Collected: {impact['total_bottles_collected']}")
        print(f"💨 CO2 Saved: {impact['co2_saved_kg']} kg")
        print(f"🌳 Tree Equivalent: {impact['trees_equivalent']} trees (1 year)")
        print("=" * 70)
        
        if impact['total_bottles_collected'] > 0:
            print("\n🎉 Amazing work! Every bottle makes a difference!")
            print("💚 Together we're making our planet cleaner!")
        else:
            print("\n💡 Start collecting bottles to see your impact!")
    
    def show_help(self):
        """Show help information"""
        print("\n" + "=" * 70)
        print("ℹ️  HELP & INFORMATION")
        print("=" * 70)
        print("""
HOW IT WORKS:
1. Register with your student ID
2. Collect plastic bottles and bring them to the collection point
3. Exchange bottles for WiFi access vouchers
4. Use the voucher code to activate your WiFi

PRICING:
- 1 Hour   = 1 bottle
- 6 Hours  = 5 bottles (save 1!)
- 24 Hours = 8 bottles (save 4!)
- 7 Days   = 50 bottles (best value!)

ENVIRONMENTAL FACTS:
- Each bottle saves 0.082 kg of CO2
- 12 bottles = equivalent to 1 tree's yearly CO2 absorption
- Plastic bottles can take 450 years to decompose

WHY RECYCLE?
♻️  Reduce plastic waste in oceans and landfills
🌱 Save energy and resources
💚 Protect wildlife and ecosystems
🌍 Fight climate change

Every bottle you recycle makes a real difference!
        """)
        print("=" * 70)
    
    def run(self):
        """Run the CLI application"""
        self.clear_screen()
        self.print_header()
        
        print("🌱 Welcome to the eco-friendly WiFi access system!")
        print("♻️  Recycle bottles, get WiFi, save the planet!\n")
        
        while True:
            self.print_menu()
            choice = input("\nEnter your choice (1-8): ").strip()
            
            if choice == "1":
                self.register_student()
            elif choice == "2":
                self.login()
            elif choice == "3":
                self.collect_bottles()
            elif choice == "4":
                self.get_voucher()
            elif choice == "5":
                self.check_balance()
            elif choice == "6":
                self.view_impact()
            elif choice == "7":
                self.show_help()
            elif choice == "8":
                print("\n🌍 Thank you for helping the environment!")
                print("💚 See you next time!")
                break
            else:
                print("❌ Invalid choice! Please select 1-8.")
            
            input("\nPress Enter to continue...")


if __name__ == "__main__":
    cli = CLI()
    try:
        cli.run()
    except KeyboardInterrupt:
        print("\n\n🌍 Thank you for helping the environment!")
        print("💚 See you next time!")
        sys.exit(0)
