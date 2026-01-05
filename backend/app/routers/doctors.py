"""
Jiwar Backend - Doctors Router
Using separate Doctors database
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import or_
from typing import Optional, List

from app.core.database import get_doctors_db, get_users_db
from app.models import Doctor, Specialty, User, UserType
from app.models.reservations import DoctorReservation
from app.services.slot_generator import SlotGenerator
from datetime import date as date_type, datetime
from app.schemas.doctor import (
    DoctorResponse,
    DoctorListResponse,
    DoctorMapPin,
    DoctorUpdateRequest
)
from app.schemas.common import SpecialtyResponse, SpecialtyListResponse
from app.dependencies import get_current_user, require_user_type

router = APIRouter()


def build_doctor_response(doctor: Doctor) -> DoctorResponse:
    """Helper to build doctor response with specialty info"""
    return DoctorResponse(
        id=doctor.id,
        name=doctor.name,
        description=doctor.description,
        specialty_id=doctor.specialty_id,
        specialty_name_ar=doctor.specialty.name_ar if doctor.specialty else None,
        specialty_name_en=doctor.specialty.name_en if doctor.specialty else None,
        address=doctor.address,
        latitude=doctor.latitude,
        longitude=doctor.longitude,
        city=doctor.city,
        governorate=doctor.governorate,
        phone=doctor.phone,
        consultation_fee=doctor.consultation_fee,
        rating=doctor.rating,
        total_ratings=doctor.total_ratings,
        is_verified=doctor.is_verified,
        working_hours=doctor.working_hours,
        examination_fee=doctor.examination_fee
    )

@router.get("/{doctor_id}/slots", response_model=List[str])
async def get_doctor_slots(
    doctor_id: int,
    date: date_type,
    doctors_db: Session = Depends(get_doctors_db)
):
    """Get available time slots for a doctor on a specific date"""
    doctor = doctors_db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "DOCTOR_NOT_FOUND", "message": "Doctor not found"}
        )
        
    # Get existing reservations for this doctor on this day
    # Assuming visit_date is DATETIME. We filter by the date part.
    # Note: sqlalchemy filter on date(DateTimeColumn) depends on DB backend. 
    # For postgres: func.date(col)
    from sqlalchemy import func
    
    reservations = doctors_db.query(DoctorReservation).filter(
        DoctorReservation.doctor_id == doctor_id,
        func.date(DoctorReservation.visit_date) == date
    ).all()
    
    # Generate slots
    slots = SlotGenerator.generate_slots(
        working_hours=doctor.working_hours, 
        date=datetime.combine(date, datetime.min.time()),
        existing_reservations=reservations
    )
    
    return slots


@router.get("/", response_model=DoctorListResponse)
async def list_doctors(
    city: Optional[str] = None,
    specialty_id: Optional[int] = None,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=100, le=1000),
    doctors_db: Session = Depends(get_doctors_db)
):
    """List all doctors, optionally filtered by city and specialty"""
    query = doctors_db.query(Doctor)
    
    # Optional city filter
    if city:
        query = query.filter(Doctor.city == city)
    
    # Optional specialty filter
    if specialty_id:
        query = query.filter(Doctor.specialty_id == specialty_id)
    
    # Order by rating (best first)
    query = query.order_by(Doctor.rating.desc())
    
    # Pagination
    total = query.count()
    # Use joinedload to prevent N+1 queries for specialty
    doctors = query.options(joinedload(Doctor.specialty)).offset(skip).limit(limit).all()
    
    return DoctorListResponse(
        doctors=[build_doctor_response(d) for d in doctors],
        total=total
    )


@router.get("/search", response_model=List[DoctorMapPin])
async def search_doctors(
    q: str = Query(..., min_length=1),
    city: str = Query(default="الواسطي"),
    doctors_db: Session = Depends(get_doctors_db)
):
    """Search doctors by name or specialty"""
    doctors = doctors_db.query(Doctor).join(Specialty).filter(
        Doctor.city == city,
        Doctor.is_verified == True,
        or_(
            Doctor.name.ilike(f"%{q}%"),
            Specialty.name_ar.ilike(f"%{q}%"),
            Specialty.name_en.ilike(f"%{q}%")
        )
    ).all()
    
    return [
        DoctorMapPin(
            id=d.id,
            name=d.name,
            specialty_name_ar=d.specialty.name_ar,
            address=d.address,
            latitude=d.latitude,
            longitude=d.longitude,
            rating=d.rating
        )
        for d in doctors
    ]


@router.get("/by-specialty/{specialty_id}", response_model=List[DoctorMapPin])
async def get_doctors_by_specialty(
    specialty_id: int,
    city: str = Query(default="الواسطي"),
    doctors_db: Session = Depends(get_doctors_db)
):
    """Get all doctors of a specific specialty"""
    doctors = doctors_db.query(Doctor).filter(
        Doctor.specialty_id == specialty_id,
        Doctor.city == city,
        Doctor.is_verified == True
    ).all()
    
    return [
        DoctorMapPin(
            id=d.id,
            name=d.name,
            specialty_name_ar=d.specialty.name_ar if d.specialty else "",
            address=d.address,
            latitude=d.latitude,
            longitude=d.longitude,
            rating=d.rating
        )
        for d in doctors
    ]


@router.get("/{doctor_id}", response_model=DoctorResponse)
async def get_doctor(
    doctor_id: int,
    doctors_db: Session = Depends(get_doctors_db)
):
    """Get doctor details by ID"""
    doctor = doctors_db.query(Doctor).filter(Doctor.id == doctor_id).first()
    
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "DOCTOR_NOT_FOUND", "message": "Doctor not found"}
        )
    
    return build_doctor_response(doctor)


@router.put("/me", response_model=DoctorResponse)
async def update_my_doctor_profile(
    request: DoctorUpdateRequest,
    current_user: User = Depends(require_user_type(UserType.DOCTOR)),
    doctors_db: Session = Depends(get_doctors_db)
):
    """Update current doctor's profile"""
    doctor = doctors_db.query(Doctor).filter(
        Doctor.user_id == current_user.id
    ).first()
    
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "DOCTOR_PROFILE_NOT_FOUND", "message": "Doctor profile not found"}
        )
    
    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(doctor, field, value)
    
    doctors_db.commit()
    doctors_db.refresh(doctor)
    
    return build_doctor_response(doctor)


@router.get("/me/profile", response_model=DoctorResponse)
async def get_my_doctor_profile(
    current_user: User = Depends(require_user_type(UserType.DOCTOR)),
    doctors_db: Session = Depends(get_doctors_db)
):
    """Get current doctor's profile"""
    doctor = doctors_db.query(Doctor).filter(
        Doctor.user_id == current_user.id
    ).first()
    
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "DOCTOR_PROFILE_NOT_FOUND", "message": "Doctor profile not found"}
        )
    
    return build_doctor_response(doctor)
