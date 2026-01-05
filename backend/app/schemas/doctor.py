"""
Jiwar Backend - Doctor Schemas
Pydantic models for doctor-related operations
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime


class AvailabilitySlot(BaseModel):
    """Availability time slot"""
    from_time: str = Field(..., alias="from", pattern=r"^\d{2}:\d{2}$")
    to_time: str = Field(..., alias="to", pattern=r"^\d{2}:\d{2}$")
    
    class Config:
        populate_by_name = True


class DoctorResponse(BaseModel):
    """Doctor data response"""
    id: int
    name: str
    description: Optional[str]
    specialty_id: int
    specialty_name_ar: Optional[str] = None
    specialty_name_en: Optional[str] = None
    address: str
    latitude: float
    longitude: float
    city: str
    governorate: str
    phone: Optional[str]
    consultation_fee: Optional[float]
    rating: float
    total_ratings: int
    is_verified: bool
    working_hours: Optional[Dict] = None
    examination_fee: Optional[float] = None
    
    class Config:
        from_attributes = True


class DoctorListResponse(BaseModel):
    """List of doctors for map display"""
    doctors: List[DoctorResponse]
    total: int


class DoctorSearchRequest(BaseModel):
    """Search parameters for finding doctors"""
    specialty_id: Optional[int] = None
    specialty_name: Optional[str] = None
    city: str = "الواسطي"
    

class DoctorMapPin(BaseModel):
    """Minimal doctor data for map pins"""
    id: int
    name: str
    specialty_name_ar: str
    address: str
    latitude: float
    longitude: float
    rating: float
    
    class Config:
        from_attributes = True


class DoctorUpdateRequest(BaseModel):
    """Update doctor profile"""
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    address: Optional[str] = Field(None, min_length=5)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    phone: Optional[str] = Field(None, max_length=20)
    consultation_fee: Optional[float] = None
    availability: Optional[Dict] = None
