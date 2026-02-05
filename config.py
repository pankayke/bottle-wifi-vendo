"""
Configuration file for Bottle WiFi Vendo system
"""

# Voucher pricing in bottles
VOUCHER_PRICING = {
    "1_hour": 1,      # 1 bottle for 1 hour
    "6_hours": 5,     # 5 bottles for 6 hours (savings!)
    "24_hours": 8,    # 8 bottles for 24 hours (best value!)
    "7_days": 50,     # 50 bottles for 7 days
}

# Environmental impact calculations
CO2_SAVED_PER_BOTTLE_KG = 0.082  # kg of CO2 saved per bottle recycled
CO2_PER_TREE_YEAR = 21.0  # kg of CO2 absorbed by one tree per year

# System settings
VOUCHER_CODE_LENGTH = 12
VOUCHER_EXPIRY_DAYS = 30
DATABASE_PATH = "wifi_vendo.db"

# Student settings
STUDENT_WELCOME_BOTTLES = 2  # Free bottles for new students

# Eco-friendly messages
ECO_MESSAGES = [
    "🌱 Thank you for helping the environment!",
    "♻️ Every bottle makes a difference!",
    "🌍 Together we can make the planet greener!",
    "💚 Eco-warriors unite!",
    "🌿 Small actions, big impact!",
]
