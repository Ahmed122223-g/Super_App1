from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel

from app.core.database import get_users_db
from app.core.security import get_current_user
from app.models.user import User, Address

router = APIRouter()

# --- Schemas ---

# --- Schemas ---

class AddressBase(BaseModel):
    label: str
    contact_name: str
    contact_phone: str
    address: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    is_default: bool = False

class AddressCreate(AddressBase):
    pass

class AddressUpdate(AddressBase):
    pass

class AddressResponse(AddressBase):
    id: int
    user_id: int
    
    class Config:
        from_attributes = True

# --- Endpoints ---

@router.get("/", response_model=List[AddressResponse])
def get_my_addresses(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_users_db)
):
    """Get all saved addresses for the current user"""
    return db.query(Address).filter(Address.user_id == current_user.id).all()

@router.post("/", response_model=AddressResponse)
def create_address(
    address: AddressCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_users_db)
):
    """Save a new address"""
    # If set as default, unset others
    if address.is_default:
        db.query(Address).filter(Address.user_id == current_user.id).update({Address.is_default: False})
        
    new_address = Address(
        user_id=current_user.id,
        label=address.label,
        contact_name=address.contact_name,
        contact_phone=address.contact_phone,
        address=address.address,
        latitude=address.latitude,
        longitude=address.longitude,
        is_default=address.is_default
    )
    db.add(new_address)
    db.commit()
    db.refresh(new_address)
    return new_address

@router.put("/{address_id}", response_model=AddressResponse)
def update_address(
    address_id: int,
    address_update: AddressUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_users_db)
):
    """Update an existing address"""
    existing_address = db.query(Address).filter(Address.id == address_id, Address.user_id == current_user.id).first()
    if not existing_address:
        raise HTTPException(status_code=404, detail="Address not found")
        
    # If set as default, unset others
    if address_update.is_default:
        db.query(Address).filter(Address.user_id == current_user.id).update({Address.is_default: False})
        
    existing_address.label = address_update.label
    existing_address.contact_name = address_update.contact_name
    existing_address.contact_phone = address_update.contact_phone
    existing_address.address = address_update.address
    existing_address.latitude = address_update.latitude
    existing_address.longitude = address_update.longitude
    existing_address.is_default = address_update.is_default
    
    db.commit()
    db.refresh(existing_address)
    return existing_address

@router.delete("/{address_id}")
def delete_address(
    address_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_users_db)
):
    """Delete an address"""
    existing_address = db.query(Address).filter(Address.id == address_id, Address.user_id == current_user.id).first()
    if not existing_address:
        raise HTTPException(status_code=404, detail="Address not found")
        
    db.delete(existing_address)
    db.commit()
    return {"success": True, "message": "Address deleted"}
