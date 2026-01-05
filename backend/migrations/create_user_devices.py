"""
Database Migration: Create user_devices table for multi-device FCM support
Run this script to add the new table to the users database.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import users_engine
from app.models.user import UserDevice

def run_migration():
    """Create user_devices table if it doesn't exist"""
    try:
        # Create the table
        UserDevice.__table__.create(users_engine, checkfirst=True)
        print("✅ user_devices table created successfully!")
        return True
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        return False

if __name__ == "__main__":
    run_migration()
