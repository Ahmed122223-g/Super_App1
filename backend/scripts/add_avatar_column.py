import sqlite3
import os

# Adjust path to your database
DB_PATH = "../data/users.db"

def add_avatar_column():
    if not os.path.exists(DB_PATH):
        print(f"Database {DB_PATH} not found. startup event will create it correctly.")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Check if column exists
    cursor.execute("PRAGMA table_info(users)")
    columns = [info[1] for info in cursor.fetchall()]
    
    if "avatar" not in columns:
        print("Adding 'avatar' column to 'users' table...")
        try:
            cursor.execute("ALTER TABLE users ADD COLUMN avatar VARCHAR(255)")
            conn.commit()
            print("✅ Column added successfully.")
        except Exception as e:
            print(f"❌ Error adding column: {e}")
    else:
        print("ℹ️ 'avatar' column already exists.")
        
    conn.close()

if __name__ == "__main__":
    add_avatar_column()
