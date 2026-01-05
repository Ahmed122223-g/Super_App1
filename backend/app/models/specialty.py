"""
Jiwar Backend - Specialty Model
Defines medical specialties for doctors
"""
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Specialty(Base):
    """
    Medical Specialty model
    
    Attributes:
        id: Primary key
        name_ar: Specialty name in Arabic
        name_en: Specialty name in English
        icon: Icon identifier for UI
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


# Predefined specialties data
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
