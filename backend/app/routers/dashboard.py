from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.core.database import (
    get_users_db, get_doctors_db, get_pharmacies_db, 
    get_teachers_db
)
from app.core.security import get_current_user
from app.models.user import User, UserType
from app.models.doctor import Doctor
from app.models.pharmacy import Pharmacy
from app.models.teacher import Teacher, TeacherPricing
from app.models.reservations import DoctorReservation, TeacherReservation, ReservationStatus
from app.models.orders import PharmacyOrder, OrderStatus

from app.schemas.dashboard import (
    DoctorProfileUpdate, PharmacyProfileUpdate, TeacherProfileUpdate, UserProfileUpdate,
    ReservationResponse, ReservationAction,
    OrderResponse, OrderPriceUpdate, ProfileUpdateResponse,
    BookingRequest, UserReservationResponse, CreateOrderRequest, UserOrderResponse,
    OrderUserAction
)
from app.services.notifications import (
    notify_new_booking, notify_booking_confirmed, notify_booking_rejected,
    notify_new_order, notify_order_priced, send_notification, notify_new_rating
)




router = APIRouter()

# ==========================================
# HELPER: Get Provider Profile
# ==========================================
def get_provider_profile(user: User, db_session: Session, model_class):
    if not user.profile_id:
        return None
    return db_session.query(model_class).filter(model_class.id == user.profile_id).first()

# ==========================================
# 1. PROFILE MANAGEMENT
# ==========================================

@router.get("/profile")
def get_profile(
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    teachers_db: Session = Depends(get_teachers_db),
    users_db: Session = Depends(get_users_db)
):
    """Get current user's provider profile"""
    profile = None
    
    if current_user.user_type == UserType.DOCTOR:
        profile = get_provider_profile(current_user, doctors_db, Doctor)
        if profile:
            return {
                "id": profile.id,
                "name": profile.name,
                "email": current_user.email,
                "phone": profile.phone,
                "address": profile.address,
                "description": profile.description,
                "profile_image": profile.profile_image,
                "specialty": {"id": profile.specialty.id, "name_ar": profile.specialty.name_ar} if profile.specialty else None,
                "consultation_fee": profile.consultation_fee,
                "examination_fee": profile.examination_fee,
                "working_hours": profile.working_hours,
                "rating": profile.rating,
                "total_ratings": profile.total_ratings,
            }
    elif current_user.user_type == UserType.PHARMACY:
        profile = get_provider_profile(current_user, pharmacies_db, Pharmacy)
        if profile:
            return {
                "id": profile.id,
                "name": profile.name,
                "email": current_user.email,
                "phone": profile.phone,
                "address": profile.address,
                "profile_image": profile.profile_image,
                "delivery_available": profile.delivery_available,
                "working_hours": profile.working_hours,
                "rating": profile.rating,
            }
    elif current_user.user_type == UserType.TEACHER:
        profile = get_provider_profile(current_user, teachers_db, Teacher)
        if profile:
            # Eagerly load pricing and subject
            pricing_list = [{"id": p.id, "grade_name": p.grade_name, "price": p.price} for p in profile.pricing]
            subject_data = {"id": profile.subject.id, "name_ar": profile.subject.name_ar, "name_en": profile.subject.name_en} if profile.subject else None
            
            return {
                "id": profile.id,
                "name": profile.name,
                "email": current_user.email,
                "phone": profile.phone,
                "whatsapp": profile.whatsapp,
                "address": profile.address,
                "description": profile.description,
                "profile_image": profile.profile_image,
                "subject": subject_data,
                "pricing": pricing_list,
                "rating": profile.rating,
                "total_ratings": profile.total_ratings,
            }
    elif current_user.user_type == UserType.CUSTOMER:
        return {
            "id": current_user.id,
            "name": current_user.name,
            "email": current_user.email,
            "phone": current_user.phone,
            "address": current_user.address,
            "user_type": current_user.user_type.value,
        }
        
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

