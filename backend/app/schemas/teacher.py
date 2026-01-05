"""
Jiwar Backend - Teacher Schemas
Pydantic models for teacher-related operations
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict


class SubjectResponse(BaseModel):
    """Subject data response"""
    id: int
    name_ar: str
    name_en: Optional[str]
    icon: Optional[str]
    grade_levels: Optional[List[str]] = None
    
    class Config:
        from_attributes = True


class TeacherPricingResponse(BaseModel):
    """Pricing for a specific grade"""
    grade_name: str
    price: float
    
    class Config:
        from_attributes = True


class TeacherResponse(BaseModel):
    """Teacher data response"""
    id: int
    name: str
    description: Optional[str]
    subject_id: int
    subject: Optional[SubjectResponse] = None
    address: str
    latitude: float
    longitude: float
    city: str
    governorate: str
    phone: Optional[str]
    phone: Optional[str]
    # monthly_price removed, replaced by pricing list
    pricing: List[TeacherPricingResponse] = []
    rating: float
    total_ratings: int
    is_verified: bool
    
    class Config:
        from_attributes = True


class TeacherListResponse(BaseModel):
    """List of teachers for map display"""
    teachers: List[TeacherResponse]
    total: int


class TeacherSearchRequest(BaseModel):
    """Search parameters for finding teachers"""
    subject_id: Optional[int] = None
    city: Optional[str] = None
