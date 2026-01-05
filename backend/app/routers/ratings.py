"""
Jiwar Backend - Ratings Router
Using separate databases for doctors and pharmacies ratings
"""
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional, Any
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.database import get_doctors_db, get_pharmacies_db, get_users_db, get_teachers_db
from app.models import Doctor, Pharmacy, User, DoctorRating, PharmacyRating
from app.models.teacher import Teacher, TeacherRating
from app.schemas.common import (
    RatingCreate,
    RatingResponse,
    RatingListResponse,
    MessageResponse
)
from app.dependencies import get_current_user
from app.services.notifications import notify_new_rating

router = APIRouter()


@router.post("/", response_model=RatingResponse, status_code=status.HTTP_201_CREATED)
async def create_rating(
    request: RatingCreate,
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    teachers_db: Session = Depends(get_teachers_db),
    users_db: Session = Depends(get_users_db)
):
    """Create a new rating for a doctor, pharmacy, or teacher"""
    
    if not request.doctor_id and not request.pharmacy_id and not request.teacher_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "NO_TARGET", "message": "Must provide doctor_id, pharmacy_id, or teacher_id"}
        )
    
    # Only one target allowed
    targets = [request.doctor_id, request.pharmacy_id, request.teacher_id]
    if sum(1 for t in targets if t is not None) > 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "MULTIPLE_TARGETS", "message": "Provide only one target"}
        )
    
    # Rating for doctor
    if request.doctor_id:
        doctor = doctors_db.query(Doctor).filter(Doctor.id == request.doctor_id).first()
        if not doctor:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"error_code": "DOCTOR_NOT_FOUND", "message": "Doctor not found"}
            )
        
        # Allow multiple ratings per user
        # pass
        
        # Create rating
        rating = DoctorRating(
            doctor_id=request.doctor_id,
            user_id=current_user.id,
            user_name=current_user.name,
            rating=request.rating,
            comment=request.comment,
            is_anonymous=request.is_anonymous
        )
        doctors_db.add(rating)
        
        # Update doctor average rating
        result = doctors_db.query(
            func.avg(DoctorRating.rating),
            func.count(DoctorRating.id)
        ).filter(DoctorRating.doctor_id == doctor.id).first()
        
        # Add the new rating to calculation
        total_ratings = (result[1] or 0) + 1
        sum_ratings = ((result[0] or 0) * (result[1] or 0)) + request.rating
        doctor.rating = round(sum_ratings / total_ratings, 1)
        doctor.total_ratings = total_ratings
        
        doctors_db.commit()
        doctors_db.refresh(rating)
        
        # Notify Doctor
        # We need to find the User associated with this Doctor profile
        doctor_user = users_db.query(User).filter(User.profile_id == doctor.id, User.user_type == "doctor").first()
        if doctor_user and doctor_user.fcm_token:
            notify_new_rating(doctor_user.fcm_token, request.rating, "doctor")

        return RatingResponse(
            id=rating.id,
            user_id=rating.user_id,
            user_name=rating.user_name,
            doctor_id=rating.doctor_id,
            pharmacy_id=None,
            teacher_id=None,
            rating=rating.rating,
            comment=rating.comment,
            created_at=rating.created_at
        )
    
    # Rating for pharmacy
    elif request.pharmacy_id:
        pharmacy = pharmacies_db.query(Pharmacy).filter(Pharmacy.id == request.pharmacy_id).first()
        if not pharmacy:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"error_code": "PHARMACY_NOT_FOUND", "message": "Pharmacy not found"}
            )
        
        # Allow multiple ratings per user
        # pass
        
        # Create rating
        rating = PharmacyRating(
            pharmacy_id=request.pharmacy_id,
            user_id=current_user.id,
            user_name=current_user.name,
            rating=request.rating,
            comment=request.comment,
            is_anonymous=request.is_anonymous
        )
        pharmacies_db.add(rating)
        
        # Update pharmacy average rating
        result = pharmacies_db.query(
            func.avg(PharmacyRating.rating),
            func.count(PharmacyRating.id)
        ).filter(PharmacyRating.pharmacy_id == pharmacy.id).first()
        
        total_ratings = (result[1] or 0) + 1
        sum_ratings = ((result[0] or 0) * (result[1] or 0)) + request.rating
        pharmacy.rating = round(sum_ratings / total_ratings, 1)
        pharmacy.total_ratings = total_ratings
        
        pharmacies_db.commit()
        pharmacies_db.refresh(rating)
        
        # Notify Pharmacy
        pharmacy_user = users_db.query(User).filter(User.profile_id == pharmacy.id, User.user_type == "pharmacy").first()
        if pharmacy_user and pharmacy_user.fcm_token:
            notify_new_rating(pharmacy_user.fcm_token, request.rating, "pharmacy")

        return RatingResponse(
            id=rating.id,
            user_id=rating.user_id,
            user_name=rating.user_name,
            doctor_id=None,
            pharmacy_id=rating.pharmacy_id,
            teacher_id=None,
            rating=rating.rating,
            comment=rating.comment,
            created_at=rating.created_at
        )
    
    # Rating for teacher
    else:
        teacher = teachers_db.query(Teacher).filter(Teacher.id == request.teacher_id).first()
        if not teacher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"error_code": "TEACHER_NOT_FOUND", "message": "Teacher not found"}
            )
        
        # Allow multiple ratings per user
        # pass
        
        # Create rating
        rating = TeacherRating(
            teacher_id=request.teacher_id,
            user_id=current_user.id,
            user_name=current_user.name,
            rating=request.rating,
            comment=request.comment,
            is_anonymous=request.is_anonymous
        )
        teachers_db.add(rating)
        
        # Update teacher average rating
        result = teachers_db.query(
            func.avg(TeacherRating.rating),
            func.count(TeacherRating.id)
        ).filter(TeacherRating.teacher_id == teacher.id).first()
        
        total_ratings = (result[1] or 0) + 1
        sum_ratings = ((result[0] or 0) * (result[1] or 0)) + request.rating
        teacher.rating = round(sum_ratings / total_ratings, 1)
        teacher.total_ratings = total_ratings
        
        teachers_db.commit()
        teachers_db.refresh(rating)
        
        # Notify Teacher
        teacher_user = users_db.query(User).filter(User.profile_id == teacher.id, User.user_type == "teacher").first()
        if teacher_user and teacher_user.fcm_token:
            notify_new_rating(teacher_user.fcm_token, request.rating, "teacher")

        return RatingResponse(
            id=rating.id,
            user_id=rating.user_id,
            user_name=rating.user_name,
            doctor_id=None,
            pharmacy_id=None,
            teacher_id=rating.teacher_id,
            rating=rating.rating,
            comment=rating.comment,
            created_at=rating.created_at
        )