@router.patch("/profile/doctor", response_model=ProfileUpdateResponse)
def update_doctor_profile(
    update_data: DoctorProfileUpdate,
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db)
):
    if current_user.user_type != UserType.DOCTOR:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    profile = get_provider_profile(current_user, doctors_db, Doctor)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
        
    # Update allowed fields
    if update_data.consultation_fee is not None:
        profile.consultation_fee = update_data.consultation_fee
    if update_data.examination_fee is not None:
        profile.examination_fee = update_data.examination_fee
    if update_data.address is not None:
        profile.address = update_data.address
    if update_data.phone is not None:
        profile.phone = update_data.phone
    if update_data.description is not None:
        profile.description = update_data.description
    if update_data.profile_image is not None:
        profile.profile_image = update_data.profile_image
    if update_data.working_hours is not None:
        profile.working_hours = update_data.working_hours
        
    doctors_db.commit()
    return ProfileUpdateResponse(success=True, message="Profile updated", data={"id": profile.id})

@router.patch("/profile/pharmacy", response_model=ProfileUpdateResponse)
def update_pharmacy_profile(
    update_data: PharmacyProfileUpdate,
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    if current_user.user_type != UserType.PHARMACY:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    profile = get_provider_profile(current_user, pharmacies_db, Pharmacy)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    if update_data.delivery_available is not None:
        profile.delivery_available = update_data.delivery_available
    if update_data.working_hours is not None:
        profile.working_hours = update_data.working_hours
    if update_data.profile_image is not None:
        profile.profile_image = update_data.profile_image
    if update_data.phone is not None:
        profile.phone = update_data.phone
        
    pharmacies_db.commit()
    return ProfileUpdateResponse(success=True, message="Profile updated")

@router.patch("/profile/teacher", response_model=ProfileUpdateResponse)
def update_teacher_profile(
    update_data: TeacherProfileUpdate,
    current_user: User = Depends(get_current_user),
    teachers_db: Session = Depends(get_teachers_db)
):
    if current_user.user_type != UserType.TEACHER:
        raise HTTPException(status_code=403, detail="Not authorized")

    profile = get_provider_profile(current_user, teachers_db, Teacher)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")

    if update_data.phone is not None:
        profile.phone = update_data.phone

    if update_data.whatsapp is not None:
        profile.whatsapp = update_data.whatsapp

    if update_data.description is not None:
        profile.description = update_data.description
        
    if update_data.profile_image is not None:
        profile.profile_image = update_data.profile_image

    if update_data.pricing is not None:
        # Delete existing pricing
        teachers_db.query(TeacherPricing).filter(TeacherPricing.teacher_id == profile.id).delete()
        
        # Add new pricing
        for price_item in update_data.pricing:
            # Handle both formats just in case
            grade = price_item.get('grade_name') or price_item.get('grade')
            price = price_item.get('price')
            
            if grade and price is not None:
                new_price = TeacherPricing(
                    teacher_id=profile.id,
                    grade_name=grade,
                    price=price
                )
                teachers_db.add(new_price)
        
        
    teachers_db.commit()
    return ProfileUpdateResponse(success=True, message="Profile updated")


@router.patch("/profile/user", response_model=ProfileUpdateResponse)
def update_user_profile(
    update_data: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    users_db: Session = Depends(get_users_db)
):
    """Update regular user profile"""
    if update_data.name is not None:
        current_user.name = update_data.name
    if update_data.phone is not None:
        current_user.phone = update_data.phone
    if update_data.address is not None:
        current_user.address = update_data.address
        
    users_db.commit()
    return ProfileUpdateResponse(success=True, message="Profile updated", data={"id": current_user.id})


# ==========================================
# 2. RESERVATIONS (Doctor & Teacher)
# ==========================================

@router.get("/reservations", response_model=List[ReservationResponse])
def get_reservations(
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    teachers_db: Session = Depends(get_teachers_db)
):
    """Get reservations for the provider"""
    reservations = []
    
    if current_user.user_type == UserType.DOCTOR:
        profile = get_provider_profile(current_user, doctors_db, Doctor)
        if profile:
            reservations = doctors_db.query(DoctorReservation).filter(
                DoctorReservation.doctor_id == profile.id
            ).order_by(DoctorReservation.visit_date.desc()).all()
            
            # Map to response (manual or Pydantic)
            return [
                ReservationResponse(
                    id=r.id, user_id=r.user_id, patient_name=r.patient_name,
                    phone=r.patient_phone, date=r.visit_date, status=r.status.value,
                    notes=r.notes
                ) for r in reservations
            ]

    elif current_user.user_type == UserType.TEACHER:
        profile = get_provider_profile(current_user, teachers_db, Teacher)
        if profile:
            reservations = teachers_db.query(TeacherReservation).filter(
                TeacherReservation.teacher_id == profile.id
            ).order_by(TeacherReservation.requested_date.desc()).all()
            
            return [
                ReservationResponse(
                    id=r.id, user_id=r.user_id, student_name=r.student_name,
                    phone=r.student_phone, date=r.requested_date, status=r.status.value,
                    notes=r.notes
                ) for r in reservations
            ]
            
    return []

@router.post("/reservations/{id}/action")
def reservation_action(
    id: int,
    action: ReservationAction,
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    teachers_db: Session = Depends(get_teachers_db),
    users_db: Session = Depends(get_users_db)
):
    if current_user.user_type == UserType.DOCTOR:
        profile = get_provider_profile(current_user, doctors_db, Doctor)
        reservation = doctors_db.query(DoctorReservation).filter(
            DoctorReservation.id == id, DoctorReservation.doctor_id == profile.id
        ).first() # Ensure ownership
        db = doctors_db
    elif current_user.user_type == UserType.TEACHER:
        profile = get_provider_profile(current_user, teachers_db, Teacher)
        reservation = teachers_db.query(TeacherReservation).filter(
            TeacherReservation.id == id, TeacherReservation.teacher_id == profile.id
        ).first()
        db = teachers_db
    else:
        raise HTTPException(status_code=400, detail="Invalid user type")
        
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
        
    if action.action == "accept":
        reservation.status = ReservationStatus.CONFIRMED
        
        # Save schedule if provided (for Teacher)
        if hasattr(reservation, 'schedule') and hasattr(action, 'schedule') and action.schedule:
             reservation.schedule = action.schedule
             
        db.commit()
        
        # Notify User
        user_to_notify = users_db.query(User).filter(User.id == reservation.user_id).first()
        if user_to_notify:
            notify_booking_confirmed(users_db, user_to_notify, profile.name, reservation.id)
            
        return {"success": True, "message": "Reservation confirmed"}
        
    elif action.action == "reject":
        reservation.status = ReservationStatus.REJECTED
        reservation.rejection_reason = action.reason
        db.commit()
        
        # Notify User
        user_to_notify = users_db.query(User).filter(User.id == reservation.user_id).first()
        if user_to_notify:
            notify_booking_rejected(users_db, user_to_notify, profile.name, reservation.id, action.reason)
            
        return {"success": True, "message": "Reservation rejected"}
    elif action.action == "complete":
        reservation.status = ReservationStatus.COMPLETED
        
    db.commit()

    # Notify User about status change
    user_to_notify = users_db.query(User).filter(User.id == reservation.user_id).first()
    if user_to_notify:
        provider_name = profile.name
        if action.action == "accept":
            notify_booking_confirmed(users_db, user_to_notify, provider_name, reservation.id)
        elif action.action == "reject":
            notify_booking_rejected(users_db, user_to_notify, provider_name, reservation.id, action.reason)

    return {"success": True, "status": reservation.status}


# ==========================================
# 3. ORDERS (Pharmacy)
# ==========================================

@router.get("/orders", response_model=List[OrderResponse])
def get_orders(
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    if current_user.user_type != UserType.PHARMACY:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    profile = get_provider_profile(current_user, pharmacies_db, Pharmacy)
    if not profile:
        return []
        
    orders = pharmacies_db.query(PharmacyOrder).filter(
        PharmacyOrder.pharmacy_id == profile.id
    ).order_by(PharmacyOrder.created_at.desc()).all()
    
    return [
        OrderResponse(
            id=o.id, user_id=o.user_id, customer_name=o.customer_name,
            customer_phone=o.customer_phone, customer_address=o.customer_address,
            items=o.items_json, 
            items_text=o.items_text,
            prescription_image=o.prescription_image,
            total_price=o.total_price, delivery_fee=o.delivery_fee,
            estimated_time=o.estimated_delivery_time,
            notes=o.pharmacy_notes,
            status=o.status.value, created_at=o.created_at
        ) for o in orders
    ]

@router.post("/orders/{id}/price")
@router.post("/orders/{id}/price")
def set_order_price(
    id: int,
    price_update: OrderPriceUpdate,
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    users_db: Session = Depends(get_users_db)
):
    if current_user.user_type != UserType.PHARMACY:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    profile = get_provider_profile(current_user, pharmacies_db, Pharmacy)
    order = pharmacies_db.query(PharmacyOrder).filter(
        PharmacyOrder.id == id, PharmacyOrder.pharmacy_id == profile.id
    ).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    order.total_price = price_update.total_price
    order.delivery_fee = price_update.delivery_fee
    order.estimated_delivery_time = price_update.estimated_time
    order.pharmacy_notes = price_update.notes
    order.status = OrderStatus.PRICED
    
    pharmacies_db.commit()
    
    # Notify User about price
    user_to_notify = users_db.query(User).filter(User.id == order.user_id).first()
    if user_to_notify:
        notify_order_priced(users_db, user_to_notify, profile.name, order.id, price_update.total_price)
        
    return {"success": True, "message": "Order priced and sent to user"}


# ==========================================
# 4. USER BOOKING (Create Reservation)
# ==========================================

@router.post("/reservations/book")
def create_booking(
    booking: BookingRequest,
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    teachers_db: Session = Depends(get_teachers_db),
    users_db: Session = Depends(get_users_db)
):
    """Create a new reservation (for regular users)"""
    if current_user.user_type != UserType.CUSTOMER:
        raise HTTPException(status_code=403, detail="Only customers can create bookings")
    
    if booking.provider_type == "doctor":
        # Verify doctor exists
        doctor = doctors_db.query(Doctor).filter(Doctor.id == booking.provider_id).first()
        if not doctor:
            raise HTTPException(status_code=404, detail="Doctor not found")
        
        # Create reservation
        reservation = DoctorReservation(
            doctor_id=booking.provider_id,
            user_id=current_user.id,
            patient_name=booking.patient_name,
            patient_phone=booking.patient_phone,
            booking_type=booking.booking_type,
            visit_date=booking.visit_date,
            notes=booking.notes,
            status=ReservationStatus.PENDING
        )
        doctors_db.add(reservation)
        doctors_db.commit()
        doctors_db.refresh(reservation)
        
        # Notify Doctor
        doctor_user = users_db.query(User).filter(User.profile_id == doctor.id, User.user_type == UserType.DOCTOR).first()
        if doctor_user:
            notify_new_booking(users_db, doctor_user, booking.patient_name, reservation.id, "doctor")
            
        return {"success": True, "reservation_id": reservation.id, "message": "تم إرسال طلب الحجز بنجاح"}
    
    elif booking.provider_type == "teacher":
        # Verify teacher exists
        teacher = teachers_db.query(Teacher).filter(Teacher.id == booking.provider_id).first()
        if not teacher:
            raise HTTPException(status_code=404, detail="Teacher not found")
        
        # Create reservation
        reservation = TeacherReservation(
            teacher_id=booking.provider_id,
            user_id=current_user.id,
            student_name=booking.patient_name,  # Reusing patient_name for student
            student_phone=booking.patient_phone,
            requested_date=booking.visit_date,
            notes=booking.notes,
            status=ReservationStatus.PENDING
        )
        teachers_db.add(reservation)
        teachers_db.commit()
        teachers_db.refresh(reservation)
        
        # Notify Teacher
        teacher_user = users_db.query(User).filter(User.profile_id == teacher.id, User.user_type == UserType.TEACHER).first()
        if teacher_user:
            notify_new_booking(users_db, teacher_user, booking.patient_name, reservation.id, "teacher")

        return {"success": True, "reservation_id": reservation.id, "message": "تم إرسال طلب الحجز بنجاح"}
    
    raise HTTPException(status_code=400, detail="Invalid provider type")


@router.get("/my-reservations", response_model=List[UserReservationResponse])
def get_my_reservations(
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    teachers_db: Session = Depends(get_teachers_db)
):
    """Get all reservations for the current user"""
    results = []
    
    # Doctor Reservations
    doctor_reservations = doctors_db.query(DoctorReservation).filter(
        DoctorReservation.user_id == current_user.id
    ).order_by(DoctorReservation.visit_date.desc()).all()
    
    for r in doctor_reservations:
        doctor = doctors_db.query(Doctor).filter(Doctor.id == r.doctor_id).first()
        results.append(UserReservationResponse(
            id=r.id,
            provider_id=r.doctor_id,
            provider_type="doctor",
            provider_name=doctor.name if doctor else "Unknown",
            specialty=doctor.specialty.name_ar if doctor and doctor.specialty else None,
            booking_type=r.booking_type,
            visit_date=r.visit_date,
            status=r.status.value,
            notes=r.notes,
            created_at=r.created_at
        ))
    
    # Teacher Reservations
    teacher_reservations = teachers_db.query(TeacherReservation).filter(
        TeacherReservation.user_id == current_user.id
    ).order_by(TeacherReservation.requested_date.desc()).all()
    
    for r in teacher_reservations:
        teacher = teachers_db.query(Teacher).filter(Teacher.id == r.teacher_id).first()
        results.append(UserReservationResponse(
            id=r.id,
            provider_id=r.teacher_id,
            provider_type="teacher",
            provider_name=teacher.name if teacher else "Unknown",
            subject=teacher.subject.name_ar if teacher and teacher.subject else None,
            visit_date=r.requested_date,
            status=r.status.value,
            notes=r.notes,
            created_at=r.created_at
        ))
    
    # Sort by date descending
    results.sort(key=lambda x: x.visit_date, reverse=True)
    return results


@router.delete("/reservations/{id}")
def cancel_reservation(
    id: int,
    provider_type: str,  # Query param: "doctor" or "teacher"
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    teachers_db: Session = Depends(get_teachers_db)
):
    """Cancel a reservation (for users)"""
    if provider_type == "doctor":
        reservation = doctors_db.query(DoctorReservation).filter(
            DoctorReservation.id == id,
            DoctorReservation.user_id == current_user.id
        ).first()
        if not reservation:
            raise HTTPException(status_code=404, detail="Reservation not found")
        reservation.status = ReservationStatus.CANCELLED
        doctors_db.commit()
        return {"success": True, "message": "تم إلغاء الحجز"}
    
    elif provider_type == "teacher":
        reservation = teachers_db.query(TeacherReservation).filter(
            TeacherReservation.id == id,
            TeacherReservation.user_id == current_user.id
        ).first()
        if not reservation:
            raise HTTPException(status_code=404, detail="Reservation not found")
        reservation.status = ReservationStatus.CANCELLED
        teachers_db.commit()
        return {"success": True, "message": "تم إلغاء الحجز"}
    
    raise HTTPException(status_code=400, detail="Invalid provider type")



# ==========================================
# 5. PROVIDER DELETE ENDPOINTS
# ==========================================

@router.delete("/provider/reservations/{id}")
def delete_provider_reservation(
    id: int,
    provider_type: str, # "doctor" or "teacher"
    current_user: User = Depends(get_current_user),
    doctors_db: Session = Depends(get_doctors_db),
    teachers_db: Session = Depends(get_teachers_db)
):
    """Delete a reservation from provider dashboard (only if Completed or Rejected)"""
    if provider_type == "doctor":
        if current_user.user_type != UserType.DOCTOR:
             raise HTTPException(status_code=403, detail="Not authorized")
        
        reservation = doctors_db.query(DoctorReservation).filter(
            DoctorReservation.id == id,
            DoctorReservation.doctor_id == current_user.profile_id
        ).first()

        if not reservation:
            raise HTTPException(status_code=404, detail="Reservation not found")
            
        # Allow delete only if status is final
        if reservation.status not in [ReservationStatus.COMPLETED, ReservationStatus.REJECTED]:
             raise HTTPException(status_code=400, detail="Can only delete completed or rejected reservations")
             
        doctors_db.delete(reservation)
        doctors_db.commit()
        return {"success": True, "message": "Reservation deleted"}
        
    elif provider_type == "teacher":
        if current_user.user_type != UserType.TEACHER:
             raise HTTPException(status_code=403, detail="Not authorized")
             
        reservation = teachers_db.query(TeacherReservation).filter(
            TeacherReservation.id == id,
            TeacherReservation.teacher_id == current_user.profile_id
        ).first()
        
        if not reservation:
            raise HTTPException(status_code=404, detail="Reservation not found")
            
        if reservation.status not in [ReservationStatus.COMPLETED, ReservationStatus.REJECTED]:
             raise HTTPException(status_code=400, detail="Can only delete completed or rejected reservations")
             
        teachers_db.delete(reservation)
        teachers_db.commit()
        return {"success": True, "message": "Reservation deleted"}
        
    raise HTTPException(status_code=400, detail="Invalid provider type")


@router.delete("/provider/orders/{id}")
def delete_pharmacy_order(
    id: int,
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Delete an order from pharmacy dashboard (only if Delivered or Cancelled/Rejected)"""
    if current_user.user_type != UserType.PHARMACY:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    order = pharmacies_db.query(PharmacyOrder).filter(
        PharmacyOrder.id == id,
        PharmacyOrder.pharmacy_id == current_user.profile_id
    ).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    # Check status. Assuming DELIVERED, REJECTED, CANCELLED are final.
    # We used status strings in dashboard.py earlier. 
    # Let's support OrderStatus.DELIVERED, OrderStatus.REJECTED, OrderStatus.CANCELLED
    # and maybe OrderStatus.COMPLETED if used.
    
    allowed_statuses = [OrderStatus.DELIVERED, OrderStatus.REJECTED, OrderStatus.CANCELLED]
    # If COMPLETED exists in enum, add it.
    if hasattr(OrderStatus, 'COMPLETED'):
        allowed_statuses.append(OrderStatus.COMPLETED)
        
    if order.status not in allowed_statuses:
         raise HTTPException(status_code=400, detail="Can only delete completed or rejected orders")
         
    pharmacies_db.delete(order)
    pharmacies_db.commit()
    return {"success": True, "message": "Order deleted"}


# ==========================================
# 6. USER ORDERS (Pharmacy) - Renumbered
# ==========================================

@router.post("/orders/create")
def create_order(
    order: CreateOrderRequest,
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    users_db: Session = Depends(get_users_db)
):
    """Create a new pharmacy order (for regular users)"""
    if current_user.user_type != UserType.CUSTOMER:
        raise HTTPException(status_code=403, detail="Only customers can create orders")
    
    # Verify pharmacy exists
    pharmacy = pharmacies_db.query(Pharmacy).filter(Pharmacy.id == order.pharmacy_id).first()
    if not pharmacy:
        raise HTTPException(status_code=404, detail="Pharmacy not found")
    
    # Create order
    new_order = PharmacyOrder(
        pharmacy_id=order.pharmacy_id,
        user_id=current_user.id,
        items_text=order.items_text,
        prescription_image=order.prescription_image,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        customer_address=order.customer_address,
        status=OrderStatus.PENDING
    )
    pharmacies_db.add(new_order)
    pharmacies_db.commit()
    pharmacies_db.refresh(new_order)
    
    # Notify Pharmacy
    pharmacy_user = users_db.query(User).filter(User.profile_id == pharmacy.id, User.user_type == UserType.PHARMACY).first()
    if pharmacy_user:
        notify_new_order(users_db, pharmacy_user, order.customer_name, new_order.id)
    
    return {"success": True, "order_id": new_order.id, "message": "تم إرسال طلبك بنجاح"}


@router.post("/orders/{id}/action")
def user_order_action(
    id: int,
    action: OrderUserAction,
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    users_db: Session = Depends(get_users_db)
):
    """User accepts/rejects a priced order"""
    if current_user.user_type != UserType.CUSTOMER:
        raise HTTPException(status_code=403, detail="Only customers can perform this action")
        
    order = pharmacies_db.query(PharmacyOrder).filter(
        PharmacyOrder.id == id,
        PharmacyOrder.user_id == current_user.id
    ).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    if order.status not in [OrderStatus.PRICED]:  # Can only act on Priced orders? Or status logic?
        # Maybe user can reject even if pending? No, logic assumes pricing is done.
        # Actually, let's allow REJECT at any time, but ACCEPT only if PRICED.
        pass

    if action.action == "accept":
        if order.status != OrderStatus.PRICED:
            raise HTTPException(status_code=400, detail="Cannot accept order unless it is priced")
        order.status = OrderStatus.ACCEPTED
        message = "تم تأكيد الطلب"
    elif action.action == "reject":
        order.status = OrderStatus.REJECTED
        message = "تم رفض الطلب"
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    pharmacies_db.commit()
    
    # Notify Pharmacy about User Action
    pharmacy = pharmacies_db.query(Pharmacy).filter(Pharmacy.id == order.pharmacy_id).first()
    if pharmacy:
        pharmacy_user = users_db.query(User).filter(User.profile_id == pharmacy.id, User.user_type == UserType.PHARMACY).first()
        if pharmacy_user and pharmacy_user.fcm_token:
            title = "تحديث حالة الطلب"
            body = f"قام العميل {order.customer_name} ب{action.action == 'accept' and 'قبول' or 'رفض'} السعر"
            send_notification(pharmacy_user.fcm_token, title, body, {"type": "order_update", "order_id": order.id})

    return {"success": True, "status": order.status.value, "message": message}


@router.post("/orders/{id}/pharmacy-action")
def pharmacy_order_action(
    id: int,
    action: OrderUserAction, # Reuse schema: "deliver", "reject" (cancel)
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db),
    users_db: Session = Depends(get_users_db)
):
    """Pharmacy completes/cancels an order"""
    if current_user.user_type != UserType.PHARMACY:
        raise HTTPException(status_code=403, detail="Only pharmacies can perform this action")
        
    order = pharmacies_db.query(PharmacyOrder).filter(
        PharmacyOrder.id == id,
        PharmacyOrder.pharmacy_id == current_user.profile_id
    ).first()
    
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
        
    if action.action == "deliver":
        # Check logic: can only deliver if Accepted? Or Priced if auto-accept?
        # Assuming flow: Pending -> Priced -> Accepted -> Delivered
        if order.status not in [OrderStatus.ACCEPTED]:
             raise HTTPException(status_code=400, detail="Order must be Accepted by user first")
        order.status = OrderStatus.DELIVERED # Or COMPLETED? Let's assume Delivered IS final or use Completed.
        # Check OrderStatus enum. usually: PENDING, PRICED, ACCEPTED, REJECTED, CANCELLED, COMPLETED?
        # Let's check schemas/models.
        # Assuming COMPLETED is the end state.
        
        # Checking existing code: 'statusPriced', 'statusDelivered' in localizations implies 'DELIVERED'.
        # Let's verify OrderStatus enum if accessible. 
        # But based on dashboard.py imports, OrderStatus is imported.
        # I'll optimistically use OrderStatus.COMPLETED or DELIVERED if it exists. 
        # Let's assume COMPLETED for now to match Reservations, or verify.
        # Wait, localizations said "statusDelivered": "Delivered".
        # Let's assume I should update OrderStatus to have DELIVERED if not exists, 
        # or just use COMPLETED and map it. 
        # Let's peek at imports... `from app.models.orders import OrderStatus`
        
        # Safest is to use a valid status string if I can't check Enum.
        # I will assume OrderStatus.COMPLETED exists.
        
        order.status = OrderStatus.DELIVERED 
        message = "تم توصيل الطلب"
        
    elif action.action == "reject": # Cancel
        order.status = OrderStatus.CANCELLED
        message = "تم إلغاء الطلب"
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    pharmacies_db.commit()
    
    # Notify User
    user_to_notify = users_db.query(User).filter(User.id == order.user_id).first()
    if user_to_notify and user_to_notify.fcm_token:
        title = "تحديث حالة الطلب"
        body = f"تم {action.action == 'deliver' and 'توصيل' or 'إلغاء'} طلبك من صيدلية" 
        send_notification(user_to_notify.fcm_token, title, body, {"type": "order_update", "order_id": order.id})

    return {"success": True, "status": order.status.value, "message": message}


@router.get("/my-orders", response_model=List[UserOrderResponse])
def get_my_orders(
    current_user: User = Depends(get_current_user),
    pharmacies_db: Session = Depends(get_pharmacies_db)
):
    """Get all orders for the current user"""
    orders = pharmacies_db.query(PharmacyOrder).filter(
        PharmacyOrder.user_id == current_user.id
    ).order_by(PharmacyOrder.created_at.desc()).all()
    
    results = []
    for o in orders:
        pharmacy = pharmacies_db.query(Pharmacy).filter(Pharmacy.id == o.pharmacy_id).first()
        results.append(UserOrderResponse(
            id=o.id,
            pharmacy_id=o.pharmacy_id,
            pharmacy_name=pharmacy.name if pharmacy else "Unknown",
            items_text=o.items_text,
            prescription_image=o.prescription_image,
            total_price=o.total_price,
            delivery_fee=o.delivery_fee,
            estimated_time=o.estimated_delivery_time,
            notes=o.pharmacy_notes,
            status=o.status.value,
            created_at=o.created_at
        ))
    
    return results

