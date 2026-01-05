"""
Jiwar Backend - Reservations Models
Stores reservations for Doctors and Teachers in their respective databases.
"""
from sqlalchemy import (
    Column, Integer, String, DateTime, Enum as SQLEnum, ForeignKey, Text, JSON
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.core.database import DoctorsBase, TeachersBase

class ReservationStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    REJECTED = "rejected"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class DoctorReservation(DoctorsBase):
    """
    Reservation for a Doctor's appointment.
    Stored in 'doctors' database.
    """
    __tablename__ = "doctor_reservations"
    
    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False, index=True)
    user_id = Column(Integer, nullable=False, index=True) # User ID from Users DB
    
    # Patient info snapshot (in case user profile changes or for guest booking later)
    patient_name = Column(String(100), nullable=False)
    patient_phone = Column(String(20), nullable=False)
    
    booking_type = Column(String(20), nullable=True)  # "examination" or "consultation"
    visit_date = Column(DateTime, nullable=False)
    status = Column(SQLEnum(ReservationStatus), default=ReservationStatus.PENDING)
    
    notes = Column(Text, nullable=True)
    rejection_reason = Column(Text, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    doctor = relationship("Doctor", backref="reservations")


class TeacherReservation(TeachersBase):
    """
    Reservation for a Teacher's class/session.
    Stored in 'teachers' database.
    """
    __tablename__ = "teacher_reservations"
    
    id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.id"), nullable=False, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    student_name = Column(String(100), nullable=False)
    student_phone = Column(String(20), nullable=False)
    grade_level = Column(String(50), nullable=True) # e.g., "1st Secondary"
    
    # Schedule set by teacher upon acceptance
    # JSON structure: {"Sunday": ["10:00", "11:00"], "Monday": ["14:00", "15:00"]}
    schedule = Column(JSON, nullable=True)
    
    requested_date = Column(DateTime, nullable=False)
    status = Column(SQLEnum(ReservationStatus), default=ReservationStatus.PENDING)
    
    notes = Column(Text, nullable=True)
    rejection_reason = Column(Text, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    teacher = relationship("Teacher", backref="reservations")
