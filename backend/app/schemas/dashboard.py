from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime
from app.models.reservations import ReservationStatus
from app.models.orders import OrderStatus

# --- Generic Profile Update Schemas ---

class ProfileUpdateResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class DoctorProfileUpdate(BaseModel):
    consultation_fee: Optional[float] = None  # سعر الاستشارة
    examination_fee: Optional[float] = None   # سعر الكشف
    profile_image: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    working_hours: Optional[Any] = None

class PharmacyProfileUpdate(BaseModel):
    delivery_available: Optional[bool] = None
    profile_image: Optional[str] = None
    working_hours: Optional[Any] = None
    address: Optional[str] = None
    phone: Optional[str] = None

class TeacherProfileUpdate(BaseModel):
    profile_image: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    pricing: Optional[List[dict]] = None # List of {grade_name, price}

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None

# --- Reservation Schemas ---

class ReservationResponse(BaseModel):
    id: int
    user_id: int
    patient_name: Optional[str] = None # For Doctor
    student_name: Optional[str] = None # For Teacher
    phone: str
    date: datetime
    status: str
    notes: Optional[str] = None
    
    class Config:
        from_attributes = True

class ReservationAction(BaseModel):
    action: str # "accept", "reject", "complete"
    reason: Optional[str] = None # For rejection
    schedule: Optional[Any] = None # For teacher acceptance (JSON)

# --- Order Schemas ---

class OrderItem(BaseModel):
    name: str
    quantity: int = 1
    notes: Optional[str] = None

class OrderResponse(BaseModel):
    id: int
    user_id: int
    customer_name: str
    customer_phone: str
    customer_address: str
    items: Optional[Any] = None
    items_text: Optional[str] = None
    prescription_image: Optional[str] = None
    total_price: Optional[float] = None
    delivery_fee: Optional[float] = None
    estimated_time: Optional[str] = None
    notes: Optional[str] = None
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class OrderPriceUpdate(BaseModel):
    total_price: float
    delivery_fee: float = 0.0
    estimated_time: str
    notes: Optional[str] = None
    items_availability: Optional[dict] = None # Map item name to boolean

class OrderUserAction(BaseModel):
    action: str # "accept", "reject"



# --- Booking Request (User creates reservation) ---

class BookingRequest(BaseModel):
    provider_id: int
    provider_type: str  # "doctor" or "teacher"
    booking_type: str   # "examination" or "consultation" (for doctors)
    visit_date: datetime
    patient_name: str
    patient_phone: str
    notes: Optional[str] = None


# --- User-facing Reservation Response (includes provider info) ---

class UserReservationResponse(BaseModel):
    id: int
    provider_id: int
    provider_type: str  # "doctor" or "teacher"
    provider_name: str
    specialty: Optional[str] = None  # For doctors
    subject: Optional[str] = None    # For teachers
    booking_type: Optional[str] = None
    visit_date: datetime
    status: str
    notes: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True


# --- Create Order Request (User creates pharmacy order) ---

class CreateOrderRequest(BaseModel):
    pharmacy_id: int
    items_text: Optional[str] = None         # Text description of medications
    prescription_image: Optional[str] = None  # Base64 or URL of prescription image
    customer_name: str
    customer_phone: str
    customer_address: str
    notes: Optional[str] = None


# --- User-facing Order Response (includes pharmacy info) ---

class UserOrderResponse(BaseModel):
    id: int
    pharmacy_id: int
    pharmacy_name: str
    items_text: Optional[str] = None
    prescription_image: Optional[str] = None
    total_price: Optional[float] = None
    delivery_fee: Optional[float] = None
    estimated_time: Optional[str] = None
    notes: Optional[str] = None
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

