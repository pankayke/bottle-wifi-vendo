#!/usr/bin/env python3
"""
Bottle WiFi Vendo - Eco-Friendly WiFi Access System for Students

This application provides WiFi access vouchers to students while promoting
environmental sustainability through bottle recycling incentives.
"""

import sqlite3
import secrets
import string
from datetime import datetime, timedelta
from typing import Dict, List, Optional


class BottleWiFiVendo:
    """Main class for the Bottle WiFi Vending System"""
    
    def __init__(self, db_path: str = "wifi_vendo.db"):
        """Initialize the WiFi vending system"""
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize the database schema"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Students table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS students (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id TEXT UNIQUE NOT NULL,
                name TEXT NOT NULL,
                bottles_collected INTEGER DEFAULT 0,
                total_vouchers INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Bottle collections table (for eco-friendly tracking)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS bottle_collections (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                student_id TEXT NOT NULL,
                bottles_count INTEGER NOT NULL,
                collected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (student_id) REFERENCES students(student_id)
            )
        """)
        
        # WiFi vouchers table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS wifi_vouchers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                voucher_code TEXT UNIQUE NOT NULL,
                student_id TEXT NOT NULL,
                duration_hours INTEGER NOT NULL,
                bottles_used INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP NOT NULL,
                activated BOOLEAN DEFAULT FALSE,
                activated_at TIMESTAMP,
                FOREIGN KEY (student_id) REFERENCES students(student_id)
            )
        """)
        
        # Environmental impact tracking
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS environmental_impact (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                total_bottles_collected INTEGER DEFAULT 0,
                co2_saved_kg REAL DEFAULT 0,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        conn.commit()
        conn.close()
    
    def register_student(self, student_id: str, name: str) -> bool:
        """Register a new student in the system"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute(
                "INSERT INTO students (student_id, name) VALUES (?, ?)",
                (student_id, name)
            )
            conn.commit()
            conn.close()
            return True
        except sqlite3.IntegrityError:
            return False
    
    def collect_bottles(self, student_id: str, bottles_count: int) -> bool:
        """Record bottle collection for a student (eco-friendly action)"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Record the collection
        cursor.execute(
            "INSERT INTO bottle_collections (student_id, bottles_count) VALUES (?, ?)",
            (student_id, bottles_count)
        )
        
        # Update student's total
        cursor.execute(
            "UPDATE students SET bottles_collected = bottles_collected + ? WHERE student_id = ?",
            (bottles_count, student_id)
        )
        
        # Update environmental impact (0.082 kg CO2 saved per bottle recycled)
        co2_saved = bottles_count * 0.082
        
        # Check if environmental_impact record exists
        cursor.execute("SELECT id FROM environmental_impact LIMIT 1")
        exists = cursor.fetchone()
        
        if exists:
            cursor.execute(
                """
                UPDATE environmental_impact SET
                    total_bottles_collected = total_bottles_collected + ?,
                    co2_saved_kg = co2_saved_kg + ?,
                    last_updated = CURRENT_TIMESTAMP
                WHERE id = 1
                """,
                (bottles_count, co2_saved)
            )
        else:
            cursor.execute(
                """
                INSERT INTO environmental_impact (id, total_bottles_collected, co2_saved_kg)
                VALUES (1, ?, ?)
                """,
                (bottles_count, co2_saved)
            )
        
        conn.commit()
        conn.close()
        return True
    
    def generate_voucher_code(self, length: int = 12) -> str:
        """Generate a random voucher code"""
        characters = string.ascii_uppercase + string.digits
        return ''.join(secrets.choice(characters) for _ in range(length))
    
    def create_wifi_voucher(self, student_id: str, duration_hours: int, bottles_required: int) -> Optional[Dict]:
        """
        Create a WiFi voucher for a student using their collected bottles
        
        Args:
            student_id: Student ID
            duration_hours: WiFi access duration in hours
            bottles_required: Number of bottles needed for this voucher
        
        Returns:
            Dictionary with voucher details or None if insufficient bottles
        """
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Check student's bottle balance
        cursor.execute(
            "SELECT bottles_collected FROM students WHERE student_id = ?",
            (student_id,)
        )
        result = cursor.fetchone()
        
        if not result or result[0] < bottles_required:
            conn.close()
            return None
        
        # Generate voucher
        voucher_code = self.generate_voucher_code()
        expires_at = datetime.now() + timedelta(days=30)
        
        cursor.execute(
            """
            INSERT INTO wifi_vouchers 
            (voucher_code, student_id, duration_hours, bottles_used, expires_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            (voucher_code, student_id, duration_hours, bottles_required, expires_at)
        )
        
        # Deduct bottles from student's balance
        cursor.execute(
            "UPDATE students SET bottles_collected = bottles_collected - ?, total_vouchers = total_vouchers + 1 WHERE student_id = ?",
            (bottles_required, student_id)
        )
        
        conn.commit()
        conn.close()
        
        return {
            "voucher_code": voucher_code,
            "duration_hours": duration_hours,
            "bottles_used": bottles_required,
            "expires_at": expires_at.isoformat()
        }
    
    def activate_voucher(self, voucher_code: str) -> bool:
        """Activate a WiFi voucher"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            """
            UPDATE wifi_vouchers 
            SET activated = TRUE, activated_at = CURRENT_TIMESTAMP
            WHERE voucher_code = ? AND activated = FALSE 
            AND datetime(expires_at) > datetime('now')
            """,
            (voucher_code,)
        )
        
        success = cursor.rowcount > 0
        conn.commit()
        conn.close()
        return success
    
    def get_student_info(self, student_id: str) -> Optional[Dict]:
        """Get student information and statistics"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            "SELECT * FROM students WHERE student_id = ?",
            (student_id,)
        )
        result = cursor.fetchone()
        conn.close()
        
        if not result:
            return None
        
        return {
            "student_id": result[1],
            "name": result[2],
            "bottles_collected": result[3],
            "total_vouchers": result[4],
            "created_at": result[5]
        }
    
    def get_environmental_impact(self) -> Dict:
        """Get overall environmental impact statistics"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("SELECT total_bottles_collected, co2_saved_kg FROM environmental_impact")
        result = cursor.fetchone()
        conn.close()
        
        if not result:
            return {"total_bottles_collected": 0, "co2_saved_kg": 0.0}
        
        return {
            "total_bottles_collected": result[0],
            "co2_saved_kg": round(result[1], 2),
            "trees_equivalent": round(result[1] / 21, 2)  # 1 tree absorbs ~21kg CO2/year
        }


def main():
    """Main function to demonstrate the system"""
    print("=" * 60)
    print("Bottle WiFi Vendo - Eco-Friendly WiFi Access for Students")
    print("=" * 60)
    print()
    
    vendo = BottleWiFiVendo()
    
    # Example usage
    print("📚 Registering student...")
    vendo.register_student("STU001", "John Doe")
    
    print("♻️  Student collected 10 bottles...")
    vendo.collect_bottles("STU001", 10)
    
    print("🎟️  Creating WiFi voucher (costs 5 bottles)...")
    voucher = vendo.create_wifi_voucher("STU001", duration_hours=24, bottles_required=5)
    
    if voucher:
        print(f"\n✅ Voucher Created Successfully!")
        print(f"   Code: {voucher['voucher_code']}")
        print(f"   Duration: {voucher['duration_hours']} hours")
        print(f"   Expires: {voucher['expires_at']}")
        print(f"   Bottles Used: {voucher['bottles_used']}")
    
    print("\n" + "=" * 60)
    print("📊 Student Information")
    print("=" * 60)
    student = vendo.get_student_info("STU001")
    if student:
        print(f"Name: {student['name']}")
        print(f"ID: {student['student_id']}")
        print(f"Bottles Collected: {student['bottles_collected']}")
        print(f"Total Vouchers: {student['total_vouchers']}")
    
    print("\n" + "=" * 60)
    print("🌍 Environmental Impact")
    print("=" * 60)
    impact = vendo.get_environmental_impact()
    print(f"Total Bottles Collected: {impact['total_bottles_collected']}")
    print(f"CO2 Saved: {impact['co2_saved_kg']} kg")
    print(f"Equivalent to {impact['trees_equivalent']} trees for a year")
    print("=" * 60)


if __name__ == "__main__":
    main()
