"""
Jiwar Backend - Authentication Dependencies
JWT token verification using Users database
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from typing import Optional

from app.core.database import get_users_db
from app.core.security import decode_token
from app.models import User, UserType

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    users_db: Session = Depends(get_users_db)
) -> User:
    """Get the current authenticated user from JWT token"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail={"error_code": "INVALID_TOKEN", "message": "Could not validate credentials"},
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    token = credentials.credentials
    payload = decode_token(token)
    
    if payload is None:
        raise credentials_exception
    
    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"error_code": "INVALID_TOKEN_TYPE", "message": "Invalid token type"},
        )
    
    # Get user_id from sub claim and ensure it's an integer
    sub = payload.get("sub")
    if sub is None:
        raise credentials_exception
    
    try:
        user_id = int(sub)
    except (ValueError, TypeError):
        raise credentials_exception
    
    user = users_db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"error_code": "USER_INACTIVE", "message": "User account is inactive"},
        )
    
    return user


async def get_current_user_optional(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(
        HTTPBearer(auto_error=False)
    ),
    users_db: Session = Depends(get_users_db)
) -> Optional[User]:
    """Optional authentication - returns None if no token"""
    if credentials is None:
        return None
    
    try:
        return await get_current_user(credentials, users_db)
    except HTTPException:
        return None


def require_user_type(*user_types: UserType):
    """Dependency factory to require specific user types"""
    async def dependency(user: User = Depends(get_current_user)) -> User:
        if user.user_type not in user_types:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "error_code": "INSUFFICIENT_PERMISSIONS",
                    "message": "You don't have permission to access this resource"
                },
            )
        return user
    return dependency


get_doctor_user = require_user_type(UserType.DOCTOR)
get_pharmacy_user = require_user_type(UserType.PHARMACY)
get_admin_user = require_user_type(UserType.ADMIN)
