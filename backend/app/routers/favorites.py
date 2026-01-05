from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from app.core.database import get_users_db, get_doctors_db, get_pharmacies_db, get_teachers_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.favorites import Favorite
from app.models.doctor import Doctor
from app.models.pharmacy import Pharmacy
from app.models.teacher import Teacher
from app.models.doctor import Specialty
from app.models.teacher import Subject

router = APIRouter()

# --- Schemas ---

class FavoriteRequest(BaseModel):
    provider_id: int
    provider_type: str # doctor, pharmacy, teacher

class FavoriteResponse(BaseModel):
    id: int
    provider_id: int
    provider_type: str
    provider_name: str
    provider_image: Optional[str] = None
    provider_specialty: Optional[str] = None
    provider_address: Optional[str] = None
    provider_latitude: Optional[float] = None
    provider_longitude: Optional[float] = None
    provider_rating: Optional[float] = None
    provider_total_ratings: Optional[int] = None
    provider_phone: Optional[str] = None
    provider_description: Optional[str] = None
    provider_whatsapp: Optional[str] = None
    provider_consultation_fee: Optional[float] = None
    provider_examination_fee: Optional[float] = None
    provider_delivery_available: Optional[bool] = None
    provider_working_hours: Optional[dict] = None
    provider_pricing: Optional[list] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

# --- Endpoints ---

@router.post("/toggle")
def toggle_favorite(
    req: FavoriteRequest,
    current_user: User = Depends(get_current_user),
    users_db: Session = Depends(get_users_db)
):
    """Add or remove from favorites"""
    existing = users_db.query(Favorite).filter(
        Favorite.user_id == current_user.id,
        Favorite.provider_id == req.provider_id,
        Favorite.provider_type == req.provider_type
    ).first()
    
    if existing:
        users_db.delete(existing)
        users_db.commit()
        return {"success": True, "action": "removed", "message": "تم الحذف من المفضلة"}
    else:
        new_fav = Favorite(
            user_id=current_user.id,
            provider_id=req.provider_id,
            provider_type=req.provider_type
        )
        users_db.add(new_fav)
        users_db.commit()
        return {"success": True, "action": "added", "message": "تم الإضافة للمفضلة"}


@router.get("/", response_model=List[FavoriteResponse])
def get_my_favorites(
    type: Optional[str] = None, # optional filter
    current_user: User = Depends(get_current_user),
    users_db: Session = Depends(get_users_db),
    doctors_db: Session = Depends(get_doctors_db),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    teachers_db: Session = Depends(get_teachers_db)
):
    """Get all favorites with provider details"""
    query = users_db.query(Favorite).filter(Favorite.user_id == current_user.id)
    if type:
        query = query.filter(Favorite.provider_type == type)
    
    favorites = query.order_by(desc(Favorite.created_at)).all()
    results = []
    
    for fav in favorites:
        provider_data = {
            "id": fav.id,
            "provider_id": fav.provider_id,
            "provider_type": fav.provider_type,
            "provider_name": "Unknown",
            "provider_image": None,
            "provider_specialty": None,
            "provider_address": None,
            "provider_latitude": None,
            "provider_longitude": None,
            "provider_rating": None,
            "provider_total_ratings": None,
            "provider_phone": None,
            "provider_description": None,
            "provider_whatsapp": None,
            "provider_consultation_fee": None,
            "provider_examination_fee": None,
            "provider_delivery_available": None,
            "provider_working_hours": None,
            "provider_pricing": None,
            "created_at": fav.created_at
        }
        
        # Fetch provider details from respective DB
        if fav.provider_type == "doctor":
            doc = doctors_db.query(Doctor).filter(Doctor.id == fav.provider_id).first()
            if doc:
                provider_data["provider_name"] = doc.name
                provider_data["provider_image"] = doc.profile_image
                provider_data["provider_address"] = doc.address
                provider_data["provider_latitude"] = doc.latitude
                provider_data["provider_longitude"] = doc.longitude
                provider_data["provider_rating"] = doc.rating
                provider_data["provider_total_ratings"] = doc.total_ratings
                provider_data["provider_phone"] = doc.phone
                provider_data["provider_description"] = doc.description
                provider_data["provider_consultation_fee"] = doc.consultation_fee
                provider_data["provider_examination_fee"] = doc.examination_fee
                provider_data["provider_working_hours"] = doc.working_hours
                if doc.specialty_id:
                    spec = doctors_db.query(Specialty).filter(Specialty.id == doc.specialty_id).first()
                    provider_data["provider_specialty"] = spec.name_ar if spec else None
                    
        elif fav.provider_type == "pharmacy":
            pharma = pharmacies_db.query(Pharmacy).filter(Pharmacy.id == fav.provider_id).first()
            if pharma:
                provider_data["provider_name"] = pharma.name
                provider_data["provider_image"] = pharma.profile_image
                provider_data["provider_specialty"] = "صيدلية"
                provider_data["provider_address"] = pharma.address
                provider_data["provider_latitude"] = pharma.latitude
                provider_data["provider_longitude"] = pharma.longitude
                provider_data["provider_rating"] = pharma.rating
                provider_data["provider_total_ratings"] = pharma.total_ratings
                provider_data["provider_phone"] = pharma.phone
                provider_data["provider_description"] = getattr(pharma, 'description', None)
                provider_data["provider_whatsapp"] = getattr(pharma, 'whatsapp', None)
                provider_data["provider_delivery_available"] = getattr(pharma, 'delivery_available', None)
                provider_data["provider_working_hours"] = getattr(pharma, 'working_hours', None)

        elif fav.provider_type == "teacher":
            teacher = teachers_db.query(Teacher).filter(Teacher.id == fav.provider_id).first()
            if teacher:
                provider_data["provider_name"] = teacher.name
                provider_data["provider_image"] = teacher.profile_image
                provider_data["provider_address"] = teacher.address
                provider_data["provider_latitude"] = teacher.latitude
                provider_data["provider_longitude"] = teacher.longitude
                provider_data["provider_rating"] = teacher.rating
                provider_data["provider_total_ratings"] = teacher.total_ratings
                provider_data["provider_phone"] = teacher.phone
                provider_data["provider_description"] = getattr(teacher, 'description', None)
                provider_data["provider_whatsapp"] = getattr(teacher, 'whatsapp', None)
                provider_data["provider_working_hours"] = getattr(teacher, 'working_hours', None)
                # Convert pricing ORM objects to dicts
                pricing = getattr(teacher, 'pricing', None)
                if pricing:
                    provider_data["provider_pricing"] = [
                        {"grade_name": p.grade_name, "price": p.price} for p in pricing
                    ]
                if teacher.subject_id:
                    subj = teachers_db.query(Subject).filter(Subject.id == teacher.subject_id).first()
                    provider_data["provider_specialty"] = subj.name_ar if subj else None

        results.append(FavoriteResponse(**provider_data))
        
    return results
