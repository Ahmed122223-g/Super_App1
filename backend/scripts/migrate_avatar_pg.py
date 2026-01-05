import sys
import os
from sqlalchemy import text

# Add backend directory to sys.path to allow imports from app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.database import users_engine

def migrate():
    print("Connecting to Users DB...")
    with users_engine.connect() as conn:
        print("Checking users table...")
        # Check if column exists
        result = conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='avatar'"))
        if result.first():
            print("✅ 'avatar' column already exists.")
        else:
            print("Adding 'avatar' column...")
            try:
                conn.execute(text("ALTER TABLE users ADD COLUMN avatar VARCHAR(255)"))
                conn.commit()
                print("✅ Column added successfully.")
            except Exception as e:
                print(f"❌ Error adding column: {e}")

if __name__ == "__main__":
    migrate()
