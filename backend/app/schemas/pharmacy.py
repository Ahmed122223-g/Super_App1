"""
Jiwar Backend - Pharmacy Schemas
Pydantic models for pharmacy-related operations
"""
from pydantic import BaseModel, Field
from typing import Optional, List, Dict


class PharmacyResponse(BaseModel):
    """Pharmacy data response"""
    id: int
    name: str
    address: str
    latitude: float
    longitude: float
    city: str
    governorate: str
    phone: Optional[str]
    working_hours: Optional[Dict] = None
    rating: float
    total_ratings: int
    is_verified: bool
    
    class Config:
        from_attributes = True


class PharmacyListResponse(BaseModel):
    """List of pharmacies for map display"""
    pharmacies: List[PharmacyResponse]
    total: int


class PharmacyMapPin(BaseModel):
    """Minimal pharmacy data for map pins"""
    id: int
    name: str
    address: str
    latitude: float
    longitude: float
    rating: float
    
    class Config:
        from_attributes = True


class PharmacyUpdateRequest(BaseModel):
    """Update pharmacy profile"""
    name: Optional[str] = Field(None, min_length=2, max_length=100)
    address: Optional[str] = Field(None, min_length=5)
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    phone: Optional[str] = Field(None, max_length=20)
    working_hours: Optional[Dict] = None


# ============================================
# MEDICINE SCHEMAS
# ============================================

class MedicineCreate(BaseModel):
    """Create a new medicine"""
    name: str = Field(..., min_length=1, max_length=100)
    price: Optional[float] = Field(None, ge=0)
    quantity: int = Field(default=0, ge=0)
    available: bool = True


class MedicineUpdate(BaseModel):
    """Update medicine info"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    price: Optional[float] = Field(None, ge=0)
    quantity: Optional[int] = Field(None, ge=0)
    available: Optional[bool] = None


class MedicineResponse(BaseModel):
    """Medicine data response"""
    id: int
    pharmacy_id: int
    name: str
    price: Optional[float]
    quantity: int
    available: bool
    
    class Config:
        from_attributes = True


class MedicineSearchResult(BaseModel):
    """Medicine search result with pharmacy info"""
    medicine: MedicineResponse
    pharmacy_name: str
    pharmacy_address: str
    pharmacy_phone: Optional[str]
    latitude: float
    longitude: float


class MedicineSearchResponse(BaseModel):
    """Medicine search response"""
    results: List[MedicineSearchResult]
    total: int
