"""
Jiwar Backend - Schemas Package
"""
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    DoctorRegisterFull,
    PharmacyRegisterFull,
    UserResponse,
    AdminTypeEnum
)
from app.schemas.doctor import (
    DoctorResponse,
    DoctorListResponse,
    DoctorSearchRequest,
    DoctorMapPin,
    DoctorUpdateRequest
)
from app.schemas.pharmacy import (
    PharmacyResponse,
    PharmacyListResponse,
    PharmacyMapPin,
    PharmacyUpdateRequest,
    MedicineCreate,
    MedicineUpdate,
    MedicineResponse,
    MedicineSearchResult,
    MedicineSearchResponse
)
from app.schemas.common import (
    RatingCreate,
    RatingResponse,
    RatingListResponse,
    SpecialtyResponse,
    SpecialtyListResponse,
    MessageResponse,
    ErrorResponse,
    PaginatedResponse
)

__all__ = [
    # Auth
    "UserRegisterRequest",
    "UserLoginRequest", 
    "TokenResponse",
    "RefreshTokenRequest",
    "DoctorRegisterFull",
    "PharmacyRegisterFull",
    "UserResponse",
    "AdminTypeEnum",
    # Doctor
    "DoctorResponse",
    "DoctorListResponse",
    "DoctorSearchRequest",
    "DoctorMapPin",
    "DoctorUpdateRequest",
    # Pharmacy
    "PharmacyResponse",
    "PharmacyListResponse",
    "PharmacyMapPin",
    "PharmacyUpdateRequest",
    "MedicineCreate",
    "MedicineUpdate",
    "MedicineResponse",
    "MedicineSearchResult",
    "MedicineSearchResponse",
    # Common
    "RatingCreate",
    "RatingResponse",
    "RatingListResponse",
    "SpecialtyResponse",
    "SpecialtyListResponse",
    "MessageResponse",
    "ErrorResponse",
    "PaginatedResponse"
]
