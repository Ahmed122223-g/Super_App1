"""
Jiwar Backend - Search Router  
Unified search across doctors, pharmacies, and teachers databases
"""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional
from pydantic import BaseModel

from app.core.database import get_doctors_db, get_pharmacies_db, get_teachers_db
from app.models import Doctor, Pharmacy, Specialty
from app.models.teacher import Teacher, Subject

router = APIRouter()


class SearchResult(BaseModel):
    """Unified search result"""
    id: int
    type: str  # doctor, pharmacy, teacher (extensible for future types)
    name: str
    specialty: str | None = None
    address: str
    latitude: float
    longitude: float
    rating: float
    total_ratings: int = 0
    phone: str | None = None
    profile_image: str | None = None
    description: str | None = None


class SearchResponse(BaseModel):
    results: List[SearchResult]
    total: int


class MapProvider(BaseModel):
    """Provider data for map markers"""
    id: int
    type: str
    name: str
    specialty: str | None = None
    address: str
    latitude: float
    longitude: float
    rating: float
    total_ratings: int = 0
    phone: str | None = None
    profile_image: str | None = None
    description: str | None = None
    consultation_fee: float | None = None  # For doctors
    examination_fee: float | None = None   # For doctors
    delivery_available: bool | None = None  # For pharmacies
    working_hours: dict | None = None  # For doctors and pharmacies
    whatsapp: str | None = None  # For teachers
    pricing: List[dict] | None = None  # For teachers [{'grade_name': '...', 'price': ...}]


class AllProvidersResponse(BaseModel):
    providers: List[MapProvider]
    total: int
    doctors_count: int
    pharmacies_count: int
    teachers_count: int


@router.get("/all", response_model=AllProvidersResponse)
async def get_all_providers(
    city: Optional[str] = Query(default=None),
    teacher_name: Optional[str] = Query(default=None, description="Filter teachers by name"),
    subject_id: Optional[int] = Query(default=None, description="Filter teachers by subject ID"),
    doctors_db: Session = Depends(get_doctors_db),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    teachers_db: Session = Depends(get_teachers_db)
):
    """
    Get ALL verified providers for the map display.
    Returns doctors, pharmacies, and teachers with their coordinates.
    """
    providers = []
    
    # Get all verified doctors
    doc_query = doctors_db.query(Doctor).join(Specialty, isouter=True).filter(Doctor.is_verified == True)
    if city:
        doc_query = doc_query.filter(Doctor.city == city)
    doctors = doc_query.all()
    
    for d in doctors:
        providers.append(MapProvider(
            id=d.id,
            type="doctor",
            name=d.name,
            specialty=d.specialty.name_ar if d.specialty else None,
            address=d.address,
            latitude=d.latitude,
            longitude=d.longitude,
            rating=d.rating or 0.0,
            total_ratings=d.total_ratings or 0,
            phone=d.phone,
            profile_image=d.profile_image,
            description=d.description,
            consultation_fee=d.consultation_fee,
            examination_fee=d.examination_fee,
            working_hours=d.working_hours,
        ))
    
    # Get all verified pharmacies
    pharm_query = pharmacies_db.query(Pharmacy).filter(Pharmacy.is_verified == True)
    if city:
        pharm_query = pharm_query.filter(Pharmacy.city == city)
    pharmacies = pharm_query.all()
    
    for p in pharmacies:
        providers.append(MapProvider(
            id=p.id,
            type="pharmacy",
            name=p.name,
            specialty=None,
            address=p.address,
            latitude=p.latitude,
            longitude=p.longitude,
            rating=p.rating or 0.0,
            total_ratings=p.total_ratings or 0,
            phone=p.phone,
            profile_image=p.profile_image,
            description=None,
            delivery_available=p.delivery_available,
            working_hours=p.working_hours,
        ))
    
    # Get all verified teachers
    teachers_query = teachers_db.query(Teacher).join(Subject, isouter=True).filter(Teacher.is_verified == True)
    
    if city:
        teachers_query = teachers_query.filter(Teacher.city == city)
    
    # Apply teacher name filter
    if teacher_name:
        teachers_query = teachers_query.filter(
            Teacher.name.ilike(f"%{teacher_name}%")
        )
    
    # Apply subject filter
    if subject_id:
        teachers_query = teachers_query.filter(
            Teacher.subject_id == subject_id
        )
    
    teachers = teachers_query.all()
    
    for t in teachers:
        providers.append(MapProvider(
            id=t.id,
            type="teacher",
            name=t.name,
            specialty=t.subject.name_ar if t.subject else None,
            address=t.address,
            latitude=t.latitude,
            longitude=t.longitude,
            rating=t.rating or 0.0,
            total_ratings=t.total_ratings or 0,
            phone=t.phone,
            profile_image=t.profile_image,
            description=t.description,
            whatsapp=t.whatsapp,
            pricing=[{"grade_name": p.grade_name, "price": p.price} for p in t.pricing] if t.pricing else []
        ))
    
    return AllProvidersResponse(
        providers=providers,
        total=len(providers),
        doctors_count=len(doctors),
        pharmacies_count=len(pharmacies),
        teachers_count=len(teachers)
    )

