"""
Jiwar Backend - Common Schemas
Shared schemas for ratings and general responses
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime


# ============================================
# RATING SCHEMAS
# ============================================

class RatingCreate(BaseModel):
    """Create a new rating"""
    doctor_id: Optional[int] = None
    pharmacy_id: Optional[int] = None
    teacher_id: Optional[int] = None
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = Field(None, max_length=500)
    is_anonymous: bool = False


class RatingResponse(BaseModel):
    """Rating data response"""
    id: int
    user_id: int
    user_name: Optional[str] = None
    doctor_id: Optional[int] = None
    pharmacy_id: Optional[int] = None
    teacher_id: Optional[int] = None
    rating: int
    comment: Optional[str]
    is_anonymous: bool = False
    created_at: datetime
    
    class Config:
        from_attributes = True


class RatingListResponse(BaseModel):
    """List of ratings"""
    ratings: List[RatingResponse]
    total: int
    average: float


# ============================================
# SPECIALTY SCHEMAS
# ============================================

class SpecialtyResponse(BaseModel):
    """Specialty data response"""
    id: int
    name_ar: str
    name_en: Optional[str]
    icon: Optional[str]
    
    class Config:
        from_attributes = True


class SpecialtyListResponse(BaseModel):
    """List of specialties"""
    specialties: List[SpecialtyResponse]


# ============================================
# GENERAL RESPONSE SCHEMAS
# ============================================

class MessageResponse(BaseModel):
    """Simple message response"""
    message: str
    success: bool = True


class ErrorResponse(BaseModel):
    """Error response with code for frontend translation"""
    error_code: str
    message: str
    details: Optional[Any] = None


class PaginatedResponse(BaseModel):
    """Paginated response wrapper"""
    items: List[Any]
    total: int
    page: int
    page_size: int
    total_pages: int
