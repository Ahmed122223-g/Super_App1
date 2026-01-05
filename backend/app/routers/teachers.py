"""
Jiwar Backend - Teachers Router
Handles teacher search and retrieval operations
"""
from fastapi import APIRouter, Depends, HTTPException, Query, status, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional

from app.models.reservations import TeacherReservation, ReservationStatus
from app.core.database import get_teachers_db, get_users_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.teacher import Teacher, Subject, SUBJECTS_DATA
from datetime import datetime
from app.models.reservations import TeacherReservation, ReservationStatus
from app.schemas.reservation import TeacherReservationRequest, ReservationResponse
from app.schemas.teacher import (
    TeacherResponse, TeacherListResponse, 
    SubjectResponse
)
from app.services.notifications import notify_new_booking

router = APIRouter()


# ============================================
# SUBJECTS ENDPOINTS
# ============================================

@router.get("/subjects", response_model=List[SubjectResponse])
async def list_subjects(
    teachers_db: Session = Depends(get_teachers_db)
):
    """List all teaching subjects"""
    subjects = teachers_db.query(Subject).all()
    
    if not subjects:
        for subject_data in SUBJECTS_DATA:
            subject = Subject(**subject_data)
            teachers_db.add(subject)
        teachers_db.commit()
        subjects = teachers_db.query(Subject).all()
        
    return subjects


# ============================================
# TEACHERS ENDPOINTS
# ============================================

def build_teacher_response(teacher: Teacher) -> TeacherResponse:
    """Helper to build teacher response with related data"""
    return teacher


@router.get("/", response_model=TeacherListResponse)
async def list_teachers(
    city: Optional[str] = None,
    subject_id: Optional[int] = None,
    name: Optional[str] = None,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, le=1000),
    teachers_db: Session = Depends(get_teachers_db)
):
    """
    List all teachers, optionally filtered by city, subject, or name
    """
    query = teachers_db.query(Teacher)
    
    if city:
        query = query.filter(Teacher.city == city)
    
    if subject_id:
        query = query.filter(Teacher.subject_id == subject_id)
        
    if name:
        query = query.filter(Teacher.name.ilike(f"%{name}%"))
    
    query = query.order_by(Teacher.rating.desc())
    
    total = query.count()
    teachers = query.offset(skip).limit(limit).all()
    
    return TeacherListResponse(
        teachers=[build_teacher_response(t) for t in teachers],
        total=total
    )


@router.get("/search", response_model=TeacherListResponse)
async def search_teachers(
    q: Optional[str] = None,
    subject_id: Optional[int] = None,
    teachers_db: Session = Depends(get_teachers_db)
):
    """Search teachers by name or subject (Map friendly)"""
    query = teachers_db.query(Teacher)
    
    if q:
        query = query.filter(Teacher.name.ilike(f"%{q}%"))
        
    if subject_id:
        query = query.filter(Teacher.subject_id == subject_id)
        
    teachers = query.all()
    
    return TeacherListResponse(
        teachers=[build_teacher_response(t) for t in teachers],
        total=len(teachers)
    )


@router.get("/{teacher_id}", response_model=TeacherResponse)
async def get_teacher(
    teacher_id: int,
    teachers_db: Session = Depends(get_teachers_db)
):
    """Get specific teacher details"""
    teacher = teachers_db.query(Teacher).filter(Teacher.id == teacher_id).first()
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "TEACHER_NOT_FOUND", "message": "Teacher not found"}
        )
    return build_teacher_response(teacher)


@router.post("/request", response_model=ReservationResponse)
async def request_teacher_booking(
    request: TeacherReservationRequest,
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user),
    teachers_db: Session = Depends(get_teachers_db),
    users_db: Session = Depends(get_users_db)
):
    """
    Submit a booking request to a teacher.
    The teacher will later review and suggest specific times.
    """
    teacher = teachers_db.query(Teacher).filter(Teacher.id == request.teacher_id).first()
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "TEACHER_NOT_FOUND", "message": "Teacher not found"}
        )
        
    new_reservation = TeacherReservation(
        teacher_id=request.teacher_id,
        user_id=current_user.id,
        student_name=request.student_name,
        student_phone=request.student_phone,
        grade_level=request.grade_level,
        requested_date=request.requested_date,
        status=ReservationStatus.PENDING,
        notes=request.notes
    )
    
    teachers_db.add(new_reservation)
    teachers_db.commit()
    teachers_db.refresh(new_reservation)
    
    # Notify Teacher
    teacher_user = users_db.query(User).filter(User.profile_id == teacher.id, User.user_type == "teacher").first()
    if teacher_user:
        background_tasks.add_task(notify_new_booking, users_db, teacher_user, request.student_name, new_reservation.id, "teacher")
    
    return ReservationResponse(
        id=new_reservation.id,
        status=new_reservation.status,
        created_at=new_reservation.created_at,
        message="Reservation request sent successfully"
    )
