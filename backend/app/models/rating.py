"""
Jiwar Backend - Rating Model
Unified rating system for doctors and pharmacies
"""
from sqlalchemy import (
    Column, Integer, String, Float, DateTime, 
    Text, ForeignKey, CheckConstraint
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.core.database import Base


class Rating(Base):
    """
    Rating model for doctors and pharmacies
    
    Attributes:
        id: Primary key
        user_id: Foreign key to User who gave the rating
        doctor_id: Foreign key to Doctor (nullable)
        pharmacy_id: Foreign key to Pharmacy (nullable)
        rating: Rating value (1-5)
        comment: Optional review text
        created_at: Creation timestamp
    """
    __tablename__ = "ratings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    doctor_id = Column(Integer, ForeignKey("doctors.id"), nullable=True)
    pharmacy_id = Column(Integer, ForeignKey("pharmacies.id"), nullable=True)
    rating = Column(Integer, nullable=False)
    comment = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Constraints
    __table_args__ = (
        CheckConstraint('rating >= 1 AND rating <= 5', name='rating_range'),
        CheckConstraint(
            '(doctor_id IS NOT NULL AND pharmacy_id IS NULL) OR '
            '(doctor_id IS NULL AND pharmacy_id IS NOT NULL)',
            name='exactly_one_target'
        ),
    )
    
    # Relationships
    user = relationship("User", back_populates="ratings_given")
    doctor = relationship("Doctor", back_populates="ratings", foreign_keys=[doctor_id])
    pharmacy = relationship("Pharmacy", back_populates="ratings", foreign_keys=[pharmacy_id])
    
    def __repr__(self):
        target = f"doctor_id={self.doctor_id}" if self.doctor_id else f"pharmacy_id={self.pharmacy_id}"
        return f"<Rating(id={self.id}, {target}, rating={self.rating})>"
