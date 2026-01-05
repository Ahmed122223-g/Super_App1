"""
Jiwar Backend - Pharmacies Router
Using separate Pharmacies database
"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_pharmacies_db
from app.models import Pharmacy, Medicine, User, UserType
from app.schemas.pharmacy import (
    PharmacyResponse,
    PharmacyListResponse,
    PharmacyMapPin,
    PharmacyUpdateRequest,
    MedicineCreate,
    MedicineUpdate,
    MedicineResponse,
    MedicineSearchResult,
    MedicineSearchResponse
)
from app.dependencies import require_user_type

router = APIRouter()


def build_pharmacy_response(pharmacy: Pharmacy) -> PharmacyResponse:
    return PharmacyResponse(
        id=pharmacy.id,
        name=pharmacy.name,
        address=pharmacy.address,
        latitude=pharmacy.latitude,
        longitude=pharmacy.longitude,
        city=pharmacy.city,
        governorate=pharmacy.governorate,
        phone=pharmacy.phone,
        working_hours=pharmacy.working_hours,
        rating=pharmacy.rating,
        total_ratings=pharmacy.total_ratings,
        is_verified=pharmacy.is_verified
    )


@router.get("/", response_model=PharmacyListResponse)
async def list_pharmacies(
    city: str = Query(default="الواسطي"),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """List all pharmacies in a city"""
    pharmacies = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.city == city,
        Pharmacy.is_verified == True
    ).all()
    
    return PharmacyListResponse(
        pharmacies=[build_pharmacy_response(p) for p in pharmacies],
        total=len(pharmacies)
    )


@router.get("/search", response_model=List[PharmacyMapPin])
async def search_pharmacies(
    q: str = Query(..., min_length=1),
    city: str = Query(default="الواسطي"),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Search pharmacies by name"""
    pharmacies = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.city == city,
        Pharmacy.is_verified == True,
        Pharmacy.name.ilike(f"%{q}%")
    ).all()
    
    return [
        PharmacyMapPin(
            id=p.id,
            name=p.name,
            address=p.address,
            latitude=p.latitude,
            longitude=p.longitude,
            rating=p.rating
        )
        for p in pharmacies
    ]


@router.get("/pins", response_model=List[PharmacyMapPin])
async def get_pharmacy_pins(
    city: str = Query(default="الواسطي"),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Get all pharmacy pins for map"""
    pharmacies = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.city == city,
        Pharmacy.is_verified == True
    ).all()
    
    return [
        PharmacyMapPin(
            id=p.id,
            name=p.name,
            address=p.address,
            latitude=p.latitude,
            longitude=p.longitude,
            rating=p.rating
        )
        for p in pharmacies
    ]


@router.get("/{pharmacy_id}", response_model=PharmacyResponse)
async def get_pharmacy(
    pharmacy_id: int,
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Get pharmacy details"""
    pharmacy = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.id == pharmacy_id
    ).first()
    
    if not pharmacy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "PHARMACY_NOT_FOUND", "message": "Pharmacy not found"}
        )
    
    return build_pharmacy_response(pharmacy)


@router.put("/me", response_model=PharmacyResponse)
async def update_my_pharmacy_profile(
    request: PharmacyUpdateRequest,
    current_user: User = Depends(require_user_type(UserType.PHARMACY)),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Update current pharmacy's profile"""
    pharmacy = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.owner_id == current_user.id
    ).first()
    
    if not pharmacy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "PHARMACY_PROFILE_NOT_FOUND", "message": "Pharmacy profile not found"}
        )
    
    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(pharmacy, field, value)
    
    pharmacies_db.commit()
    pharmacies_db.refresh(pharmacy)
    
    return build_pharmacy_response(pharmacy)


# ============================================
# MEDICINE MANAGEMENT
# ============================================

