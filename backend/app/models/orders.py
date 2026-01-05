"""
Jiwar Backend - Orders Models
Stores orders for Pharmacies.
"""
from sqlalchemy import (
    Column, Integer, String, Float, DateTime, Enum as SQLEnum, ForeignKey, JSON, Text
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.core.database import PharmaciesBase

class OrderStatus(str, enum.Enum):
    PENDING = "pending"      
    PRICED = "priced"         
    ACCEPTED = "accepted"     
    REJECTED = "rejected"     
    DELIVERED = "delivered"   
    CANCELLED = "cancelled"   

class PharmacyOrder(PharmaciesBase):
    """
    Order for a Pharmacy.
    Stored in 'pharmacies' database.
    """
    __tablename__ = "pharmacy_orders"
    
    id = Column(Integer, primary_key=True, index=True)
    pharmacy_id = Column(Integer, ForeignKey("pharmacies.id"), nullable=False, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # Items requested (could be text list or structured)
    items_text = Column(Text, nullable=True) # Raw text request
    items_json = Column(JSON, nullable=True) # Structured items if selected from list
    prescription_image = Column(Text, nullable=True) # URL or base64 of prescription photo
    
    # Pharmacy Response
    total_price = Column(Float, nullable=True)
    delivery_fee = Column(Float, nullable=True)
    estimated_delivery_time = Column(String(50), nullable=True) # e.g. "30 mins"
    pharmacy_notes = Column(Text, nullable=True)
    
    status = Column(SQLEnum(OrderStatus), default=OrderStatus.PENDING)
    
    # User info
    customer_name = Column(String(100), nullable=False)
    customer_phone = Column(String(20), nullable=False)
    customer_address = Column(Text, nullable=False)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    pharmacy = relationship("Pharmacy", backref="orders")