def to_search_result(entity, type_str: str) -> SearchResult:
    """Helper to convert entity to SearchResult"""
    specialty = None
    if type_str == "doctor" and entity.specialty:
        specialty = entity.specialty.name_ar
    elif type_str == "teacher" and entity.subject:
        specialty = entity.subject.name_ar
        
    return SearchResult(
        id=entity.id,
        type=type_str,
        name=entity.name,
        specialty=specialty,
        address=entity.address,
        latitude=entity.latitude,
        longitude=entity.longitude,
        rating=entity.rating or 0.0,
        total_ratings=entity.total_ratings or 0,
        phone=entity.phone,
        profile_image=entity.profile_image,
        description=getattr(entity, 'description', None)
    )

@router.get("/", response_model=SearchResponse)
async def unified_search(
    q: str = Query(..., min_length=1),
    city: Optional[str] = Query(default=None),
    type: str = Query(default="all"),
    sort: str = Query(default="rating"),  # rating, price_asc, price_desc
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_rating: Optional[float] = None,
    doctors_db: Session = Depends(get_doctors_db),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    teachers_db: Session = Depends(get_teachers_db)
):
    """
    Unified search with advanced filters
    """
    results = []
    
    # Search doctors
    if type in ["all", "doctor"]:
        query = doctors_db.query(Doctor).join(Specialty, isouter=True).filter(
            Doctor.is_verified == True,
            or_(
                Doctor.name.ilike(f"%{q}%"),
                Specialty.name_ar.ilike(f"%{q}%"),
                Specialty.name_en.ilike(f"%{q}%")
            )
        )
        if city:
             query = query.filter(Doctor.city == city)
             
        if min_price is not None:
             query = query.filter(Doctor.examination_fee >= min_price)
        if max_price is not None:
             query = query.filter(Doctor.examination_fee <= max_price)
        if min_rating is not None:
             query = query.filter(Doctor.rating >= min_rating)

        doctors = query.all()
        results.extend([to_search_result(d, "doctor") for d in doctors])
    
    # Search pharmacies
    if type in ["all", "pharmacy"]:
        query = pharmacies_db.query(Pharmacy).filter(
            Pharmacy.is_verified == True,
            Pharmacy.name.ilike(f"%{q}%")
        )
        if city:
             query = query.filter(Pharmacy.city == city)
             
        if min_rating is not None:
             query = query.filter(Pharmacy.rating >= min_rating)
             
        pharmacies = query.all()
        results.extend([to_search_result(p, "pharmacy") for p in pharmacies])
    
    # Search teachers
    if type in ["all", "teacher"]:
        query = teachers_db.query(Teacher).join(Subject, isouter=True).filter(
            Teacher.is_verified == True,
            or_(
                Teacher.name.ilike(f"%{q}%"),
                Subject.name_ar.ilike(f"%{q}%"),
                Subject.name_en.ilike(f"%{q}%")
            )
        )
        if city:
             query = query.filter(Teacher.city == city)
             
        if min_rating is not None:
             query = query.filter(Teacher.rating >= min_rating)
             
        teachers = query.all()
        results.extend([to_search_result(t, "teacher") for t in teachers])
    
    # Sort
    if sort == "rating":
        results.sort(key=lambda x: x.rating, reverse=True)
    elif sort == "price_asc" and type == "doctor":
         # Only doctors have base fee in this context mainly
         pass 

    return SearchResponse(results=results, total=len(results))

