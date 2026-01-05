"""
Jiwar Backend - Authentication Router
Handles user registration, login, and token management
Using multiple databases for different entities
"""
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from datetime import datetime

from app.core.database import (
    get_users_db, get_doctors_db, 
    get_pharmacies_db, get_codes_db,
    get_teachers_db
)
from app.core.limiter import limiter
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_registration_code,
    mark_code_as_used,
    get_current_user
)
from app.models import User, UserType, Doctor, Pharmacy, Specialty
from app.models.teacher import Teacher
from app.models.reservations import DoctorReservation, TeacherReservation
from app.models.orders import PharmacyOrder
from app.core.database import get_users_db, get_doctors_db, get_teachers_db, get_pharmacies_db
from datetime import datetime
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    TokenResponse,
    RefreshTokenRequest,
    DoctorRegisterFull,
    PharmacyRegisterFull,
    TeacherRegisterFull,
    UserResponse,
    ChangePasswordRequest
)
from app.schemas.common import MessageResponse

router = APIRouter(tags=["Authentication"])


# ============================================
# USER REGISTRATION & LOGIN
# ============================================

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def register_user(
    request: Request,
    body: UserRegisterRequest,
    users_db: Session = Depends(get_users_db)
):
    """
    Register a new regular user (customer)
    """
    existing_user = users_db.query(User).filter(User.email == body.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error_code": "EMAIL_ALREADY_EXISTS", "message": "Email already registered"}
        )
    
    user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        name=body.name,
        phone=body.phone,
        age=body.age,
        address=body.address,
        user_type=UserType.CUSTOMER
    )
    
    users_db.add(user)
    users_db.commit()
    users_db.refresh(user)
    
    access_token = create_access_token(data={"sub": str(user.id), "v": user.token_version})
    refresh_token = create_refresh_token(data={"sub": str(user.id), "v": user.token_version})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_type=user.user_type.value,
        user_id=user.id,
        name=user.name
    )


@router.post("/login", response_model=TokenResponse)
@limiter.limit("10/minute")
async def login_user(
    request: Request,
    body: UserLoginRequest,
    users_db: Session = Depends(get_users_db)
):
    """
    Login user with email and password
    Works for all user types - returns appropriate user_type and redirects accordingly
    """
    user = users_db.query(User).filter(User.email == body.email).first()
    
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_CREDENTIALS", "message": "Invalid email or password"}
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error_code": "USER_INACTIVE", "message": "Account is deactivated"}
        )
    
    user.token_version += 1
    users_db.commit()
    
    access_token = create_access_token(data={"sub": str(user.id), "v": user.token_version})
    refresh_token = create_refresh_token(data={"sub": str(user.id), "v": user.token_version})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_type=user.user_type.value,
        user_id=user.id,
        name=user.name
    )


@router.post("/refresh", response_model=TokenResponse)
@limiter.limit("10/minute")
async def refresh_token(
    request: Request,
    body: RefreshTokenRequest,
    users_db: Session = Depends(get_users_db)
):
    """
    Refresh access token using refresh token
    """
    payload = decode_token(body.refresh_token)
    
    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_REFRESH_TOKEN", "message": "Invalid refresh token"}
        )
    
    user_id = payload.get("sub")
    user = users_db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "USER_NOT_FOUND", "message": "User not found"}
        )
    
    token_version = payload.get("v")
    if token_version is not None and token_version != user.token_version:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "SESSION_EXPIRED", "message": "Session expired, please login again"}
        )
    
    access_token = create_access_token(data={"sub": str(user.id), "v": user.token_version})
    new_refresh_token = create_refresh_token(data={"sub": str(user.id), "v": user.token_version})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        user_type=user.user_type.value,
        user_id=user.id,
        name=user.name
    )


# ============================================
# ADMIN REGISTRATION CODE VERIFICATION
# ============================================

from pydantic import BaseModel

class VerifyCodeRequest(BaseModel):
    code: str
    type: str

