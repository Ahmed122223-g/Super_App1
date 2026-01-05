from datetime import datetime, timedelta, time
from typing import List, Dict, Optional
from app.models.reservations import DoctorReservation

class SlotGenerator:
    @staticmethod
    def generate_slots(
        working_hours: Dict,
        date: datetime,
        existing_reservations: List[DoctorReservation]
    ) -> List[str]:
        """
        Generate available 30-minute time slots for a specific date
        based on working hours and existing reservations.
        """
        # Get English day name (e.g., "Sunday")
        day_name = date.strftime("%A")
        
        # Check if doctor works on this day
        # working_hours format: {"Sunday": [{"start": "14:00", "end": "17:00"}], ...}
        # Or simple format: {"days": {"sunday": true}, "start": "14:00", "end": "17:00"} (Current format in DB seems mixed, let's support the simple one first based on provider_details_panel.dart)
        
        # Based on provider_details_panel.dart:
        # hours = provider.workingHours!;
        # start = hours['start'] ?? '09:00';
        # end = hours['end'] ?? '21:00';
        # daysMap = hours['days'] as Map<String, dynamic>?;
        
        if not working_hours:
            return []
            
        days_map = working_hours.get('days', {})
        # Check if day is enabled (keys are lowercase in DB usually)
        if not days_map.get(day_name.lower(), False):
            return []
            
        start_str = working_hours.get('start', '09:00')
        end_str = working_hours.get('end', '21:00')
        
        try:
            start_time = datetime.strptime(start_str, "%H:%M").time()
            end_time = datetime.strptime(end_str, "%H:%M").time()
        except ValueError:
            return []
            
        # Create base slots (30 min intervals)
        slots = []
        current_time = datetime.combine(date.date(), start_time)
        end_datetime = datetime.combine(date.date(), end_time)
        
        while current_time + timedelta(minutes=30) <= end_datetime:
            slot_start = current_time
            # slot_end = current_time + timedelta(minutes=30)
            
            # Check if this slot conflicts with any existing reservation
            is_booked = False
            for res in existing_reservations:
                # Basic check: if reservation visit_date matches slot_start
                # NOTE: Reservation system currently stores specific visit_date. 
                # We assume reservation duration is also 30 mins for simplicity, or we treat visit_date as the start time.
                if res.visit_date == slot_start:
                    is_booked = True
                    break
            
            if not is_booked:
                slots.append(slot_start.strftime("%H:%M"))
                
            current_time += timedelta(minutes=30)
            
        return slots
