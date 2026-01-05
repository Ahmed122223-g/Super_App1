from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class TeacherReservationRequest(BaseModel):
    """Schema for requesting a lesson with a teacher"""
    teacher_id: int
    subject_id: Optional[int] = None
    student_name: str
    student_phone: str
    grade_level: Optional[str] = None
    notes: Optional[str] = None
    requested_date: datetime

class ReservationResponse(BaseModel):
    """Generic response for created reservation"""
    id: int
    status: str
    created_at: datetime
    message: str

    class Config:
        from_attributes = True
