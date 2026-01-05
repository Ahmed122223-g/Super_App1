import sys
import os
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# If running from backend dir, we don't need to append anything if 'app' is here.
# If running from root, append 'backend'.
if os.path.exists('app'):
    sys.path.append('.')
elif os.path.exists('backend'):
    sys.path.append('backend')

from app.core.database import get_db_url
from app.models.doctor import Doctor
from app.services.slot_generator import SlotGenerator
from app.models.reservations import DoctorReservation

def test_slots():
    print("--- Testing Doctor Slot Generation ---")
    
    # 1. Setup Mock Data
    working_hours = {
        "days": {"sunday": True, "monday": False},
        "start": "14:00",
        "end": "16:00" # Should generate 14:00, 14:30, 15:00, 15:30
    }
    
    # Test Date: A Sunday
    test_date = datetime(2025, 1, 5) # Jan 5, 2025 is Sunday
    print(f"Test Date: {test_date.strftime('%A %Y-%m-%d')}")
    
    # Mock Reservoir (Empty)
    slots = SlotGenerator.generate_slots(working_hours, test_date, [])
    print(f"Slots (Empty Reservations): {slots}")
    assert "14:00" in slots
    assert "15:30" in slots
    assert len(slots) == 4
    
    # Mock Reservoir (One booking at 14:30)
    booking = DoctorReservation(visit_date=datetime(2025, 1, 5, 14, 30))
    slots_booked = SlotGenerator.generate_slots(working_hours, test_date, [booking])
    print(f"Slots (Booked 14:30): {slots_booked}")
    assert "14:30" not in slots_booked
    assert "14:00" in slots_booked
    assert len(slots_booked) == 3
    
    # Test Date: A Monday (Not working)
    monday_date = datetime(2025, 1, 6)
    slots_closed = SlotGenerator.generate_slots(working_hours, monday_date, [])
    print(f"Slots (Monday - Closed): {slots_closed}")
    assert len(slots_closed) == 0

    print("\n✅ Slot Generation Logic Verified!")

if __name__ == "__main__":
    test_slots()

