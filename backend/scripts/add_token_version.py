import sys
import os
 
# Add the backend directory to sys.path so we can import app modules
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.dirname(current_dir)
sys.path.append(backend_dir)

from sqlalchemy import text
from app.core.database import users_engine

def update_db():
    print("🔄 Connecting to Users Database...")
    try:
        with users_engine.connect() as connection:
            print("🚀 Adding 'token_version' column to 'users' table...")
            # Using text() for raw SQL execution
            connection.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS token_version INTEGER DEFAULT 1 NOT NULL;"))
            connection.commit()
            print("✅ Database updated successfully!")
    except Exception as e:
        print(f"❌ Error updating database: {e}")

if __name__ == "__main__":
    update_db()
