
import os
import sys
from sqlalchemy import create_engine, inspect, text

# Add parent dir to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.core.config import settings

def migrate_pharmacy_db():
    print("Migrating Pharmacy DB...")
    
    # Connection URL for Pharmacies DB
    # Assuming standard pattern, or getting from settings if available
    # Using the same logic as main app
    DATABASE_URL = settings.SQLALCHEMY_PHARMACIES_DATABASE_URI
    
    engine = create_engine(DATABASE_URL)
    inspector = inspect(engine)
    
    table_name = "pharmacy_orders"
    
    # Check if table exists
    if not inspector.has_table(table_name):
        print(f"Table '{table_name}' does not exist. Please run initial migration first.")
        return

    existing_columns = [c['name'] for c in inspector.get_columns(table_name)]
    print(f"Existing columns in '{table_name}': {existing_columns}")
    
    with engine.connect() as conn:
        # Add matches (JSON) if missing - usually for schedule/items
        # But here we need specific columns for pricing workflow
        
        # 1. items_text
        if "items_text" not in existing_columns:
            print("Adding 'items_text' column...")
            conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN items_text TEXT"))
            
        # 2. delivery_fee
        if "delivery_fee" not in existing_columns:
            print("Adding 'delivery_fee' column...")
            conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN delivery_fee FLOAT"))
            
        # 3. estimated_delivery_time
        if "estimated_delivery_time" not in existing_columns:
            print("Adding 'estimated_delivery_time' column...")
            conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN estimated_delivery_time VARCHAR(50)"))
            
        # 4. pharmacy_notes
        if "pharmacy_notes" not in existing_columns:
            print("Adding 'pharmacy_notes' column...")
            conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN pharmacy_notes TEXT"))

        # 5. prescription_image
        if "prescription_image" not in existing_columns:
             print("Adding 'prescription_image' column...")
             conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN prescription_image TEXT"))
             
        conn.commit()
        print("Migration completed successfully.")

if __name__ == "__main__":
    migrate_pharmacy_db()
