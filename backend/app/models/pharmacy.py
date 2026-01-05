"""
Jiwar Backend - Pharmacy Model (Pharmacies Database)
Defines the Pharmacy profile with location and medicines
"""
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, 
    DateTime, Text, ForeignKey, JSON
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.core.database import PharmaciesBase


class Pharmacy(PharmaciesBase):
    """
    Pharmacy profile model (stored in Pharmacies DB)
    """
    __tablename__ = "pharmacies"
    
    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, nullable=False, index=True)  # Reference to Users DB
    name = Column(String(100), nullable=False)
    address = Column(Text, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    city = Column(String(50), default="الواسطي", index=True)
    governorate = Column(String(50), default="بني سويف")
    phone = Column(String(20), nullable=True)
    profile_image = Column(String(255), nullable=True)
    delivery_available = Column(Boolean, default=False)
    working_hours = Column(JSON, nullable=True)
    rating = Column(Float, default=0.0)
    total_ratings = Column(Integer, default=0)
    is_verified = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
    
    # Relationships
    medicines = relationship("Medicine", back_populates="pharmacy", cascade="all, delete-orphan")
    ratings = relationship("PharmacyRating", back_populates="pharmacy")
    
    def __repr__(self):
        return f"<Pharmacy(id={self.id}, name='{self.name}')>"


class Medicine(PharmaciesBase):
    """
    Medicine model for pharmacy inventory (stored in Pharmacies DB)
    """
    __tablename__ = "medicines"
    
    id = Column(Integer, primary_key=True, index=True)
    pharmacy_id = Column(Integer, ForeignKey("pharmacies.id"), nullable=False)
    name = Column(String(100), nullable=False, index=True)
    price = Column(Float, nullable=True)
    quantity = Column(Integer, default=0)
    available = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now()
    )
    
    # Relationships
    pharmacy = relationship("Pharmacy", back_populates="medicines")
    
    def __repr__(self):
        return f"<Medicine(id={self.id}, name='{self.name}')>"


class PharmacyRating(PharmaciesBase):
    """Pharmacy ratings (stored in Pharmacies DB)"""
    __tablename__ = "pharmacy_ratings"
    
    id = Column(Integer, primary_key=True, index=True)
    pharmacy_id = Column(Integer, ForeignKey("pharmacies.id"), nullable=False)
    user_id = Column(Integer, nullable=False)  # Reference to Users DB
    user_name = Column(String(100), nullable=True)  # Cached for display
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    is_anonymous = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    pharmacy = relationship("Pharmacy", back_populates="ratings")