@router.post("/register/verify-code", response_model=MessageResponse)
@limiter.limit("10/minute")
async def verify_admin_registration_code(
    request: Request,
    body: VerifyCodeRequest,
    codes_db: Session = Depends(get_codes_db)
):
    """
    Step 1: Verify admin registration code from database
    
    type: 'doctor', 'pharmacy', 'restaurant', 'company', 'engineer', 'mechanic'
    """
    valid_types = ["doctor", "pharmacy", "teacher", "restaurant", "company", "engineer", "mechanic"]
    
    if body.type not in valid_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "INVALID_ADMIN_TYPE", "message": "Invalid admin type"}
        )
    
    if body.type not in ["doctor", "pharmacy", "teacher"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "FEATURE_COMING_SOON", "message": "This feature will be available soon"}
        )
    
    if not verify_registration_code(body.code, body.type, codes_db):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_REGISTRATION_CODE", "message": "Invalid or already used registration code"}
        )
    
    return MessageResponse(message="Code verified successfully")


# ============================================
# DOCTOR REGISTRATION
# ============================================

@router.post("/register/doctor", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
async def register_doctor(
    request: Request,
    body: DoctorRegisterFull,
    users_db: Session = Depends(get_users_db),
    doctors_db: Session = Depends(get_doctors_db),
    codes_db: Session = Depends(get_codes_db)
):
    """
    Register a new doctor (full registration)
    
    Requires valid registration code from developer
    """
    if not verify_registration_code(body.registration_code, "doctor", codes_db):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_REGISTRATION_CODE", "message": "Invalid or already used registration code"}
        )
    
    existing_user = users_db.query(User).filter(User.email == body.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error_code": "EMAIL_ALREADY_EXISTS", "message": "Email already registered"}
        )
    
    specialty = doctors_db.query(Specialty).filter(Specialty.id == body.specialty_id).first()
    if not specialty:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "SPECIALTY_NOT_FOUND", "message": "Specialty not found"}
        )
    
    user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        name=body.name,
        phone=body.phone,
        user_type=UserType.DOCTOR
    )
    
    users_db.add(user)
    users_db.flush()  
    
    doctor = Doctor(
        user_id=user.id,
        name=body.name,
        description=body.description,
        specialty_id=body.specialty_id,
        address=body.address,
        latitude=body.latitude,
        longitude=body.longitude,
        phone=body.phone,
        consultation_fee=body.consultation_fee,
        is_verified=True
    )
    
    doctors_db.add(doctor)
    doctors_db.flush()
    
    user.profile_id = doctor.id
    
    mark_code_as_used(body.registration_code, "doctor", body.email, codes_db)
    
    users_db.commit()
    doctors_db.commit()
    
    access_token = create_access_token(data={"sub": str(user.id), "v": user.token_version})
    refresh_token = create_refresh_token(data={"sub": str(user.id), "v": user.token_version})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_type=user.user_type.value,
        user_id=user.id,
        name=user.name
    )


# ============================================
# PHARMACY REGISTRATION
# ============================================

@router.post("/register/pharmacy", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
async def register_pharmacy(
    request: Request,
    body: PharmacyRegisterFull,
    users_db: Session = Depends(get_users_db),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    codes_db: Session = Depends(get_codes_db)
):
    """
    Register a new pharmacy (full registration)
    
    Requires valid registration code from developer
    """
    if not verify_registration_code(body.registration_code, "pharmacy", codes_db):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_REGISTRATION_CODE", "message": "Invalid or already used registration code"}
        )
    
    existing_user = users_db.query(User).filter(User.email == body.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error_code": "EMAIL_ALREADY_EXISTS", "message": "Email already registered"}
        )
    
    user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        name=body.name,
        phone=body.phone,
        user_type=UserType.PHARMACY
    )
    
    users_db.add(user)
    users_db.flush()  
    
    pharmacy = Pharmacy(
        owner_id=user.id,
        name=body.name,
        address=body.address,
        latitude=body.latitude,
        longitude=body.longitude,
        phone=body.phone,
        is_verified=True
    )
    
    pharmacies_db.add(pharmacy)
    pharmacies_db.flush()
    
    user.profile_id = pharmacy.id
    
    mark_code_as_used(body.registration_code, "pharmacy", body.email, codes_db)
    
    users_db.commit()
    pharmacies_db.commit()
    
    access_token = create_access_token(data={"sub": str(user.id), "v": user.token_version})
    refresh_token = create_refresh_token(data={"sub": str(user.id), "v": user.token_version})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_type=user.user_type.value,
        user_id=user.id,
        name=user.name
    )


# ============================================
# TEACHER REGISTRATION
# ============================================

