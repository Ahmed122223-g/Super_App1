"""
Jiwar Backend - User Model (Users Database)
Defines the User table with authentication fields
"""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Enum as SQLEnum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from app.core.database import UsersBase


class UserType(str, enum.Enum):
    """Enum for user types"""
    CUSTOMER = "customer"
    DOCTOR = "doctor"
    PHARMACY = "pharmacy"
    RESTAURANT = "restaurant"
    COMPANY = "company"
    ENGINEER = "engineer"
    MECHANIC = "mechanic"
    TEACHER = "teacher"
    ADMIN = "admin"


class User(UsersBase):
    """
    User model for authentication (stored in Users DB)
    
    Attributes:
        id: Primary key
        email: Unique email address
        password_hash: Bcrypt hashed password
        name: Full name
        phone: Phone number (optional)
        age: User age (optional)
        address: User address (optional)
        user_type: Type of user
        profile_id: ID of the profile in the respective database
        is_active: Whether the user account is active
        is_verified: Whether the user has verified their email
    """
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(100), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    name = Column(String(100), nullable=False)
    phone = Column(String(20), nullable=True)
    age = Column(Integer, nullable=True)
    address = Column(String(255), nullable=True)
    user_type = Column(
        SQLEnum(UserType),
        default=UserType.CUSTOMER,
        nullable=False
    )
    # Reference to profile in other database (doctor_id, pharmacy_id, etc.)
    profile_id = Column(Integer, nullable=True)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    # FCM Token for push notifications
    fcm_token = Column(String(500), nullable=True)
    # Token version for single session enforcement
    token_version = Column(Integer, default=1, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
    
    addresses = relationship("Address", back_populates="user")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, email='{self.email}', type={self.user_type})>"


class Address(UsersBase):
    """
    User Saved Addresses (stored in Users DB)
    """
    __tablename__ = "addresses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    label = Column(String(50), nullable=False) # e.g. Home, Work, Family
    contact_name = Column(String(100), nullable=False) # الاسم
    contact_phone = Column(String(20), nullable=False) # رقم الهاتف
    address = Column(String(255), nullable=True) # العنوان (اختياري)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    is_default = Column(Boolean, default=False)
    
    user = relationship("User", back_populates="addresses")

    def __repr__(self):
        return f"<Address(id={self.id}, label='{self.label}')>"



