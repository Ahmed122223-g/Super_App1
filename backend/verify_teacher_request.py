import sys
import os
import asyncio
from datetime import datetime

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app.core.database import TeachersSessionLocal, teachers_engine, TeachersBase
from app.models.teacher import Teacher, Subject
from app.routers.teachers import request_teacher_booking
from app.schemas.reservation import TeacherReservationRequest

# Ensure tables exist
TeachersBase.metadata.create_all(bind=teachers_engine)

async def test_teacher_request():
    print("--- Testing Teacher Booking Request ---")
    
    db = TeachersSessionLocal()
    
    try:
        # 1. Create Mock Teacher if needed
        teacher = db.query(Teacher).first()
        if not teacher:
            print("Creating mock teacher...")
            # Need a subject first
            subject = db.query(Subject).first()
            if not subject:
                subject = Subject(name_ar="Math", name_en="Math")
                db.add(subject)
                db.commit()
                
            teacher = Teacher(
                user_id=999,
                name="Mr. Test",
                subject_id=subject.id,
                address="Test Addr",
                latitude=0.0,
                longitude=0.0
            )
            db.add(teacher)
            db.commit()
            db.refresh(teacher)
            
        print(f"Testing with Teacher ID: {teacher.id}")
        
        # 2. Create Request
        req_data = TeacherReservationRequest(
            teacher_id=teacher.id,
            student_name="Ahmed Student",
            student_phone="0123456789",
            grade_level="1st Secondary",
            notes="Test Booking",
            requested_date=datetime.now()
        )
        
        # Call function directly (simulation of API call)
        response = await request_teacher_booking(req_data, db)
        
        print(f"Response: {response}")
        assert response.message == "Reservation request sent successfully"
        assert response.status == "pending"
        
        print("\n✅ Teacher Booking Request Verified!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(test_teacher_request())
