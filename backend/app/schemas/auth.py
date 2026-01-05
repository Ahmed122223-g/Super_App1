"""
Jiwar Backend - Authentication Schemas
Pydantic models for request/response validation
"""
from pydantic import BaseModel, EmailStr, Field, field_validator
from typing import Optional, List, Dict
from enum import Enum


class UserTypeEnum(str, Enum):
    """User type enumeration"""
    CUSTOMER = "customer"
    DOCTOR = "doctor"
    PHARMACY = "pharmacy"
    TEACHER = "teacher"
    ADMIN = "admin"


# ============================================
# USER REGISTRATION & LOGIN SCHEMAS
# ============================================

class UserRegisterRequest(BaseModel):
    """Schema for regular user registration"""
    name: str = Field(..., min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(..., min_length=8)
    password_confirm: str = Field(..., min_length=8)
    phone: Optional[str] = Field(None, max_length=20)
    age: Optional[int] = Field(None, ge=1, le=120)
    address: Optional[str] = Field(None, max_length=255)
    
    @field_validator('password_confirm')
    @classmethod
    def passwords_match(cls, v, info):
        if 'password' in info.data and v != info.data['password']:
            raise ValueError('PASSWORDS_DO_NOT_MATCH')
        return v


class UserLoginRequest(BaseModel):
    """Schema for user login"""
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    """Schema for JWT token response"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_type: str
    user_id: int
    name: str


class RefreshTokenRequest(BaseModel):
    """Schema for token refresh"""
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    """Schema for password change"""
    old_password: str
    new_password: str = Field(..., min_length=8)
    confirm_password: str = Field(..., min_length=8)
    
    @field_validator('confirm_password')
    @classmethod
    def passwords_match(cls, v, info):
        if 'new_password' in info.data and v != info.data['new_password']:
            raise ValueError('PASSWORDS_DO_NOT_MATCH')
        return v


# ============================================
# DOCTOR REGISTRATION SCHEMAS
# ============================================

class AdminTypeEnum(str, Enum):
    """Admin registration types"""
    CLINIC = "clinic"
    PHARMACY = "pharmacy"
    COMPANY = "company"
    RESTAURANT = "restaurant"
    ENGINEER = "engineer"

    MECHANIC = "mechanic"
    TEACHER = "teacher"


class DoctorRegisterStep1(BaseModel):
    """Step 1: Verify registration code"""
    registration_code: str


class DoctorRegisterStep2(BaseModel):
    """Step 2: Doctor profile info"""
    name: str = Field(..., min_length=2, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    specialty_id: int
    
    
class DoctorRegisterStep3(BaseModel):
    """Step 3: Location info"""
    address: str = Field(..., min_length=5)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    phone: Optional[str] = Field(None, max_length=20)


class DoctorRegisterStep4(BaseModel):
    """Step 4: Account credentials"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    password_confirm: str = Field(..., min_length=8)
    
    @field_validator('password_confirm')
    @classmethod
    def passwords_match(cls, v, info):
        if 'password' in info.data and v != info.data['password']:
            raise ValueError('PASSWORDS_DO_NOT_MATCH')
        return v


class DoctorRegisterFull(BaseModel):
    """Complete doctor registration (all steps combined)"""
    registration_code: str
    name: str = Field(..., min_length=2, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    specialty_id: int
    address: str = Field(..., min_length=5)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    phone: Optional[str] = Field(None, max_length=20)
    bio: Optional[str] = Field(None, max_length=1000)
    consultation_fee: Optional[float] = Field(None, ge=0)
    email: EmailStr
    password: str = Field(..., min_length=8)
    password_confirm: str = Field(..., min_length=8)
    
    @field_validator('password_confirm')
    @classmethod
    def passwords_match(cls, v, info):
        if 'password' in info.data and v != info.data['password']:
            raise ValueError('PASSWORDS_DO_NOT_MATCH')
        return v


# ============================================
# PHARMACY REGISTRATION SCHEMAS
# ============================================

class PharmacyRegisterStep1(BaseModel):
    """Step 1: Verify registration code"""
    registration_code: str


class PharmacyRegisterStep2(BaseModel):
    """Step 2: Pharmacy info and location"""
    name: str = Field(..., min_length=2, max_length=100)
    address: str = Field(..., min_length=5)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    phone: Optional[str] = Field(None, max_length=20)


class PharmacyRegisterStep3(BaseModel):
    """Step 3: Account credentials"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    password_confirm: str = Field(..., min_length=8)
    
    @field_validator('password_confirm')
    @classmethod
    def passwords_match(cls, v, info):
        if 'password' in info.data and v != info.data['password']:
            raise ValueError('PASSWORDS_DO_NOT_MATCH')
        return v



class TeacherPricingInput(BaseModel):
    """Input for teacher pricing per grade"""
    grade_name: str = Field(..., min_length=2)
    price: float = Field(..., ge=0)


class PharmacyRegisterFull(BaseModel):
    """Complete pharmacy registration (all steps combined)"""
    registration_code: str
    name: str = Field(..., min_length=2, max_length=100)
    address: str = Field(..., min_length=5)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    phone: Optional[str] = Field(None, max_length=20)
    email: EmailStr
    password: str = Field(..., min_length=8)
    password_confirm: str = Field(..., min_length=8)
    
    @field_validator('password_confirm')
    @classmethod
    def passwords_match(cls, v, info):
        if 'password' in info.data and v != info.data['password']:
            raise ValueError('PASSWORDS_DO_NOT_MATCH')
        return v


# ============================================
# TEACHER REGISTRATION SCHEMAS
# ============================================

class TeacherRegisterFull(BaseModel):
    """Complete teacher registration"""
    registration_code: str
    name: str = Field(..., min_length=2, max_length=100)
    phone: str = Field(..., max_length=20)
    address: str = Field(..., min_length=5)
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    longitude: float = Field(..., ge=-180, le=180)
    pricing: List[TeacherPricingInput] = Field(..., min_length=1)
    subject_id: int
    email: EmailStr
    password: str = Field(..., min_length=8)
    password_confirm: str = Field(..., min_length=8)
    
    @field_validator('password_confirm')
    @classmethod
    def passwords_match(cls, v, info):
        if 'password' in info.data and v != info.data['password']:
            raise ValueError('PASSWORDS_DO_NOT_MATCH')
        return v


# ============================================
# USER RESPONSE SCHEMAS
# ============================================

class UserResponse(BaseModel):
    """User data response"""
    id: int
    email: str
    name: str
    phone: Optional[str]
    age: Optional[int]
    address: Optional[str]
    user_type: str
    is_verified: bool
    
    class Config:
        from_attributes = True
