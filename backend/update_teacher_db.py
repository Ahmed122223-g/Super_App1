from sqlalchemy import text, inspect, JSON
from app.core.database import SessionLocal, teachers_engine

def migrate_teacher_reservations():
    print("Starting migration check for 'teacher_reservations'...")
    
    inspector = inspect(teachers_engine)
    columns = [c['name'] for c in inspector.get_columns('teacher_reservations')]
    print(f"Current columns in 'teacher_reservations': {columns}")
    
    if 'schedule' not in columns:
        print("Adding 'schedule' column...")
        with teachers_engine.connect() as connection:
            try:
                # Add JSON column
                connection.execute(text("ALTER TABLE teacher_reservations ADD COLUMN schedule JSONB DEFAULT NULL"))
                connection.commit()
                print("Added 'schedule' column successfully.")
            except Exception as e:
                print(f"Failed to add 'schedule' column: {e}")
                connection.rollback()
    else:
        print("'schedule' column already exists.")
        
    print("Migration check completed.")

if __name__ == "__main__":
    migrate_teacher_reservations()