@router.post("/register/teacher", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("3/minute")
async def register_teacher(
    request: Request,
    body: TeacherRegisterFull,
    users_db: Session = Depends(get_users_db),
    teachers_db: Session = Depends(get_teachers_db),
    codes_db: Session = Depends(get_codes_db)
):
    """
    Register a new teacher (full registration)
    
    Requires valid registration code from developer
    """
    from app.models.teacher import Subject, TeacherPricing
    
    if not verify_registration_code(body.registration_code, "teacher", codes_db):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_REGISTRATION_CODE", "message": "Invalid or already used registration code"}
        )
    
    existing_user = users_db.query(User).filter(User.email == body.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"error_code": "EMAIL_ALREADY_EXISTS", "message": "Email already registered"}
        )
    
    subject = teachers_db.query(Subject).filter(Subject.id == body.subject_id).first()
    if not subject:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error_code": "SUBJECT_NOT_FOUND", "message": "Subject not found"}
        )
    
    user = User(
        email=body.email,
        password_hash=hash_password(body.password),
        name=body.name,
        phone=body.phone,
        user_type=UserType.TEACHER
    )
    
    users_db.add(user)
    users_db.flush()  
    
    teacher = Teacher(
        user_id=user.id,
        name=body.name,
        subject_id=body.subject_id,
        address=body.address,
        latitude=body.latitude,
        longitude=body.longitude,
        phone=body.phone,
        is_verified=True
    )
    
    teachers_db.add(teacher)
    teachers_db.flush()
    
    for price_item in body.pricing:
        pricing = TeacherPricing(
            teacher_id=teacher.id,
            grade_name=price_item.grade_name,
            price=price_item.price
        )
        teachers_db.add(pricing)
    
    user.profile_id = teacher.id
    
    mark_code_as_used(body.registration_code, "teacher", body.email, codes_db)
    
    users_db.commit()
    teachers_db.commit()
    
    access_token = create_access_token(data={"sub": str(user.id), "v": user.token_version})
    refresh_token = create_refresh_token(data={"sub": str(user.id), "v": user.token_version})
    
    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user_type=user.user_type.value,
        user_id=user.id,
        name=user.name
    )


@router.post("/change-password", response_model=MessageResponse)
async def change_password(
    request: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    users_db: Session = Depends(get_users_db)
):
    """
    Change user password
    """
    if not verify_password(request.old_password, current_user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"error_code": "INVALID_PASSWORD", "message": "Incorrect old password"}
        )
    
    current_user.password_hash = hash_password(request.new_password)
    users_db.commit()
    
    return {"message": "Password changed successfully"}


@router.delete("/delete-account")
def delete_account(
    email: str,
    current_user: User = Depends(get_current_user),
    users_db: Session = Depends(get_users_db),
    doctors_db: Session = Depends(get_doctors_db),
    teachers_db: Session = Depends(get_teachers_db),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """
    Permanently delete account (Soft delete + cleanup).
    Keeps ratings but anonymizes user info.
    Deletes reservations and orders.
    """
    if email != current_user.email:
         raise HTTPException(status_code=400, detail="البريد الإلكتروني غير صحيح")
    
    doctors_db.query(DoctorReservation).filter(DoctorReservation.user_id == current_user.id).delete()
    doctors_db.commit()

    teachers_db.query(TeacherReservation).filter(TeacherReservation.user_id == current_user.id).delete()
    teachers_db.commit()
    
    pharmacies_db.query(PharmacyOrder).filter(PharmacyOrder.user_id == current_user.id).delete()
    pharmacies_db.commit()
    
    timestamp = int(datetime.utcnow().timestamp())
    current_user.name = "Deleted User"
    current_user.email = f"deleted_{current_user.id}_{timestamp}@jiwar.app"
    current_user.phone = None
    current_user.address = None
    current_user.password_hash = "deleted_account_hash"
    current_user.is_active = False
    
    users_db.commit()
    
    return {"message": "Account deleted successfully"}


# ==========================================
# FCM Token Registration
# ==========================================

@router.post("/fcm-token")
def register_fcm_token(
    token: str,
    current_user: User = Depends(get_current_user),
    users_db: Session = Depends(get_users_db)
):
    """
    Register or update FCM token for push notifications.
    Called when app starts or token refreshes.
    """
    if not token or len(token) < 10:
        raise HTTPException(status_code=400, detail="Invalid FCM token")
    
    current_user.fcm_token = token
    users_db.commit()
    
    return {"success": True, "message": "FCM token registered"}


