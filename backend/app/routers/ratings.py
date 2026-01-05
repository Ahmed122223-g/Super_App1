"""
Jiwar Backend - Ratings Router
Using separate databases for doctors and pharmacies ratings
Refactored to use generic functions (DRY principle)
"""
from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks
from typing import List, Optional, Any, Type
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


# ==========================================
# GENERIC RATING HELPERS (DRY)
# ==========================================

def create_entity_rating(
    db: Session,
    entity_model: Type,
    rating_model: Type,
    entity_id: int,
    entity_id_field: str,
    current_user: User,
    rating_value: int,
    comment: Optional[str],
    is_anonymous: bool,
    entity_type: str,
    users_db: Session,
    background_tasks: BackgroundTasks
) -> tuple:
    """
    Generic function to create a rating for any entity (Doctor, Pharmacy, Teacher).
    Returns (rating_object, entity_object).
    """
    # Find entity
    entity = db.query(entity_model).filter(entity_model.id == entity_id).first()
    if not entity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": f"{entity_type.upper()}_NOT_FOUND", "message": f"{entity_type.title()} not found"}
        )
    
    # Create rating with dynamic field assignment
    rating_data = {
        entity_id_field: entity_id,
        "user_id": current_user.id,
        "user_name": current_user.name,
        "rating": rating_value,
        "comment": comment,
        "is_anonymous": is_anonymous
    }
    rating = rating_model(**rating_data)
    db.add(rating)
    
    # Calculate new average rating
    id_filter = getattr(rating_model, entity_id_field) == entity_id
    result = db.query(
        func.avg(rating_model.rating),
        func.count(rating_model.id)
    ).filter(id_filter).first()
    
    total_ratings = (result[1] or 0) + 1
    sum_ratings = ((result[0] or 0) * (result[1] or 0)) + rating_value
    entity.rating = round(sum_ratings / total_ratings, 1)
    entity.total_ratings = total_ratings
    
    db.commit()
    db.refresh(rating)
    
    # Notify entity owner
    entity_user = users_db.query(User).filter(
        User.profile_id == entity.id, 
        User.user_type == entity_type
    ).first()
    if entity_user:
        background_tasks.add_task(notify_new_rating, users_db, entity_user, rating_value, entity_type)
    
    return rating, entity


def get_entity_ratings(
    db: Session,
    entity_model: Type,
    rating_model: Type,
    entity_id: int,
    entity_id_field: str,
    entity_type: str,
    sort: Optional[str] = None,
    stars: Optional[int] = None
) -> RatingListResponse:
    """
    Generic function to get ratings for any entity (Doctor, Pharmacy, Teacher).
    """
    # Find entity
    entity = db.query(entity_model).filter(entity_model.id == entity_id).first()
    if not entity:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": f"{entity_type.upper()}_NOT_FOUND", "message": f"{entity_type.title()} not found"}
        )
    
    # Build query
    id_filter = getattr(rating_model, entity_id_field) == entity_id
    query = db.query(rating_model).filter(id_filter)
    
    if stars:
        query = query.filter(rating_model.rating == stars)
    
    # Apply sorting
    if sort == "newest":
        query = query.order_by(rating_model.created_at.desc())
    elif sort == "oldest":
        query = query.order_by(rating_model.created_at.asc())
    elif sort == "highest":
        query = query.order_by(rating_model.rating.desc())
    elif sort == "lowest":
        query = query.order_by(rating_model.rating.asc())
    else:
        query = query.order_by(rating_model.created_at.desc())
    
    ratings = query.all()
    
    # Build response
    rating_responses = []
    for r in ratings:
        rating_responses.append(RatingResponse(
            id=r.id,
            user_id=r.user_id,
            user_name=r.user_name if not r.is_anonymous else "مجهول",
            doctor_id=getattr(r, 'doctor_id', None),
            pharmacy_id=getattr(r, 'pharmacy_id', None),
            teacher_id=getattr(r, 'teacher_id', None),
            rating=r.rating,
            comment=r.comment,
            created_at=r.created_at
        ))
    
    return RatingListResponse(
        ratings=rating_responses,
        total=len(ratings),
        average=entity.rating or 0.0
    )


