from sqlalchemy import text, inspect
from app.core.database import SessionLocal, users_engine

def migrate_addresses():
    db = SessionLocal()
    try:
        print("Starting migration check...")
        
        inspector = inspect(users_engine)
        columns = [c['name'] for c in inspector.get_columns('addresses')]
        print(f"Current columns in 'addresses': {columns}")
        
        if 'contact_name' not in columns:
            print("Adding 'contact_name' column...")
            try:
                db.execute(text("ALTER TABLE addresses ADD COLUMN contact_name VARCHAR(100) DEFAULT 'User'"))
                db.commit()
                print("Added contact_name.")
            except Exception as e:
                db.rollback()
                print(f"Failed to add contact_name: {e}")
        else:
            print("'contact_name' already exists.")

        if 'contact_phone' not in columns:
            print("Adding 'contact_phone' column...")
            try:
                db.execute(text("ALTER TABLE addresses ADD COLUMN contact_phone VARCHAR(20) DEFAULT ''"))
                db.commit()
                print("Added contact_phone.")
            except Exception as e:
                db.rollback()
                print(f"Failed to add contact_phone: {e}")
        else:
            print("'contact_phone' already exists.")
            
        # Alter address to be nullable
        print("Altering 'address' column to be nullable...")
        try:
            db.execute(text("ALTER TABLE addresses ALTER COLUMN address DROP NOT NULL"))
            db.commit()
            print("Altered address column.")
        except Exception as e:
            print(f"Warning altering address (might already be nullable): {e}")
            db.rollback()
        
        print("Migration check completed.")
        
    except Exception as e:
        print(f"Migration script error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    migrate_addresses()
