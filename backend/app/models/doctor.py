"""
Jiwar Backend - Doctor Model (Doctors Database)
Defines the Doctor profile with location and availability
"""
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, 
    DateTime, Text, ForeignKey, JSON
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.core.database import DoctorsBase


class Specialty(DoctorsBase):
    """
    Medical Specialty model (stored in Doctors DB)
    """
    __tablename__ = "specialties"
    
    id = Column(Integer, primary_key=True, index=True)
    name_ar = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=True)
    icon = Column(String(50), nullable=True)
    
    # Relationships
    doctors = relationship("Doctor", back_populates="specialty")
    
    def __repr__(self):
        return f"<Specialty(id={self.id}, name_ar='{self.name_ar}')>"


class Doctor(DoctorsBase):
    """
    Doctor profile model (stored in Doctors DB)
    """
    __tablename__ = "doctors"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)  # Reference to Users DB
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    specialty_id = Column(Integer, ForeignKey("specialties.id"), nullable=False)
    address = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    city = Column(String(50), default="الواسطي", index=True)
    governorate = Column(String(50), default="بني سويف")
    phone = Column(String(20), nullable=True)
    profile_image = Column(String(255), nullable=True)
    consultation_fee = Column(Float, nullable=True)  # سعر الاستشارة
    examination_fee = Column(Float, nullable=True)   # سعر الكشف
    rating = Column(Float, default=0.0)
    total_ratings = Column(Integer, default=0)
    is_verified = Column(Boolean, default=True)
    working_hours = Column(JSON, nullable=True)  # Same as availability, renamed for consistency
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
    
    # Relationships
    specialty = relationship("Specialty", back_populates="doctors")
    ratings = relationship("DoctorRating", back_populates="doctor")
    
    def __repr__(self):
        return f"<Doctor(id={self.id}, name='{self.name}')>"


class DoctorRating(DoctorsBase):
    """Doctor ratings (stored in Doctors DB)"""
    __tablename__ = "doctor_ratings"
    
    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=False)
    user_id = Column(Integer, nullable=False)  # Reference to Users DB
    user_name = Column(String(100), nullable=True)  # Cached for display
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    is_anonymous = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    doctor = relationship("Doctor", back_populates="ratings")


SPECIALTIES_DATA = [
    {"name_ar": "طبيب أسنان", "name_en": "Dentist", "icon": "tooth"},
    {"name_ar": "طبيب عيون", "name_en": "Ophthalmologist", "icon": "eye"},
    {"name_ar": "طبيب أطفال", "name_en": "Pediatrician", "icon": "child"},
    {"name_ar": "طبيب قلب", "name_en": "Cardiologist", "icon": "heart"},
    {"name_ar": "طبيب جلدية", "name_en": "Dermatologist", "icon": "skin"},
    {"name_ar": "طبيب عظام", "name_en": "Orthopedist", "icon": "bone"},
    {"name_ar": "طبيب أعصاب", "name_en": "Neurologist", "icon": "brain"},
    {"name_ar": "طبيب نساء وتوليد", "name_en": "Gynecologist", "icon": "pregnant"},
    {"name_ar": "طبيب باطنة", "name_en": "Internist", "icon": "internal"},
    {"name_ar": "طبيب أنف وأذن وحنجرة", "name_en": "ENT Specialist", "icon": "ear"},
    {"name_ar": "طبيب مسالك بولية", "name_en": "Urologist", "icon": "kidney"},
    {"name_ar": "طبيب نفسي", "name_en": "Psychiatrist", "icon": "mind"},
    {"name_ar": "جراح عام", "name_en": "General Surgeon", "icon": "surgery"},
    {"name_ar": "طبيب عام", "name_en": "General Practitioner", "icon": "doctor"},
]