# ==========================================
# RATING ENDPOINTS
# ==========================================

@router.post("/", response_model=RatingResponse, status_code=status.HTTP_201_CREATED)
async def create_rating(
    request: RatingCreate,
    background_tasks: BackgroundTasks,
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
    
    # Determine which entity to rate
    if request.doctor_id:
        rating, entity = create_entity_rating(
            db=doctors_db,
            entity_model=Doctor,
            rating_model=DoctorRating,
            entity_id=request.doctor_id,
            entity_id_field="doctor_id",
            current_user=current_user,
            rating_value=request.rating,
            comment=request.comment,
            is_anonymous=request.is_anonymous,
            entity_type="doctor",
            users_db=users_db,
            background_tasks=background_tasks
        )
        return RatingResponse(
            id=rating.id, user_id=rating.user_id, user_name=rating.user_name,
            doctor_id=rating.doctor_id, pharmacy_id=None, teacher_id=None,
            rating=rating.rating, comment=rating.comment, created_at=rating.created_at
        )
    
    elif request.pharmacy_id:
        rating, entity = create_entity_rating(
            db=pharmacies_db,
            entity_model=Pharmacy,
            rating_model=PharmacyRating,
            entity_id=request.pharmacy_id,
            entity_id_field="pharmacy_id",
            current_user=current_user,
            rating_value=request.rating,
            comment=request.comment,
            is_anonymous=request.is_anonymous,
            entity_type="pharmacy",
            users_db=users_db,
            background_tasks=background_tasks
        )
        return RatingResponse(
            id=rating.id, user_id=rating.user_id, user_name=rating.user_name,
            doctor_id=None, pharmacy_id=rating.pharmacy_id, teacher_id=None,
            rating=rating.rating, comment=rating.comment, created_at=rating.created_at
        )
    
    else:  # teacher_id
        rating, entity = create_entity_rating(
            db=teachers_db,
            entity_model=Teacher,
            rating_model=TeacherRating,
            entity_id=request.teacher_id,
            entity_id_field="teacher_id",
            current_user=current_user,
            rating_value=request.rating,
            comment=request.comment,
            is_anonymous=request.is_anonymous,
            entity_type="teacher",
            users_db=users_db,
            background_tasks=background_tasks
        )
        return RatingResponse(
            id=rating.id, user_id=rating.user_id, user_name=rating.user_name,
            doctor_id=None, pharmacy_id=None, teacher_id=rating.teacher_id,
            rating=rating.rating, comment=rating.comment, created_at=rating.created_at
        )


@router.get("/doctor/{doctor_id}", response_model=RatingListResponse)
async def get_doctor_ratings(
    doctor_id: int,
    sort: Optional[str] = None,
    stars: Optional[int] = None,
    doctors_db: Session = Depends(get_doctors_db)
):
    """Get all ratings for a doctor"""
    return get_entity_ratings(
        db=doctors_db,
        entity_model=Doctor,
        rating_model=DoctorRating,
        entity_id=doctor_id,
        entity_id_field="doctor_id",
        entity_type="doctor",
        sort=sort,
        stars=stars
    )


@router.get("/pharmacy/{pharmacy_id}", response_model=RatingListResponse)
async def get_pharmacy_ratings(
    pharmacy_id: int,
    sort: Optional[str] = None,
    stars: Optional[int] = None,
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Get all ratings for a pharmacy"""
    return get_entity_ratings(
        db=pharmacies_db,
        entity_model=Pharmacy,
        rating_model=PharmacyRating,
        entity_id=pharmacy_id,
        entity_id_field="pharmacy_id",
        entity_type="pharmacy",
        sort=sort,
        stars=stars
    )


@router.get("/teacher/{teacher_id}", response_model=RatingListResponse)
async def get_teacher_ratings(
    teacher_id: int,
    sort: Optional[str] = None,
    stars: Optional[int] = None,
    teachers_db: Session = Depends(get_teachers_db)
):
    """Get all ratings for a teacher"""
    return get_entity_ratings(
        db=teachers_db,
        entity_model=Teacher,
        rating_model=TeacherRating,
        entity_id=teacher_id,
        entity_id_field="teacher_id",
        entity_type="teacher",
        sort=sort,
        stars=stars
    )
