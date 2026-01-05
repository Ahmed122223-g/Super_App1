from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from fastapi.responses import FileResponse
from app.core.security import get_current_user
from app.models import User
import shutil
import os
import uuid
from typing import Dict
import magic

router = APIRouter()

UPLOAD_DIR = "static/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Allowed MIME types for images
ALLOWED_MIME_TYPES = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "image/gif": "gif",
    "image/webp": "webp"
}

def validate_file_content(file_content: bytes) -> str:
    """
    Validate file content using magic bytes (file signature).
    Returns the correct extension if valid, raises HTTPException if invalid.
    """
    mime = magic.Magic(mime=True)
    detected_mime = mime.from_buffer(file_content[:2048])  # Check first 2KB
    
    if detected_mime not in ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid file type: {detected_mime}. Only images are allowed."
        )
    
    return ALLOWED_MIME_TYPES[detected_mime]

def save_upload_file(file: UploadFile) -> str:
    """Helper to save uploaded file and return URL path with magic bytes validation"""
    # First check the declared content type
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Read file content for validation
    file_content = file.file.read()
    file.file.seek(0)  # Reset file pointer
    
    # Validate using magic bytes (actual file content)
    extension = validate_file_content(file_content)
    
    filename = f"{uuid.uuid4()}.{extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    try:
        with open(file_path, "wb") as buffer:
            buffer.write(file_content)
        # Return secure API path instead of static path
        return f"/api/utils/files/{filename}"
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Could not save file: {str(e)}")

@router.get("/files/{filename}")
async def get_secure_file(
    filename: str,
    current_user: User = Depends(get_current_user)
):
    """
    Securely serve files (images/docs) to authenticated users only.
    Prevents IDOR and public access.
    """
    # Prevent directory traversal
    if ".." in filename or "/" in filename:
        raise HTTPException(status_code=400, detail="Invalid filename")
        
    file_path = os.path.join(UPLOAD_DIR, filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(file_path)

@router.post("/upload", response_model=Dict[str, str])
async def upload_file(file: UploadFile = File(...)):
    """
    Upload a file (image) and return the URL.
    """
    url = save_upload_file(file)
    return {"url": url}

# ============================================
# CONTACT SUPPORT
# ============================================
from pydantic import BaseModel, EmailStr
from fastapi import BackgroundTasks
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

class ContactMessage(BaseModel):
    subject: str
    email: EmailStr
    message: str

def send_support_email(contact: ContactMessage):
    """
    Sends a professionally formatted email to the support team.
    Uses settings from config.py
    """
    sender_email = settings.mail_username
    sender_password = settings.mail_password
    recipient_email = "ahmedmohamed1442006m@gmail.com"
    
    if not sender_email or not sender_password:
        logger.warning(f"⚠️ Email credentials missing (User: {sender_email}). Skipping email send.")
        logger.info(f"📩 [MOCK EMAIL] To: {recipient_email} | Subject: {contact.subject} | From: {contact.email} | Body: {contact.message}")
        return

    try:
        # Create professional HTML template
        html_content = f"""
        <html>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <div style="max-width: 600px; margin: 0 auto; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden;">
                <div style="background-color: #4CAF50; padding: 20px; text-align: center; color: white;">
                    <h2 style="margin: 0;">New Support Request</h2>
                </div>
                <div style="padding: 20px; background-color: #f9f9f9;">
                    <p><strong>From:</strong> {contact.email}</p>
                    <p><strong>Subject:</strong> {contact.subject}</p>
                    <hr style="border: 0; border-top: 1px solid #e0e0e0; margin: 20px 0;">
                    <div style="background-color: white; padding: 15px; border-radius: 4px; border-left: 4px solid #4CAF50;">
                        <p style="margin-top: 0;">{contact.message}</p>
                    </div>
                    <hr style="border: 0; border-top: 1px solid #e0e0e0; margin: 20px 0;">
                    <p style="font-size: 12px; color: #888; text-align: center;">Sent from Jiwar App Support System</p>
                </div>
            </div>
        </body>
        </html>
        """

        msg = MIMEMultipart()
        msg['From'] = sender_email
        msg['To'] = recipient_email
        msg['Subject'] = f"Support: {contact.subject}"
        msg.attach(MIMEText(html_content, 'html'))

        # Connect to Gmail SMTP (or configured server)
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(sender_email, sender_password)
        server.send_message(msg)
        server.quit()
        logger.info("✅ Support email sent successfully")
    except Exception as e:
        logger.error(f"❌ Failed to send email: {e}")

@router.post("/contact-support")
async def contact_support(contact: ContactMessage, background_tasks: BackgroundTasks):
    """
    Receive support message and send email in background.
    """
    background_tasks.add_task(send_support_email, contact)
    return {"status": "success", "message": "Message received"}
