"""
Unit tests for Bottle WiFi Vendo system
"""

import unittest
import os
from app import BottleWiFiVendo


class TestBottleWiFiVendo(unittest.TestCase):
    """Test cases for the WiFi vending system"""
    
    def setUp(self):
        """Set up test database"""
        self.test_db = "test_wifi_vendo.db"
        self.vendo = BottleWiFiVendo(self.test_db)
    
    def tearDown(self):
        """Clean up test database"""
        if os.path.exists(self.test_db):
            os.remove(self.test_db)
    
    def test_register_student(self):
        """Test student registration"""
        result = self.vendo.register_student("TEST001", "Test Student")
        self.assertTrue(result)
        
        # Try duplicate registration
        result = self.vendo.register_student("TEST001", "Test Student")
        self.assertFalse(result)
    
    def test_collect_bottles(self):
        """Test bottle collection"""
        self.vendo.register_student("TEST001", "Test Student")
        result = self.vendo.collect_bottles("TEST001", 10)
        self.assertTrue(result)
        
        student = self.vendo.get_student_info("TEST001")
        self.assertEqual(student['bottles_collected'], 10)
    
    def test_create_voucher_success(self):
        """Test successful voucher creation"""
        self.vendo.register_student("TEST001", "Test Student")
        self.vendo.collect_bottles("TEST001", 10)
        
        voucher = self.vendo.create_wifi_voucher("TEST001", 24, 5)
        self.assertIsNotNone(voucher)
        self.assertEqual(voucher['duration_hours'], 24)
        self.assertEqual(voucher['bottles_used'], 5)
        self.assertTrue(len(voucher['voucher_code']) > 0)
        
        # Check remaining bottles
        student = self.vendo.get_student_info("TEST001")
        self.assertEqual(student['bottles_collected'], 5)
    
    def test_create_voucher_insufficient_bottles(self):
        """Test voucher creation with insufficient bottles"""
        self.vendo.register_student("TEST001", "Test Student")
        self.vendo.collect_bottles("TEST001", 3)
        
        voucher = self.vendo.create_wifi_voucher("TEST001", 24, 5)
        self.assertIsNone(voucher)
    
    def test_activate_voucher(self):
        """Test voucher activation"""
        self.vendo.register_student("TEST001", "Test Student")
        self.vendo.collect_bottles("TEST001", 10)
        
        voucher = self.vendo.create_wifi_voucher("TEST001", 24, 5)
        result = self.vendo.activate_voucher(voucher['voucher_code'])
        self.assertTrue(result)
        
        # Try activating again (should fail)
        result = self.vendo.activate_voucher(voucher['voucher_code'])
        self.assertFalse(result)
    
    def test_environmental_impact(self):
        """Test environmental impact tracking"""
        self.vendo.register_student("TEST001", "Test Student")
        self.vendo.collect_bottles("TEST001", 10)
        
        impact = self.vendo.get_environmental_impact()
        self.assertEqual(impact['total_bottles_collected'], 10)
        self.assertAlmostEqual(impact['co2_saved_kg'], 0.82, places=2)
    
    def test_multiple_students(self):
        """Test system with multiple students"""
        self.vendo.register_student("TEST001", "Student One")
        self.vendo.register_student("TEST002", "Student Two")
        
        self.vendo.collect_bottles("TEST001", 5)
        self.vendo.collect_bottles("TEST002", 8)
        
        student1 = self.vendo.get_student_info("TEST001")
        student2 = self.vendo.get_student_info("TEST002")
        
        self.assertEqual(student1['bottles_collected'], 5)
        self.assertEqual(student2['bottles_collected'], 8)
        
        impact = self.vendo.get_environmental_impact()
        self.assertEqual(impact['total_bottles_collected'], 13)


def run_tests():
    """Run all tests"""
    print("=" * 70)
    print("Running Bottle WiFi Vendo Tests")
    print("=" * 70)
    print()
    
    unittest.main(argv=[''], verbosity=2, exit=False)
    
    print()
    print("=" * 70)
    print("✅ All tests completed!")
    print("=" * 70)


if __name__ == "__main__":
    run_tests()