@router.get("/doctor/{doctor_id}", response_model=RatingListResponse)
async def get_doctor_ratings(
    doctor_id: int,
    sort: Optional[str] = None,
    stars: Optional[int] = None,
    doctors_db: Session = Depends(get_doctors_db)
):
    """Get all ratings for a doctor"""
    doctor = doctors_db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "DOCTOR_NOT_FOUND", "message": "Doctor not found"}
        )
    
    query = doctors_db.query(DoctorRating).filter(DoctorRating.doctor_id == doctor_id)
    
    # Filter by stars
    if stars:
        query = query.filter(DoctorRating.rating == stars)
        
    # Sort
    if sort == 'oldest':
        query = query.order_by(DoctorRating.created_at.asc())
    elif sort == 'highest':
        query = query.order_by(DoctorRating.rating.desc())
    elif sort == 'lowest':
        query = query.order_by(DoctorRating.rating.asc())
    else: # Default: newest
        query = query.order_by(DoctorRating.created_at.desc())
        
    ratings = query.all()
    
    return RatingListResponse(
        ratings=[
            RatingResponse(
                id=r.id,
                user_id=r.user_id,
                user_name="مجهول" if r.is_anonymous else r.user_name,
                is_anonymous=r.is_anonymous,
                doctor_id=r.doctor_id,
                pharmacy_id=None,
                teacher_id=None,
                rating=r.rating,
                comment=r.comment,
                created_at=r.created_at
            )
            for r in ratings
        ],
        total=len(ratings),
        average=doctor.rating
    )


@router.get("/pharmacy/{pharmacy_id}", response_model=RatingListResponse)
async def get_pharmacy_ratings(
    pharmacy_id: int,
    sort: Optional[str] = None,
    stars: Optional[int] = None,
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Get all ratings for a pharmacy"""
    pharmacy = pharmacies_db.query(Pharmacy).filter(Pharmacy.id == pharmacy_id).first()
    if not pharmacy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "PHARMACY_NOT_FOUND", "message": "Pharmacy not found"}
        )
    
    query = pharmacies_db.query(PharmacyRating).filter(PharmacyRating.pharmacy_id == pharmacy_id)
    
    if stars:
        query = query.filter(PharmacyRating.rating == stars)
        
    if sort == 'oldest':
        query = query.order_by(PharmacyRating.created_at.asc())
    elif sort == 'highest':
        query = query.order_by(PharmacyRating.rating.desc())
    elif sort == 'lowest':
        query = query.order_by(PharmacyRating.rating.asc())
    else:
        query = query.order_by(PharmacyRating.created_at.desc())
        
    ratings = query.all()
    
    return RatingListResponse(
        ratings=[
            RatingResponse(
                id=r.id,
                user_id=r.user_id,
                user_name="مجهول" if r.is_anonymous else r.user_name,
                is_anonymous=r.is_anonymous,
                doctor_id=None,
                pharmacy_id=r.pharmacy_id,
                teacher_id=None,
                rating=r.rating,
                comment=r.comment,
                created_at=r.created_at
            )
            for r in ratings
        ],
        total=len(ratings),
        average=pharmacy.rating
    )


@router.get("/teacher/{teacher_id}", response_model=RatingListResponse)
async def get_teacher_ratings(
    teacher_id: int,
    sort: Optional[str] = None,
    stars: Optional[int] = None,
    teachers_db: Session = Depends(get_teachers_db)
):
    """Get all ratings for a teacher"""
    teacher = teachers_db.query(Teacher).filter(Teacher.id == teacher_id).first()
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "TEACHER_NOT_FOUND", "message": "Teacher not found"}
        )
    
    query = teachers_db.query(TeacherRating).filter(TeacherRating.teacher_id == teacher_id)
    
    if stars:
        query = query.filter(TeacherRating.rating == stars)
        
    if sort == 'oldest':
        query = query.order_by(TeacherRating.created_at.asc())
    elif sort == 'highest':
        query = query.order_by(TeacherRating.rating.desc())
    elif sort == 'lowest':
        query = query.order_by(TeacherRating.rating.asc())
    else:
        query = query.order_by(TeacherRating.created_at.desc())
        
    ratings = query.all()
    
    return RatingListResponse(
        ratings=[
            RatingResponse(
                id=r.id,
                user_id=r.user_id,
                user_name="مجهول" if r.is_anonymous else r.user_name,
                is_anonymous=r.is_anonymous,
                doctor_id=None,
                pharmacy_id=None,
                teacher_id=r.teacher_id,
                rating=r.rating,
                comment=r.comment,
                created_at=r.created_at
            )
            for r in ratings
        ],
        total=len(ratings),
        average=teacher.rating
    )