@router.get("/medicines/search", response_model=MedicineSearchResponse)
async def search_medicines(
    q: str = Query(..., min_length=1),
    city: str = Query(default="الواسطي"),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Search for medicines across all pharmacies"""
    medicines = pharmacies_db.query(Medicine).join(Pharmacy).filter(
        Pharmacy.city == city,
        Pharmacy.is_verified == True,
        Medicine.available == True,
        Medicine.name.ilike(f"%{q}%")
    ).all()
    
    results = []
    for m in medicines:
        results.append(MedicineSearchResult(
            medicine=MedicineResponse.model_validate(m),
            pharmacy_name=m.pharmacy.name,
            pharmacy_address=m.pharmacy.address,
            pharmacy_phone=m.pharmacy.phone,
            latitude=m.pharmacy.latitude,
            longitude=m.pharmacy.longitude
        ))
    
    return MedicineSearchResponse(results=results, total=len(results))


@router.get("/{pharmacy_id}/medicines", response_model=List[MedicineResponse])
async def get_pharmacy_medicines(
    pharmacy_id: int,
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Get all medicines in a pharmacy"""
    pharmacy = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.id == pharmacy_id
    ).first()
    
    if not pharmacy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "PHARMACY_NOT_FOUND", "message": "Pharmacy not found"}
        )
    
    medicines = pharmacies_db.query(Medicine).filter(
        Medicine.pharmacy_id == pharmacy_id
    ).all()
    
    return [MedicineResponse.model_validate(m) for m in medicines]


@router.post("/me/medicines", response_model=MedicineResponse, status_code=status.HTTP_201_CREATED)
async def add_medicine(
    request: MedicineCreate,
    current_user: User = Depends(require_user_type(UserType.PHARMACY)),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Add a new medicine to my pharmacy"""
    pharmacy = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.owner_id == current_user.id
    ).first()
    
    if not pharmacy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "PHARMACY_NOT_FOUND", "message": "Pharmacy not found"}
        )
    
    medicine = Medicine(
        pharmacy_id=pharmacy.id,
        name=request.name,
        price=request.price,
        quantity=request.quantity,
        available=request.available
    )
    
    pharmacies_db.add(medicine)
    pharmacies_db.commit()
    pharmacies_db.refresh(medicine)
    
    return MedicineResponse.model_validate(medicine)


@router.put("/me/medicines/{medicine_id}", response_model=MedicineResponse)
async def update_medicine(
    medicine_id: int,
    request: MedicineUpdate,
    current_user: User = Depends(require_user_type(UserType.PHARMACY)),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Update a medicine in my pharmacy"""
    pharmacy = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.owner_id == current_user.id
    ).first()
    
    if not pharmacy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "PHARMACY_NOT_FOUND", "message": "Pharmacy not found"}
        )
    
    medicine = pharmacies_db.query(Medicine).filter(
        Medicine.id == medicine_id,
        Medicine.pharmacy_id == pharmacy.id
    ).first()
    
    if not medicine:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "MEDICINE_NOT_FOUND", "message": "Medicine not found"}
        )
    
    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(medicine, field, value)
    
    pharmacies_db.commit()
    pharmacies_db.refresh(medicine)
    
    return MedicineResponse.model_validate(medicine)


@router.delete("/me/medicines/{medicine_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_medicine(
    medicine_id: int,
    current_user: User = Depends(require_user_type(UserType.PHARMACY)),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Delete a medicine from my pharmacy"""
    pharmacy = pharmacies_db.query(Pharmacy).filter(
        Pharmacy.owner_id == current_user.id
    ).first()
    
    if not pharmacy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "PHARMACY_NOT_FOUND", "message": "Pharmacy not found"}
        )
    
    medicine = pharmacies_db.query(Medicine).filter(
        Medicine.id == medicine_id,
        Medicine.pharmacy_id == pharmacy.id
    ).first()
    
    if not medicine:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "MEDICINE_NOT_FOUND", "message": "Medicine not found"}
        )
    
    pharmacies_db.delete(medicine)
    pharmacies_db.commit()
