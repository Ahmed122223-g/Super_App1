"""
Jiwar Backend - Teacher Model (Teachers Database)
Defines the Teacher profile with subjects and pricing
"""
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, 
    DateTime, Text, ForeignKey, JSON
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.core.database import TeachersBase


class Subject(TeachersBase):
    """
    Educational Subject model (stored in Teachers DB)
    e.g. Mathematics, Physics, Arabic, English
    """
    __tablename__ = "subjects"
    
    id = Column(Integer, primary_key=True, index=True)
    name_ar = Column(String(100), nullable=False)
    name_en = Column(String(100), nullable=True)
    icon = Column(String(50), nullable=True)
    grade_levels = Column(JSON, nullable=True)  # List of allowed grade levels
    
    # Relationships
    teachers = relationship("Teacher", back_populates="subject")
    
    def __repr__(self):
        return f"<Subject(id={self.id}, name_ar='{self.name_ar}')>"


class Teacher(TeachersBase):
    """
    Teacher profile model (stored in Teachers DB)
    """
    __tablename__ = "teachers"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)  # Reference to Users DB
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    subject_id = Column(Integer, ForeignKey("subjects.id"), nullable=False)
    address = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    city = Column(String(50), default="الواسطي", index=True)
    governorate = Column(String(50), default="بني سويف")
    phone = Column(String(20), nullable=True)
    phone = Column(String(20), nullable=True)
    whatsapp = Column(String(20), nullable=True)
    rating = Column(Float, default=0.0)
    total_ratings = Column(Integer, default=0)
    profile_image = Column(String(255), nullable=True)
    is_verified = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
    
    # Relationships
    subject = relationship("Subject", back_populates="teachers")
    pricing = relationship("TeacherPricing", back_populates="teacher", cascade="all, delete-orphan")
    ratings = relationship("TeacherRating", back_populates="teacher")
    
    def __repr__(self):
        return f"<Teacher(id={self.id}, name='{self.name}')>"


class TeacherRating(TeachersBase):
    """Teacher ratings (stored in Teachers DB)"""
    __tablename__ = "teacher_ratings"
    
    id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.id"), nullable=False)
    user_id = Column(Integer, nullable=False)  # Reference to Users DB
    user_name = Column(String(100), nullable=True)  # Cached for display
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    is_anonymous = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    teacher = relationship("Teacher", back_populates="ratings")


class TeacherPricing(TeachersBase):
    """
    Pricing for each grade level the teacher teaches
    """
    __tablename__ = "teacher_pricing"
    
    id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.id"), nullable=False, index=True)
    grade_name = Column(String(100), nullable=False)  # e.g., "1st Secondary"
    price = Column(Float, nullable=False)  # Monthly price
    
    # Relationships
    teacher = relationship("Teacher", back_populates="pricing")
    
    def __repr__(self):
        return f"<TeacherPricing(grade='{self.grade_name}', price={self.price})>"


# Grade level codes:
# primary_1_3: Primary grades 1, 2, 3
# primary_4_6: Primary grades 4, 5, 6
# primary: All primary grades 1-6
# preparatory: All preparatory grades 1-3
# secondary: All secondary grades 1-3

# Predefined subjects data with specific grade level restrictions
SUBJECTS_DATA = [
    # Available for ALL grade levels (primary 1-6, prep 1-3, secondary 1-3)
    {"name_ar": "لغة عربية", "name_en": "Arabic Language", "icon": "book", 
     "grade_levels": ["primary", "preparatory", "secondary"]},
    {"name_ar": "لغة إنجليزية", "name_en": "English Language", "icon": "language", 
     "grade_levels": ["primary", "preparatory", "secondary"]},
    {"name_ar": "رياضيات", "name_en": "Mathematics", "icon": "math", 
     "grade_levels": ["primary", "preparatory", "secondary"]},
    {"name_ar": "تحفيظ قرآن", "name_en": "Quran Memorization", "icon": "quran", 
     "grade_levels": ["primary", "preparatory", "secondary"]},
    
    # Kids Foundation - PRIMARY 1, 2, 3 ONLY
    {"name_ar": "تأسيس أطفال", "name_en": "Kids Foundation", "icon": "child", 
     "grade_levels": ["primary_1_3"]},
    
    # Social Studies & Science - PRIMARY 4, 5, 6 + PREPARATORY
    {"name_ar": "دراسات اجتماعية", "name_en": "Social Studies", "icon": "globe", 
     "grade_levels": ["primary_4_6", "preparatory"]},
    {"name_ar": "علوم", "name_en": "Science", "icon": "science", 
     "grade_levels": ["primary_4_6", "preparatory"]},
    
    # Languages & Programming - PREPARATORY + SECONDARY
    {"name_ar": "لغة فرنسية", "name_en": "French Language", "icon": "eiffel", 
     "grade_levels": ["preparatory", "secondary"]},
    {"name_ar": "لغة ألمانية", "name_en": "German Language", "icon": "german", 
     "grade_levels": ["preparatory", "secondary"]},
    {"name_ar": "برمجة", "name_en": "Programming", "icon": "code", 
     "grade_levels": ["preparatory", "secondary"]},
    
    # SECONDARY ONLY subjects
    {"name_ar": "فيزياء", "name_en": "Physics", "icon": "atom", 
     "grade_levels": ["secondary"]},
    {"name_ar": "كيمياء", "name_en": "Chemistry", "icon": "flask", 
     "grade_levels": ["secondary"]},
    {"name_ar": "أحياء", "name_en": "Biology", "icon": "dna", 
     "grade_levels": ["secondary"]},
    {"name_ar": "جغرافيا", "name_en": "Geography", "icon": "map", 
     "grade_levels": ["secondary"]},
    {"name_ar": "تاريخ", "name_en": "History", "icon": "history", 
     "grade_levels": ["secondary"]},
    {"name_ar": "فلسفة ومنطق", "name_en": "Philosophy & Logic", "icon": "brain", 
     "grade_levels": ["secondary"]},
    {"name_ar": "علم نفس واجتماع", "name_en": "Psychology & Sociology", "icon": "psychology", 
     "grade_levels": ["secondary"]},  # Combined into one subject
    {"name_ar": "إحصاء", "name_en": "Statistics", "icon": "chart", 
     "grade_levels": ["secondary"]},  # New subject
]

