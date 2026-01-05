"""
Jiwar Backend - Specialties Router
Using Doctors database
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_doctors_db
from app.models import Specialty
from app.schemas.common import SpecialtyResponse, SpecialtyListResponse

router = APIRouter()


@router.get("/", response_model=SpecialtyListResponse)
async def list_specialties(doctors_db: Session = Depends(get_doctors_db)):
    """Get all medical specialties"""
    specialties = doctors_db.query(Specialty).all()
    
    return SpecialtyListResponse(
        specialties=[
            SpecialtyResponse(
                id=s.id,
                name_ar=s.name_ar,
                name_en=s.name_en,
                icon=s.icon
            )
            for s in specialties
        ]
    )


@router.get("/{specialty_id}", response_model=SpecialtyResponse)
async def get_specialty(
    specialty_id: int,
    doctors_db: Session = Depends(get_doctors_db)
):
    """Get a specific specialty by ID"""
    specialty = doctors_db.query(Specialty).filter(
        Specialty.id == specialty_id
    ).first()
    
    if not specialty:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "SPECIALTY_NOT_FOUND", "message": "Specialty not found"}
        )
    
    return SpecialtyResponse(
        id=specialty.id,
        name_ar=specialty.name_ar,
        name_en=specialty.name_en,
        icon=specialty.icon
    )
