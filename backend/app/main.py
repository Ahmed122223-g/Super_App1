"""
Jiwar Backend - Main Application
FastAPI application with 8 database architecture
"""
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
import uvicorn

from app.core.config import settings
from app.core.limiter import limiter
from app.core.database import (
    UsersBase, DoctorsBase, PharmaciesBase, CodesBase, TeachersBase,
    users_engine, doctors_engine, pharmacies_engine, codes_engine, teachers_engine,
    DoctorsSessionLocal, TeachersSessionLocal
)
from app.routers import (
    auth_router,
    doctors_router,
    pharmacies_router,
    specialties_router,
    ratings_router,
    search_router,
    teachers_router,
    dashboard_router,
    utils_router,
    favorites_router,
    addresses_router,
    notifications_router
)
from fastapi.staticfiles import StaticFiles

# Create FastAPI application
app = FastAPI(
    title=settings.app_name,
    description="Jiwar Super App API - 8 Database Architecture",
    version="2.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Configure Rate Limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Static Files
# SECURITY WARNING: Do not serve static files publicly. Use /api/utils/files/{filename} instead.
# app.mount("/static", StaticFiles(directory="static"), name="static")

# ============================================
# EXCEPTION HANDLERS
# ============================================

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors with error codes for frontend translation"""
    errors = []
    for error in exc.errors():
        field = ".".join(str(loc) for loc in error["loc"][1:])
        error_type = error["type"]
        msg = error.get("msg", "")
        
        if "value_error" in error_type or msg.startswith("Value error"):
            error_code = msg.replace("Value error, ", "")
        elif "missing" in error_type:
            error_code = f"{field.upper()}_REQUIRED"
        elif "string_too_short" in error_type:
            error_code = f"{field.upper()}_TOO_SHORT"
        elif "string_too_long" in error_type:
            error_code = f"{field.upper()}_TOO_LONG"
        elif "email" in str(error):
            error_code = "INVALID_EMAIL_FORMAT"
        else:
            error_code = f"INVALID_{field.upper()}"
        
        errors.append({
            "field": field,
            "error_code": error_code,
            "message": msg
        })
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error_code": "VALIDATION_ERROR",
            "message": "Validation failed",
            "details": errors
        }
    )


# ============================================
# ROUTES
# ============================================

app.include_router(auth_router, prefix="/api/auth", tags=["Authentication"])
app.include_router(doctors_router, prefix="/api/doctors", tags=["Doctors"])
app.include_router(pharmacies_router, prefix="/api/pharmacies", tags=["Pharmacies"])
app.include_router(teachers_router, prefix="/api/teachers", tags=["Teachers"])
app.include_router(specialties_router, prefix="/api/specialties", tags=["Specialties"])
app.include_router(ratings_router, prefix="/api/ratings", tags=["Ratings"])
app.include_router(search_router, prefix="/api/search", tags=["Search"])
app.include_router(dashboard_router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(utils_router, prefix="/api/utils", tags=["Utils"])
app.include_router(favorites_router, prefix="/api/favorites", tags=["Favorites"])
app.include_router(addresses_router, prefix="/api/addresses", tags=["Addresses"])
app.include_router(notifications_router, prefix="/api/notifications", tags=["Notifications"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "app": settings.app_name,
        "status": "running",
        "version": "2.0.0",
        "architecture": "8-database",
        "databases": [
            "users", "doctors", "pharmacies", "codes",
            "restaurants", "companies", "engineers", "mechanics"
        ],
        "docs": "/api/docs"
    }


@app.get("/api/health")
async def health_check():
    """Health check"""
    return {"status": "healthy", "databases": 8}


# ============================================
# DATABASE INITIALIZATION
# ============================================

@app.on_event("startup")
async def startup_event():
    """Initialize databases on startup"""
    from app import models
    
    print("🔧 Initializing 8 databases...")
    
    databases = [
        ("Users", UsersBase, users_engine),
        ("Doctors", DoctorsBase, doctors_engine),
        ("Pharmacies", PharmaciesBase, pharmacies_engine),
        ("Codes", CodesBase, codes_engine),
        ("Teachers", TeachersBase, teachers_engine),
    ]
    
    for name, base, engine in databases:
        try:
            base.metadata.create_all(bind=engine)
            print(f"   ✅ {name} database ready")
        except Exception as e:
            print(f"   ⚠️ {name} database: {e}")
    
    # Seed specialties
    from app.models.doctor import SPECIALTIES_DATA, Specialty
    
    try:
        db = DoctorsSessionLocal()
        if db.query(Specialty).count() == 0:
            for spec_data in SPECIALTIES_DATA:
                specialty = Specialty(**spec_data)
                db.add(specialty)
            db.commit()
            print("   ✅ Seeded specialties data")
        db.close()
    except Exception as e:
        print(f"   ⚠️ Seeding specialties: {e}")
        
    # Seed subjects
    from app.models.teacher import SUBJECTS_DATA, Subject
    
    try:
        db = TeachersSessionLocal()
        # Create table if not exists (redundant if loop above worked)
        TeachersBase.metadata.create_all(bind=teachers_engine)
        
        if db.query(Subject).count() == 0:
            for sub_data in SUBJECTS_DATA:
                subject = Subject(**sub_data)
                db.add(subject)
            db.commit()
            print("   ✅ Seeded subjects data")
        db.close()
    except Exception as e:
        print(f"   ⚠️ Seeding subjects: {e}")
    
    print(f"\n🚀 {settings.app_name} API started!")
    print("   📊 8 Databases connected")
    print("   📡 API: http://localhost:8000/api/docs\n")


if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug
    )
