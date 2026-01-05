from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.sql import func
from app.core.database import UsersBase

class Favorite(UsersBase):
    """
    Stores user's favorite providers.
    """
    __tablename__ = "favorites"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    provider_id = Column(Integer, nullable=False)
    provider_type = Column(String(50), nullable=False) # doctor, pharmacy, teacher
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Ensure a user can only favorite a provider once
    __table_args__ = (
        UniqueConstraint('user_id', 'provider_id', 'provider_type', name='uq_user_favorite'),
    )
