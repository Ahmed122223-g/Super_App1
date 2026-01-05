from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime

class NotificationBase(BaseModel):
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None
    is_read: bool = False

class NotificationResponse(NotificationBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True
