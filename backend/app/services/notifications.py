"""
Jiwar Backend - Firebase Cloud Messaging Notification Service
Sends push notifications to users and providers
"""
import firebase_admin
from firebase_admin import credentials, messaging
from typing import Optional, Dict, Any
import os
import logging

logger = logging.getLogger(__name__)

# Initialize Firebase Admin SDK
_firebase_initialized = False

def initialize_firebase():
    """Initialize Firebase Admin SDK if not already initialized"""
    global _firebase_initialized
    if _firebase_initialized:
        return True
    
    try:
        # Look for credentials file
        cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'firebase-admin-sdk.json')
        
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            _firebase_initialized = True
            logger.info("Firebase Admin SDK initialized successfully")
            return True
        else:
            logger.warning(f"Firebase credentials not found at {cred_path}")
            return False
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        return False


def send_notification(
    token: str,
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None,
    image_url: Optional[str] = None
) -> bool:
    """
    Send a push notification to a specific device
    
    Args:
        token: FCM device token
        title: Notification title
        body: Notification body
        data: Additional data payload
        image_url: Optional image URL for rich notifications
    
    Returns:
        True if sent successfully, False otherwise
    """
    if not initialize_firebase():
        logger.warning("Firebase not initialized, skipping notification")
        return False
    
    if not token:
        logger.warning("No FCM token provided")
        return False
    
    try:
        # Build notification
        notification = messaging.Notification(
            title=title,
            body=body,
            image=image_url
        )
        
        # Build message
        message = messaging.Message(
            notification=notification,
            token=token,
            data={k: str(v) for k, v in (data or {}).items()},  # Convert all values to strings
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#4CAF50",
                    sound="default",
                    click_action="FLUTTER_NOTIFICATION_CLICK"
                )
            ),
            webpush=messaging.WebpushConfig(
                notification=messaging.WebpushNotification(
                    icon="/icons/icon-192.png",
                    badge="/icons/badge-72.png"
                ),
                fcm_options=messaging.WebpushFCMOptions(
                    link="/"
                )
            )
        )
        
        # Send message
        response = messaging.send(message)
        logger.info(f"Notification sent successfully: {response}")
        return True
        
    except messaging.UnregisteredError:
        logger.warning(f"Token is invalid or unregistered: {token[:20]}...")
        return False
    except Exception as e:
        logger.error(f"Failed to send notification: {e}")
        return False


def send_notification_to_multiple(
    tokens: list,
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None
) -> int:
    """
    Send notification to multiple devices
    
    Returns:
        Number of successful sends
    """
    if not initialize_firebase():
        return 0
    
    if not tokens:
        return 0
    
    success_count = 0
    for token in tokens:
        if send_notification(token, title, body, data):
            success_count += 1
    
    return success_count



# ==========================================
# Notification Templates (With Persistence)
# ==========================================

from app.models.user import User
from app.models.notification import Notification
from sqlalchemy.orm import Session

def save_notification(db: Session, user_id: int, title: str, body: str, data: Optional[Dict[str, Any]] = None):
    """Save notification to database"""
    try:
        new_notif = Notification(
            user_id=user_id,
            title=title,
            body=body,
            data=data,
            is_read=False
        )
        db.add(new_notif)
        db.commit() # Commit to get ID if needed, or rely on caller? 
        # Better to commit here to ensure persistence even if FCM fails
    except Exception as e:
        logger.error(f"Failed to save notification to DB: {e}")

def notify_new_booking(db: Session, provider: User, patient_name: str, reservation_id: int, provider_type: str) -> bool:
    """Notify provider about a new booking"""
    title = "حجز جديد 📋"
    body = f"لديك حجز جديد من {patient_name}"
    data = {
        "type": "new_booking",
        "reservation_id": reservation_id,
        "provider_type": provider_type,
        "action": "view_reservations"
    }
    
    # Persistent Save
    save_notification(db, provider.id, title, body, data)
    
    # Send Push
    if provider.fcm_token:
        return send_notification(provider.fcm_token, title, body, data)
    return False


def notify_booking_confirmed(db: Session, user: User, provider_name: str, reservation_id: int) -> bool:
    """Notify user that their booking was confirmed"""
    title = "تم تأكيد الحجز ✅"
    body = f"تم تأكيد حجزك مع {provider_name}"
    data = {
        "type": "booking_confirmed",
        "reservation_id": reservation_id,
        "action": "view_reservations"
    }
    
    save_notification(db, user.id, title, body, data)
    
    if user.fcm_token:
        return send_notification(user.fcm_token, title, body, data)
    return False


def notify_booking_rejected(db: Session, user: User, provider_name: str, reservation_id: int, reason: Optional[str] = None) -> bool:
    """Notify user that their booking was rejected"""
    title = "تم رفض الحجز ❌"
    body = f"للأسف تم رفض حجزك مع {provider_name}"
    if reason:
        body += f"\nالسبب: {reason}"
    
    data = {
        "type": "booking_rejected",
        "reservation_id": reservation_id,
        "action": "view_reservations"
    }
    
    save_notification(db, user.id, title, body, data)
    
    if user.fcm_token:
        return send_notification(user.fcm_token, title, body, data)
    return False


def notify_new_order(db: Session, pharmacy: User, customer_name: str, order_id: int) -> bool:
    """Notify pharmacy about a new order"""
    title = "طلب جديد 💊"
    body = f"لديك طلب جديد من {customer_name}"
    data = {
        "type": "new_order",
        "order_id": order_id,
        "action": "view_orders"
    }
    
    save_notification(db, pharmacy.id, title, body, data)
    
    if pharmacy.fcm_token:
        return send_notification(pharmacy.fcm_token, title, body, data)
    return False


def notify_order_priced(db: Session, user: User, pharmacy_name: str, order_id: int, total_price: float) -> bool:
    """Notify user that their order has been priced"""
    title = "تم تسعير طلبك 💰"
    body = f"سعر طلبك من {pharmacy_name}: {total_price:.0f} ج.م"
    data = {
        "type": "order_priced",
        "order_id": order_id,
        "action": "view_orders"
    }
    
    save_notification(db, user.id, title, body, data)
    
    if user.fcm_token:
        return send_notification(user.fcm_token, title, body, data)
    return False


def notify_new_rating(db: Session, provider: User, stars: int, provider_type: str) -> bool:
    """Notify provider about a new rating"""
    star_emoji = "⭐" * min(stars, 5)
    title = "تقييم جديد " + star_emoji
    body = f"قام شخص بتقييمك ({stars} نجوم)"
    data = {
        "type": "new_rating",
        "stars": stars,
        "provider_type": provider_type,
        "action": "view_ratings"
    }
    
    save_notification(db, provider.id, title, body, data)
    
    if provider.fcm_token:
        return send_notification(provider.fcm_token, title, body, data)
    return False

