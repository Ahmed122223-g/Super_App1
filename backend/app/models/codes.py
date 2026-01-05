"""
Jiwar Backend - Registration Codes Model
Separate tables for each registration code type
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func

from app.core.database import CodesBase


class BaseCode:
    """Base mixin for all code tables"""
    id = Column(Integer, primary_key=True, index=True)
    code = Column(String(10), unique=True, index=True, nullable=False)
    is_used = Column(Boolean, default=False)
    used_by_email = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    used_at = Column(DateTime(timezone=True), nullable=True)


class DoctorCode(CodesBase, BaseCode):
    """Registration codes for Doctors"""
    __tablename__ = "doctor_codes"
    
    def __repr__(self):
        return f"<DoctorCode(code='{self.code}', is_used={self.is_used})>"


class PharmacyCode(CodesBase, BaseCode):
    """Registration codes for Pharmacies"""
    __tablename__ = "pharmacy_codes"
    
    def __repr__(self):
        return f"<PharmacyCode(code='{self.code}', is_used={self.is_used})>"


class RestaurantCode(CodesBase, BaseCode):
    """Registration codes for Restaurants (Future)"""
    __tablename__ = "restaurant_codes"
    
    def __repr__(self):
        return f"<RestaurantCode(code='{self.code}', is_used={self.is_used})>"


class CompanyCode(CodesBase, BaseCode):
    """Registration codes for Companies (Future)"""
    __tablename__ = "company_codes"
    
    def __repr__(self):
        return f"<CompanyCode(code='{self.code}', is_used={self.is_used})>"


class EngineerCode(CodesBase, BaseCode):
    """Registration codes for Engineers (Future)"""
    __tablename__ = "engineer_codes"
    
    def __repr__(self):
        return f"<EngineerCode(code='{self.code}', is_used={self.is_used})>"


class MechanicCode(CodesBase, BaseCode):
    """Registration codes for Mechanics (Future)"""
    __tablename__ = "mechanic_codes"
    
    def __repr__(self):
        return f"<MechanicCode(code='{self.code}', is_used={self.is_used})>"


class TeacherCode(CodesBase, BaseCode):
    """Registration codes for Teachers"""
    __tablename__ = "teacher_codes"
    
    def __repr__(self):
        return f"<TeacherCode(code='{self.code}', is_used={self.is_used})>"


# Mapping of code types to their models
CODE_MODELS = {
    "doctor": DoctorCode,
    "pharmacy": PharmacyCode,
    "restaurant": RestaurantCode,
    "company": CompanyCode,
    "engineer": EngineerCode,
    "mechanic": MechanicCode,
    "teacher": TeacherCode
}

# Arabic names for display
CODE_TYPE_NAMES = {
    "doctor": "الأطباء",
    "pharmacy": "الصيدليات",
    "restaurant": "المطاعم",
    "company": "الشركات",
    "engineer": "المهندسين",
    "mechanic": "الميكانيكيين",
    "teacher": "المعلمين"
}
