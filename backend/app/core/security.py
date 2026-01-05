"""
Jiwar Backend - Security Utilities
Password hashing and JWT token management
"""
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import bcrypt
from sqlalchemy.orm import Session
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from app.core.database import get_users_db
from app.models.user import User

from app.core.config import settings


import asyncio
from concurrent.futures import ThreadPoolExecutor

# Create a process pool or thread pool for CPU-bound tasks
# We use ThreadPoolExecutor here as it's lighter and works well for IO/CPU mix
executor = ThreadPoolExecutor()

async def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain password against its hash asynchronously.
    Offloads CPU-intensive bcrypt work to a thread pool to avoid blocking the event loop.
    """
    loop = asyncio.get_running_loop()
    
    def _verify():
        # 1. Try new format: Bcrypt(SHA256(password))
        pre_hashed = hashlib.sha256(plain_password.encode('utf-8')).hexdigest()
        if bcrypt.checkpw(pre_hashed.encode('utf-8'), hashed_password.encode('utf-8')):
            return True
            
        # 2. Fallback: Try legacy format: Bcrypt(password)
        try:
            return bcrypt.checkpw(
                plain_password.encode('utf-8'),
                hashed_password.encode('utf-8')
            )
        except ValueError:
            return False

    return await loop.run_in_executor(None, _verify)


async def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt with SHA256 pre-hashing asynchronously.
    """
    loop = asyncio.get_running_loop()
    
    def _hash():
        # 1. Pre-hash with SHA256
        pre_hashed = hashlib.sha256(password.encode('utf-8')).hexdigest()
        
        # 2. Hash with Bcrypt
        salt = bcrypt.gensalt()
        return bcrypt.hashpw(pre_hashed.encode('utf-8'), salt).decode('utf-8')

    return await loop.run_in_executor(None, _hash)


def create_access_token(
    data: dict,
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Create a JWT access token
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.access_token_expire_minutes
        )
    
    to_encode.update({"exp": expire, "type": "access"})
    
    return jwt.encode(
        to_encode,
        settings.secret_key,
        algorithm=settings.algorithm
    )


def create_refresh_token(data: dict) -> str:
    """
    Create a JWT refresh token with longer expiration
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=settings.refresh_token_expire_days)
    to_encode.update({"exp": expire, "type": "refresh"})
    
    return jwt.encode(
        to_encode,
        settings.secret_key,
        algorithm=settings.algorithm
    )


def decode_token(token: str) -> Optional[dict]:
    """
    Decode and validate a JWT token
    """
    try:
        payload = jwt.decode(
            token,
            settings.secret_key,
            algorithms=[settings.algorithm]
        )
        return payload
    except JWTError:
        return None


def verify_registration_code(code: str, code_type: str, codes_db: Session) -> bool:
    """
    Verify admin registration code from database
    
    Args:
        code: The registration code to verify
        code_type: Either 'doctor', 'pharmacy', etc.
        codes_db: Database session for codes database
    
    Returns:
        True if code is valid and unused, False otherwise
    """
    from app.models.codes import CODE_MODELS
    
    CodeModel = CODE_MODELS.get(code_type)
    if not CodeModel:
        return False
    
    # Find the code in database
    db_code = codes_db.query(CodeModel).filter(
        CodeModel.code == code,
        CodeModel.is_used == False
    ).first()
    
    return db_code is not None


def mark_code_as_used(code: str, code_type: str, email: str, codes_db: Session) -> bool:
    """
    Mark a registration code as used
    
    Args:
        code: The registration code
        code_type: Either 'doctor', 'pharmacy', etc.
        email: Email of the user who used the code
        codes_db: Database session for codes database
    
    Returns:
        True if successful, False otherwise
    """
    from app.models.codes import CODE_MODELS
    
    CodeModel = CODE_MODELS.get(code_type)
    if not CodeModel:
        return False
    
    # Find and update the code
    db_code = codes_db.query(CodeModel).filter(
        CodeModel.code == code,
        CodeModel.is_used == False
    ).first()
    
    if db_code:
        db_code.is_used = True
        db_code.used_by_email = email
        db_code.used_at = datetime.utcnow()
        codes_db.commit()
        return True
    
    return False


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def get_current_user(
    token: str = Depends(oauth2_scheme),
    users_db: Session = Depends(get_users_db)
) -> User:
    """
    Validate access token and return current user
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = decode_token(token)
    if payload is None:
        raise credentials_exception
        
    # Get user_id from sub claim and ensure it's an integer
    sub = payload.get("sub")
    if sub is None:
        raise credentials_exception
    
    try:
        user_id = int(sub)
    except (ValueError, TypeError):
        raise credentials_exception
        
    # Check if this is an access token
    if payload.get("type") != "access":
        raise credentials_exception
        
    user = users_db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
        
    # Check token version for single session enforcement
    token_version = payload.get("v")
    # If token has version but user has different version -> INVALID
    # If token has no version (legacy) -> ALLOW (or enforce if strict)
    # We will enforce strictly for new tokens. Old tokens without 'v' might be valid or invalid depending on policy.
    # Let's enforce: if token has 'v', it MUST match.
    if token_version is not None and token_version != user.token_version:
         raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session expired (Logged in from another device)",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
        
    return user
